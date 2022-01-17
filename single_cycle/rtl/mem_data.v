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

`ifndef MEM_DATA_V
`define MEM_DATA_V

// Data memory

module mem_data #(
    parameter p_DATA_MEM_SIZE = 1024,
    parameter p_WORD_LEN = 16,
    parameter p_ADDR_LEN = 16
) (
    output[p_WORD_LEN-1:0]       dataOut,   // Data for reading
    
    input[p_ADDR_LEN-1:0]        address,   // Address of data
    input[p_WORD_LEN-1:0]        dataIn,    // Data for writing

    input clk,                              // Clock signal
    input writeEn
);

    // We cannot simulate 2**ADDR_LEN, so we choose a smaller data memory size
  	wire[$clog2(p_DATA_MEM_SIZE)-1:0] address_trunc = address[$clog2(p_DATA_MEM_SIZE)-1:0];

  	wire enable = ~(|address[p_ADDR_LEN-1:$clog2(p_DATA_MEM_SIZE)]);
  
    // Memory array
	reg[p_WORD_LEN-1:0] memory[p_DATA_MEM_SIZE-1:0];

    integer i;

    // Initial memory content is 0
    initial begin
        for (i = 0; i < p_DATA_MEM_SIZE; i = i + 1) begin
                memory[i] <= 0;
        end
    end

    always @(negedge clk) begin
        // Write to memory
        if(writeEn && enable)
            memory[address_trunc]   <= dataIn;
    end

    // Asynchronous read
  	assign dataOut = enable ? memory[address_trunc] : 0;
endmodule

`endif
