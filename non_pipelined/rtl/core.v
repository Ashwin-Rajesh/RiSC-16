/*
MIT License

Copyright (c) 2022 Ashwin Rajesh

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

`ifndef CORE_V
`define CORE_V

`include "mem_data.v"
`include "mem_reg.v"

// Everything except the instruction memory
module core #(
	parameter p_DATA_MEM_SIZE=1024              // Length of data memory
) (
    input               clk,                    // Main clock signal
    input               rst,                    // Global reset
    input[15:0]         instruction,            // Instruction input from instruction memory
    output reg[15:0]    pc                      // Program counter output to instruction memory
);
    initial begin
        pc = 0;
    end

    wire[15:0]  reg1_out;
    wire[15:0]  reg2_out;
    reg[15:0]   tgt_in     = 0;

    reg[2:0]    reg1 = 0;
    reg[2:0]    reg2 = 0;
    reg[2:0]    tgt = 0;

    reg tgt_write = 0;

    // Register module
    mem_reg #(
        .p_WORD_LEN(16),
        .p_REG_ADDR_LEN(3),
        .p_REG_FILE_SIZE(8)
    ) regfile (
        .out1(reg1_out),            // Read output 1
        .out2(reg2_out),            // Read output 2

        .src1(reg1),                // Read address 1
        .src2(reg2),                // Read address 2
        .tgt(tgt),                 // Write register address

        .in(tgt_in),               // Input to write
        .clk(clk),                                // Clock signal
        .writeEn(tgt_write),                            // Write enable
        .rst(rst)                                 // Reset all stored values to 0
    );

    wire[15:0]  mem_out;
    reg[15:0]   mem_addr;
    reg[15:0]   mem_in;
    reg mem_wen;

    mem_data #(
      	.p_DATA_MEM_SIZE(p_DATA_MEM_SIZE),
        .p_WORD_LEN(16),
        .p_ADDR_LEN(16)
    ) data_mem (
        .dataOut(mem_out),   // Data for reading
        
        .address(mem_addr),   // Address of data
        .dataIn(mem_in),    // Data for writing

        .clk(clk),                              // Clock signal
        .writeEn(mem_wen),                          // Active high signal for enabling write    
        .rst(rst)                               // Reset whole memory to 0
    );

    wire[2:0] opcode = instruction[15:13];
    
    localparam ADD = 0,
        ADDI = 1,
        NAND = 2,
        LUI  = 3,
        SW   = 4,
        LW   = 5,
        BEQ  = 6,
        JALR = 7;

    wire[2:0] rega = instruction[12:10];
    wire[2:0] regb = instruction[9:7];
    wire[2:0] regc = instruction[2:0];

    wire[9:0] long_imm = instruction[9:0];

    wire[6:0] sign_imm = instruction[6:0];

    wire[15:0] sign_imm_ext = {{25{sign_imm[6]}}, sign_imm};

    // Get register mapping (from instruction to register file)
    always @(*) begin
        case(opcode)
            ADD: begin
                tgt     = rega;
                reg1    = regb;
                reg2    = regc;
            end
            ADDI: begin
                tgt     = rega;
                reg1    = regb;
                reg2    = 3'b0;
            end
            NAND: begin
                tgt     = rega;
                reg1    = regb;
                reg2    = regc;
            end
            LUI: begin
                tgt     = rega;
                reg1    = 3'b0;
                reg2    = 3'b0;                
            end
            SW: begin
                tgt     = 3'b0;
                reg1    = rega;
                reg2    = regb;
            end
            LW: begin
                tgt     = rega;
                reg1    = regb;
                reg2    = 3'b0;
            end
            BEQ: begin
                tgt     = 3'b0;
                reg1    = rega;
                reg2    = regb;
            end
            JALR: begin
                tgt     = rega;
                reg1    = regb;
                reg2    = 3'b0;                
            end
        endcase
    end

    // Set register and memory control signals
    always @(*) begin
        case(opcode)
            ADD: begin
                tgt_in      <= reg1_out + reg2_out;
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
            ADDI: begin
                tgt_in      <= reg1_out + sign_imm_ext;
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
            NAND: begin
              	tgt_in      <= ~(reg1_out & reg2_out);
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
            LUI: begin
                tgt_in      <= {long_imm, 6'b0};
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
            SW: begin
                tgt_in      <= 15'b0;
                tgt_write   <= 1'b0;

                mem_in      <= reg1_out;
                mem_addr    <= reg2_out + sign_imm_ext;
                mem_wen     <= 1'b1;
            end
            LW: begin
                mem_addr    <= reg1_out + sign_imm_ext;
                tgt_in      <= mem_out;
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_wen     <= 1'b0;
            end
            BEQ: begin
                tgt_in      <= 15'b0;
                tgt_write   <= 1'b0;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
            JALR: begin
                tgt_in      <= pc + 1;
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
        endcase
    end

    always @(posedge clk) begin
        if(rst) begin
          pc = 0;
        end
        else
          case(opcode)
              ADD, ADDI, NAND, LUI, SW, LW : begin
                  pc      <= pc + 1;
              end
              BEQ: begin
                  if(reg1_out == reg2_out)
                      pc      <= pc + sign_imm_ext;
                  else
                      pc      <= pc + 1;
              end
              JALR: begin
                  pc  <= reg1_out;
              end
          endcase
    end

endmodule

`endif