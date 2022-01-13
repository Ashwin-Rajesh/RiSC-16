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

`ifndef MEM_DATA_TEST
`define MEM_DATA_TEST

`include "mem_data.v"
`include "mem_data_ref.svh"

// Test data memory
module mem_data_test;
  // Configuration parameters
  localparam p_MEM_SIZE = 1024;
  localparam p_MAX_TESTS = 100000;

  // Signals to/from the DUT
  wire[15:0]       dataOut;   // Data for reading
  bit[15:0]        address;   // Address of data
  bit[15:0]        dataIn;    // Data for writing
  bit clk;                              // Clock signal
  bit writeEn;                          // Active high signal for enabling write    
  bit rst;                              // Reset whole memory to 0

  // The DUT
  mem_data #(
      .p_WORD_LEN(16),
      .p_ADDR_LEN(16),
      .p_DATA_MEM_SIZE(p_MEM_SIZE)
  ) datamem_dut (.*);

  // The reference model
  datamem #(p_MEM_SIZE) reference;

  // Covergroup
  covergroup cg @(posedge clk);
    address_ranges : coverpoint address[$clog2(p_MEM_SIZE)-1:0] {
      bins addr_range[100] = {[0:p_MEM_SIZE-1]};
    }
    select_ranges  : coverpoint address[15:$clog2(p_MEM_SIZE)] {
      bins addr_range[10] = {[0:2**(16-$clog2(p_MEM_SIZE))]};
    }
  endgroup
  cg cg_inst;

  // Clocking block to drive TB outputs to DUT
  clocking cb_mem @(posedge clk);
    output negedge address;
    output negedge dataIn;

    output negedge writeEn;  
  endclocking

  // Generate clock signal                          
  always #5 clk = ~clk;

  initial begin
    $display("Starting data memory test");
      
      // Initialize objects
      reference 	= new();
      cg_inst		= new();

      // Main loop
      repeat(p_MAX_TESTS) begin
          // Random addresses and data
          cb_mem.address		<= $random;
          cb_mem.dataIn		  <= $random;
          cb_mem.writeEn		<= $random;

          // Reset probability 1 in 100          
          if($urandom(100) == 0)
            rst = 1;	
          else
            rst = 0;
          
          // Reset reference model if needed
          if(rst == 1)
            reference.reset();
        
          @(cb_mem);

          // Check if reads match
          assert (reference.read_mem(address) == dataOut) else begin
            $display("Read mismatch. Address %d : %h vs %h", address, dataOut, reference.read_mem(address));
          end;

          // Make sure we read from a written address at least once
          if(~writeEn) begin
            cover_reread : cover ((reference.write_hist.find() with (item == address[$clog2(p_MEM_SIZE)-1:0])) != {});
          end
          
          // Write to reference model if needed
          if(writeEn) begin
            reference.write_mem(address, dataIn);
          end
      end

      // Display coverage information
      $display("Coverage : %.2f", cg_inst.get_coverage());
    
      $display("Data memory test finished");
      $finish();
  end

endmodule

`endif
