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

`ifndef MEM_REG_V
`define MEM_REG_V

module mem_reg #(
    parameter p_WORD_LEN        = 16,
    parameter p_REG_ADDR_LEN    = 3,
    parameter p_REG_FILE_SIZE   = 8
) (
    input i_clk,                                // Clock signal

    input[p_REG_ADDR_LEN-1:0]     i_src1,      // Read address 1
    input[p_REG_ADDR_LEN-1:0]     i_src2,      // Read address 2
  	input[p_REG_ADDR_LEN-1:0]     i_tgt,       // Write register address

    output[p_WORD_LEN-1:0]        o_src1_data, // Read output 1 (asynchronous)
    output[p_WORD_LEN-1:0]        o_src2_data, // Read output 2 (asynchronous)
    input[p_WORD_LEN-1:0]         i_tgt_data,  // Input to write to the target (on posedge)

    input i_wr_en                              // High to write on posedge
);

    // Memory
    reg [p_WORD_LEN-1:0] r_memory[p_REG_FILE_SIZE-1:1];
    
    // For iteration
    integer i;

    // Outputs
  	assign o_src1_data = (i_src1 === 0) ? 0 : r_memory[i_src1];
  	assign o_src2_data = (i_src2 === 0) ? 0 : r_memory[i_src2];

    // Initial values are 0
    initial begin
      for(i = 1; i < p_REG_FILE_SIZE; i = i + 1)
            r_memory[i] <= 0;
    end

    // Write on posedge
  	always @(posedge i_clk) begin : write_block
        if(i_wr_en)
            if(i_tgt != 0)
                r_memory[i_tgt] = i_tgt_data;
    end
            
endmodule

`endif
