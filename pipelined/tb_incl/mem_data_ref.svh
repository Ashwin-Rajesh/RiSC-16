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

`ifndef MEM_DATA_REF_SVH
`define MEM_DATA_REF_SVH

// Reference class for data memory
class datamem #(int size = 1024);
  	bit[15:0] mem_ref[size-1:0];		// Memory array
  	bit[15:0] write_hist[$];			// History of all writes for debugging
  	bit[15:0] write_data_hist[$];

	// Constructor
    function new;
      	for(int i = 0; i < size; i = i + 1)
          	mem_ref[i] = 0;
    endfunction

	// Write to memory
  	function void write_mem(input bit[15:0] addr, bit[15:0] data);
      while(addr < 0)
        addr = size + addr;
      
      if(addr < size) begin
      		mem_ref[addr] = data;
      		write_hist.push_back(addr);
        	write_data_hist.push_back(data);
      end
    endfunction

	// Read from memory
  	function bit[15:0] read_mem(bit[15:0] addr);
      	if(addr < size)
        	return mem_ref[addr];
      	else
          	return 0;
    endfunction

	// Reset memory
  	function void reset();
      for(int i = 0; i < size; i = i + 1)
      	mem_ref[i] = 0;    	
    
      	write_hist.delete();
    endfunction
endclass

`endif
