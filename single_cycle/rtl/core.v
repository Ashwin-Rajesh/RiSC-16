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
    input               i_clk,                  // Main clock signal
    input               i_rst,                  // Global reset

    input[15:0]         i_inst,                 // Instruction input from instruction memory
    output reg[15:0]    o_pc                    // Program counter output to instruction memory
);
    initial begin
        o_pc = 0;
    end

    wire[15:0]  w_reg1_out;
    wire[15:0]  w_reg2_out;
    reg[15:0]   r_tgt_in     = 0;

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
        .i_clk(i_clk),
        
        .i_src1(reg1),
        .i_src2(reg2),
        .i_tgt(tgt),
        
        .o_src1_data(w_reg1_out),
        .o_src2_data(w_reg2_out),
        .i_tgt_data(r_tgt_in),
        
        .i_wr_en(tgt_write)
    );

    wire[15:0] temp_mem_out;

    reg[15:0]   mem_addr;
    reg[15:0]   mem_in;
    wire[15:0]  mem_out = mem_addr < p_DATA_MEM_SIZE ? temp_mem_out : 0;
    reg mem_wen;

    mem_data #(
        .p_WORD_LEN(16),
        .p_ADDR_LEN($clog2(p_DATA_MEM_SIZE))
    ) data_mem (
        .i_clk(i_clk),
        
        .o_rd_data(temp_mem_out),
        .i_addr(mem_addr),
        .i_wr_data(mem_in),
        
      	.i_wr_en(mem_wen && mem_addr < p_DATA_MEM_SIZE)
    );

    wire[2:0] opcode = i_inst[15:13];
    
    localparam ADD = 0,
        ADDI = 1,
        NAND = 2,
        LUI  = 3,
        SW   = 4,
        LW   = 5,
        BEQ  = 6,
        JALR = 7;

    wire[2:0] rega = i_inst[12:10];
    wire[2:0] regb = i_inst[9:7];
    wire[2:0] regc = i_inst[2:0];

    wire[9:0] long_imm = i_inst[9:0];

    wire[6:0] sign_imm = i_inst[6:0];

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
                r_tgt_in    <= w_reg1_out + w_reg2_out;
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
            ADDI: begin
                r_tgt_in    <= w_reg1_out + sign_imm_ext;
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
            NAND: begin
              	r_tgt_in    <= ~(w_reg1_out & w_reg2_out);
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
            LUI: begin
                r_tgt_in    <= {long_imm, 6'b0};
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
            SW: begin
                r_tgt_in    <= 15'b0;
                tgt_write   <= 1'b0;

                mem_in      <= w_reg1_out;
                mem_addr    <= w_reg2_out + sign_imm_ext;
                mem_wen     <= 1'b1;
            end
            LW: begin
                mem_addr    <= w_reg1_out + sign_imm_ext;
                r_tgt_in    <= mem_out;
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_wen     <= 1'b0;
            end
            BEQ: begin
                r_tgt_in    <= 15'b0;
                tgt_write   <= 1'b0;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
            JALR: begin
                r_tgt_in    <= o_pc + 1;
                tgt_write   <= 1'b1;

                mem_in      <= 15'b0;
                mem_addr    <= 15'b0;
                mem_wen     <= 1'b0;
            end
        endcase
    end

    always @(posedge i_clk) begin
        if(i_rst) begin
          o_pc = 0;
        end
        else
          case(opcode)
              ADD, ADDI, NAND, LUI, SW, LW : begin
                  o_pc      <= o_pc + 1;
              end
              BEQ: begin
                  if(w_reg1_out == w_reg2_out)
                      o_pc      <= o_pc + sign_imm_ext;
                  else
                      o_pc      <= o_pc + 1;
              end
              JALR: begin
                  o_pc  <= w_reg1_out;
              end
          endcase
    end

endmodule

`endif