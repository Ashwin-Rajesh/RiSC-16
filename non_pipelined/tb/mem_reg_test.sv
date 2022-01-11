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

`ifndef MEM_REG_TEST
`define MEM_REG_TEST

`include "mem_reg.v"
`include "mem_reg_ref.svh"

module mem_reg_test;
    localparam p_WORD_LEN = 16;

    wire[15:0] out1;
    wire[15:0] out2;

    bit[2:0] src1;
    bit[2:0] src2;
    bit[2:0] tgt;

    bit[15:0] inp;

    bit clk;
    bit writeEn;

    bit rst;

    mem_reg #(
        .p_WORD_LEN(16),
        .p_REG_ADDR_LEN(3),
        .p_REG_FILE_SIZE(8)
    ) regfile_dut (.in(inp), .*);

    covergroup cg @(posedge clk);
        coverpoint src1;
        coverpoint src2;
        coverpoint tgt iff(writeEn);

        coverpoint (tgt == src1) iff(writeEn);
        coverpoint (tgt == src2) iff(writeEn);
    endgroup : cg

    cg cg_inst;

    localparam p_MAX_TESTS = 1000;

    clocking cb_reg @(posedge clk);
        output negedge src1;
        output negedge src2;
        output negedge tgt;
        output negedge inp;
        output negedge writeEn;

        input out1;
        input out2;
    endclocking

    regfile reference;

    initial begin
      	$display("Starting register test");
      	
        $dumpfile("dump.vcd");
      	$dumpvars(0, mem_reg_test);
      
      	reference = new();
        cg_inst = new();
      
      	#1;

        repeat(p_MAX_TESTS) begin
            cb_reg.src1         <= $random;
            cb_reg.src2         <= $random;
            cb_reg.tgt          <= $random;
            cb_reg.inp          <= $random;
            cb_reg.writeEn    	<= $random;

          	if($urandom(100) == 0)
          		rst = 1;	
            else
              	rst = 0;
          
            if(rst == 1)
              reference.reset();
          
          	assert (reference.read_reg(src1) === out1) else begin
              $display("%t Source 1 mismatch. Reg %d : %h vs %h", $time, src1, out1, reference.read_reg(src1));
            end;

          	assert (reference.read_reg(src2) === out2) else begin
              $display("%t Source 1 mismatch. Reg %d : %h vs %h", $time, src2, out2, reference.read_reg(src2));            
            end;
          
            assert (^out1 !== 1'bx);
          	assert (^out2 !== 1'bx);
            
            @(cb_reg);
          
            if(writeEn) begin
              reference.write_reg(tgt, inp);
            end
        end
      	$display("Coverage : %.2f", cg_inst.get_coverage());
      	$finish();
    end

    always #5 clk = ~clk;

endmodule

`endif
