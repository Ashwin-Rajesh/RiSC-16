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
    output[p_WORD_LEN-1:0]    out1,           // Read output 1
    output[p_WORD_LEN-1:0]    out2,           // Read output 2

    input[p_REG_ADDR_LEN-1:0]      src1,      // Read address 1
    input[p_REG_ADDR_LEN-1:0]      src2,      // Read address 2
    input[p_REG_ADDR_LEN-1:0]      tgt,       // Write register address

    input[p_WORD_LEN-1:0]     in,             // Input to write
    input clk,                                // Clock signal
    input writeEn
);

    // Memory
    reg [p_WORD_LEN-1:0] memory[p_REG_FILE_SIZE-1:1];
    
    // For iteration
    integer i;

    // Outputs
  	assign out1 = (src1 === 0) ? 0 : memory[src1];
  	assign out2 = (src2 === 0) ? 0 : memory[src2];

    // Initial values are 0
    initial begin
      for(i = 1; i < p_REG_FILE_SIZE; i = i + 1)
            memory[i] <= 0;
    end

  	always @(posedge clk) begin : write_block
        if(writeEn)
            if(tgt != 0)
                memory[tgt] = in;
    end
            
endmodule

`endif