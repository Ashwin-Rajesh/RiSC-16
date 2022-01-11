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

`ifndef MEM_REG_REF_SVH
`define MEM_REG_REF_SVH

class regfile;
    bit[15:0] mem_ref[7:0];

    function new;
        for(int i = 0; i < 8; i = i + 1)
          mem_ref[i] = 0;
    endfunction

    function void write_reg(bit[2:0] addr, bit[15:0] data);
        if(addr != 0)
            mem_ref[addr] = data;
    endfunction

    function bit[15:0] read_reg(bit[2:0] addr);
        if(addr == 0)
            return 0;
        else
            return mem_ref[addr];
    endfunction

  	function void reset();
        for(int i = 0; i < 8; i = i + 1)
          mem_ref[i] = 0;    	
    endfunction
endclass

`endif
