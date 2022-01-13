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

`ifndef INST_TEST_SV
`define INST_TEST_SV

`include "simulator.svh"
`include "instruction.svh"

// Test that instruction decode and encode works well
module inst_test;
  // Configuration parameters
  localparam max_count = 10000;

  // Instruction objects to test  
  instruction inst;
  instruction inst2;
  
  int i = 0;
  
  initial begin
    int count = 0;
    
    inst2 	= new();    
    inst 	  = new();

    // Main loop

    for(i = 0; i < max_count; i = i + 1) begin
      logic[15:0] inst_bin;    
      
      // Generate random instructions
      if(inst.randomize()) begin
        // Sample for coverage
        inst.cg.sample();

        // Convert to binary and encode another instruction
        inst_bin = inst.to_bin();
        inst2.from_bin(inst_bin);
        
        // Display a total of 100 instructions
        if(i % (max_count / 100) == 0)
          $display("%d %s %s", i, inst.to_string(), inst2.to_string());

        // Check for inconsistencies
        assert(inst.to_string() == inst2.to_string()) else begin
          count = count + 1;
          $display("Inconsistency detected : %s %s", inst.to_string(), inst2.to_string());
        end
      end else begin
        $display("Randomization unsuccessful");
      end
    end
    $display("%d inconsistencies detected!", count);

    // Display coverage information
    $display("coverage : %.2f", inst.cg.get_coverage()); 
    $display("Signed imm coverage : %.2f, Long imm coverage : %.2f", inst.cg.sig_imm.get_coverage(), inst.cg.long_imm.get_coverage());
    $display("RRR : %.2f RRI : %.2f RI : %.2f", inst.cg.RRR_cover.get_coverage(), inst.cg.RRI_cover.get_coverage(), inst.cg.RI_cover.get_coverage());
  end
endmodule

`endif
