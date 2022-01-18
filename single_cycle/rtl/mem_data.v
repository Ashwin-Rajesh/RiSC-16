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
    parameter p_WORD_LEN = 16,                  // Number of bits in a word
    parameter p_ADDR_LEN = 10,                  // Number of addressing lines
    localparam p_MEM_SIZE = 2 ** p_ADDR_LEN     // Number of words
) (
    input i_clk,                                // Clock signal
    input i_wr_en,                              // High to write on positive edge

    input[p_ADDR_LEN-1:0]        i_addr,        // Address of data
    output[p_WORD_LEN-1:0]       o_rd_data,     // Data for reading (asynchronous)
  	input[p_WORD_LEN-1:0]        i_wr_data      // Data for writing (on posedge)
);

    // Truncated address bus
  	wire[$clog2(p_MEM_SIZE)-1:0] w_addr_trunc = i_addr[$clog2(p_MEM_SIZE)-1:0];

    // Memory array
	reg[p_WORD_LEN-1:0] r_memory[p_MEM_SIZE-1:0];

    integer i;

    // Initial memory content is 0
    initial begin
        for (i = 0; i < p_MEM_SIZE; i = i + 1) begin
                r_memory[i] <= 0;
        end
    end

    always @(posedge i_clk) begin
        // Write to memory
        if(i_wr_en)
            r_memory[w_addr_trunc]   <= i_wr_data;
    end

    // Asynchronous read
  	assign o_rd_data = r_memory[w_addr_trunc];

`ifdef FORMAL
    (* anyconst *) reg[p_ADDR_LEN-1:0] f_test_addr;
    reg[p_WORD_LEN-1:0] f_test_data = 0;

    always @(*) begin
        // Memory location test
        assert(r_memory[f_test_addr] == f_test_data);

        // Output data test
        if(i_addr == f_test_addr)
            assert(o_rd_data == f_test_data);        
    end

    always @(posedge i_clk) begin
        // Writing data
        if(i_addr == f_test_addr && i_wr_en)
            f_test_data = i_wr_data;
    end
`endif

endmodule

`endif
