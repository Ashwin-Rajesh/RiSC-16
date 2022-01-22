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

`ifndef ALU_V
`define ALU_V

module alu #(
    p_WORD_LEN = 16
) (
    input                   i_op,       // 0 for add, 1 for nand

    input[p_WORD_LEN-1:0]   i_ina,      // Input a
    input[p_WORD_LEN-1:0]   i_inb,      // Input b
    
    output[p_WORD_LEN-1:0]  o_out,      // Output
    output                  o_eq        // Were both inputs equal?
);

    assign o_eq     = (i_ina == i_inb);
    
    assign o_out    = i_op ? ~(i_ina & i_inb) : i_ina + i_inb;

endmodule

`endif
