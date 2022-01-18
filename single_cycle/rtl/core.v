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

`include "mem_reg.v"

// Everything except the instruction memory
module core (
    // Control signals
    input               i_clk,                  // Main clock signal
    input               i_rst,                  // Global reset

    // Instruction memory interface
    input[15:0]         i_inst,                 // Instruction input from instruction memory
    output reg[15:0]    o_pc,                   // Program counter output to instruction memory

    // Data memory interface
    input[15:0]         i_mem_rd_data,          // Data read from memory
    output reg[15:0]    o_mem_wr_data,          // Data to write to memory
    output reg[15:0]    o_mem_addr,             // Address to write or read
    output reg          o_mem_wr_en             // Write enable for memory
);
    initial begin
        o_pc = 0;
    end

    wire[15:0]  w_reg1_out;
    wire[15:0]  w_reg2_out;
    reg[15:0]   r_tgt_in    = 0;

    reg[2:0]    r_reg1_addr = 0;
    reg[2:0]    r_reg2_addr = 0;
    reg[2:0]    r_tgt_addr  = 0;

    reg         r_tgt_wr_en = 0;

    // Register module
    mem_reg #(
        .p_WORD_LEN(16),
        .p_REG_ADDR_LEN(3),
        .p_REG_FILE_SIZE(8)
    ) regfile (
        .i_clk(i_clk),
        
        .i_src1(r_reg1_addr),
        .i_src2(r_reg2_addr),
        .i_tgt(r_tgt_addr ),
        
        .o_src1_data(w_reg1_out),
        .o_src2_data(w_reg2_out),
        .i_tgt_data(r_tgt_in),
        
        .i_wr_en(r_tgt_wr_en)
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

    wire[2:0] w_rega = i_inst[12:10];
    wire[2:0] w_regb = i_inst[9:7];
    wire[2:0] w_regc = i_inst[2:0];

    wire[9:0] w_long_imm = i_inst[9:0];

    wire[6:0] w_sign_imm = i_inst[6:0];

    wire[15:0] w_sign_imm_ext = {{25{w_sign_imm[6]}}, w_sign_imm};

    // Get register mapping (from instruction to register file)
    always @(*) begin
        case(opcode)
            ADD: begin
                r_tgt_addr     = w_rega;
                r_reg1_addr    = w_regb;
                r_reg2_addr    = w_regc;
            end
            ADDI: begin
                r_tgt_addr     = w_rega;
                r_reg1_addr    = w_regb;
                r_reg2_addr    = 3'b0;
            end
            NAND: begin
                r_tgt_addr     = w_rega;
                r_reg1_addr    = w_regb;
                r_reg2_addr    = w_regc;
            end
            LUI: begin
                r_tgt_addr     = w_rega;
                r_reg1_addr    = 3'b0;
                r_reg2_addr    = 3'b0;                
            end
            SW: begin
                r_tgt_addr     = 3'b0;
                r_reg1_addr    = w_rega;
                r_reg2_addr    = w_regb;
            end
            LW: begin
                r_tgt_addr     = w_rega;
                r_reg1_addr    = w_regb;
                r_reg2_addr    = 3'b0;
            end
            BEQ: begin
                r_tgt_addr     = 3'b0;
                r_reg1_addr    = w_rega;
                r_reg2_addr    = w_regb;
            end
            JALR: begin
                r_tgt_addr     = w_rega;
                r_reg1_addr    = w_regb;
                r_reg2_addr    = 3'b0;                
            end
        endcase
    end

    // Set register and memory control signals
    always @(*) begin
        case(opcode)
            ADD: begin
                r_tgt_in    <= w_reg1_out + w_reg2_out;
                r_tgt_wr_en <= 1'b1;

                o_mem_wr_data    
                            <= 15'b0;
                o_mem_addr  <= 15'b0;
                o_mem_wr_en <= 1'b0;
            end
            ADDI: begin
                r_tgt_in    <= w_reg1_out + w_sign_imm_ext;
                r_tgt_wr_en <= 1'b1;

                o_mem_wr_data
                            <= 15'b0;
                o_mem_addr  <= 15'b0;
                o_mem_wr_en <= 1'b0;
            end
            NAND: begin
              	r_tgt_in    <= ~(w_reg1_out & w_reg2_out);
                r_tgt_wr_en <= 1'b1;

                o_mem_wr_data
                            <= 15'b0;
                o_mem_addr  <= 15'b0;
                o_mem_wr_en <= 1'b0;
            end
            LUI: begin
                r_tgt_in    <= {w_long_imm, 6'b0};
                r_tgt_wr_en <= 1'b1;

                o_mem_wr_data
                            <= 15'b0;
                o_mem_addr  <= 15'b0;
                o_mem_wr_en <= 1'b0;
            end
            SW: begin
                r_tgt_in    <= 15'b0;
                r_tgt_wr_en <= 1'b0;

                o_mem_wr_data
                            <= w_reg1_out;
                o_mem_addr  <= w_reg2_out + w_sign_imm_ext;
                o_mem_wr_en <= 1'b1;
            end
            LW: begin
                o_mem_addr  <= w_reg1_out + w_sign_imm_ext;
                r_tgt_in    <= i_mem_rd_data;
                r_tgt_wr_en <= 1'b1;

                o_mem_wr_data
                            <= 15'b0;
                o_mem_wr_en <= 1'b0;
            end
            BEQ: begin
                r_tgt_in    <= 15'b0;
                r_tgt_wr_en <= 1'b0;

                o_mem_wr_data
                            <= 15'b0;
                o_mem_addr  <= 15'b0;
                o_mem_wr_en <= 1'b0;
            end
            JALR: begin
                r_tgt_in    <= o_pc + 1;
                r_tgt_wr_en <= 1'b1;

                o_mem_wr_data
                            <= 15'b0;
                o_mem_addr  <= 15'b0;
                o_mem_wr_en <= 1'b0;
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
                      o_pc      <= o_pc + w_sign_imm_ext;
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