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

module mem_data_test;
  	localparam p_MEM_SIZE = 1024;
    localparam p_MAX_TESTS = 100000;

  	wire[15:0]       dataOut;   // Data for reading

    bit[15:0]        address;   // Address of data
    bit[15:0]        dataIn;    // Data for writing

    bit clk;                              // Clock signal
    bit writeEn;                          // Active high signal for enabling write    
    bit rst;                              // Reset whole memory to 0
  
    mem_data #(
        .p_WORD_LEN(16),
      	.p_ADDR_LEN(16),
      	.p_DATA_MEM_SIZE(p_MEM_SIZE)
    ) datamem_dut (.*);
  
    covergroup cg @(posedge clk);
      address_ranges : coverpoint address[$clog2(p_MEM_SIZE)-1:0] {
        bins addr_range[100] = {[0:p_MEM_SIZE-1]};
      }
      select_ranges  : coverpoint address[15:$clog2(p_MEM_SIZE)] {
        bins addr_range[100] = {[0:2**(16-$clog2(p_MEM_SIZE))]};
      }
    endgroup
  
    clocking cb_mem @(posedge clk);
      output negedge address;
      output negedge dataIn;

      output negedge writeEn;  
    endclocking

    cg cg_inst;
                            
  	datamem #(p_MEM_SIZE) reference;

    initial begin
      $display("Starting data memory test");
        
      	reference 	= new();
      
      	cg_inst		= new();

        repeat(p_MAX_TESTS) begin
            cb_mem.address		<= $random;
            cb_mem.dataIn		<= $random;
            cb_mem.writeEn		<= $random;
            
          	if($urandom(100) == 0)
          		rst = 1;	
            else
              	rst = 0;
          	
            if(rst == 1)
              reference.reset();
          
          	@(cb_mem);
          
            assert (reference.read_mem(address) == dataOut) else begin
              $display("Read mismatch. Address %d : %h vs %h", address, dataOut, reference.read_mem(address));
            end;
          	
          	if(~writeEn) begin
              cover_reread : cover ((reference.write_hist.find() with (item == address[$clog2(p_MEM_SIZE)-1:0])) != {});
            end
            
            if(writeEn) begin
              reference.write_mem(address, dataIn);
            end
        end

      	$display("Coverage : %.2f", cg_inst.get_coverage());
      
      	$display("Data memory test finished");
      	$finish();
    end

    always #5 clk = ~clk;

endmodule

`endif
