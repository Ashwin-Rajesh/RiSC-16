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

// Test the register file
module mem_reg_test;
  // Configuration parameters
  localparam p_WORD_LEN = 16;
  localparam p_MAX_TESTS = 1000;

  // Signals to/from the DUT
  wire[15:0] out1;
  wire[15:0] out2;

  bit[2:0] src1;
  bit[2:0] src2;
  bit[2:0] tgt;

  bit[15:0] inp;

  bit clk;
  bit writeEn;

  // The DUT
  mem_reg #(
      .p_WORD_LEN(16),
      .p_REG_ADDR_LEN(3),
      .p_REG_FILE_SIZE(8)
  ) regfile_dut (
    .i_clk(clk),
    .i_wr_en(writeEn),
    .i_src1(src1),
    .i_src2(src2),
    .i_tgt(tgt),
    .o_src1_data(out1),
    .o_src2_data(out2),
    .i_tgt_data(inp)
  );

  // The reference model
  regfile reference;

  // Covergroup
  covergroup cg @(posedge clk);
      coverpoint src1;
      coverpoint src2;
      coverpoint tgt iff(writeEn);

      coverpoint (tgt == src1) iff(writeEn);
      coverpoint (tgt == src2) iff(writeEn);
  endgroup : cg
  cg cg_inst;

  // Clocking group to drive TB outputs to DUT
  clocking cb_reg @(posedge clk);
      output negedge src1;
      output negedge src2;
      output negedge tgt;
      output negedge inp;
      output negedge writeEn;

      input out1;
      input out2;
  endclocking

  // Generate clock signal
  always #5 clk = ~clk;

  initial begin
    $display("Starting register test");

    // Setup dumpfile
    $dumpfile("dump.vcd");
    $dumpvars(0, mem_reg_test);

    // Initialize objects    
    reference = new();
    cg_inst = new();
  
    #1;

    // Main loop
    repeat(p_MAX_TESTS) begin
        // Randomize everything!
        cb_reg.src1         <= $random;
        cb_reg.src2         <= $random;
        cb_reg.tgt          <= $random;
        cb_reg.inp          <= $random;
        cb_reg.writeEn    	<= $random;
      
        // Make sure outputs are not indeterminate        
        assert (^out1 !== 1'bx);
        assert (^out2 !== 1'bx);
        
        // Wait for clock
        @(cb_reg);
      
        // Make sure reads match
        assert (reference.read_reg(src1) === out1) else begin
          $display("%t Source 1 mismatch. Reg %d : %h(dut) vs %h", $time, src1, out1, reference.read_reg(src1));
        end;
        assert (reference.read_reg(src2) === out2) else begin
          $display("%t Source 2 mismatch. Reg %d : %h(dut) vs %h", $time, src2, out2, reference.read_reg(src2));            
        end;

        // Write to reference if needed
        if(writeEn) begin
          reference.write_reg(tgt, inp);
        end
    end

    // Show coverage information
    $display("Coverage : %.2f", cg_inst.get_coverage());
    
    $display("Finished register test");
    $finish();
  end

endmodule

`endif
