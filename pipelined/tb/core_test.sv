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

`ifndef CORE_TEST_SV
`define CORE_TEST_SV

`include "simulator.svh"
`include "instruction.svh"

`include "core.v"
`include "mem_data.v"

// Test the processor core
module core_test;
	// Parameters for configuration
	localparam p_INST_COUNT = 100000;
	localparam p_DATA_ADDR_LEN = 10;
	localparam p_DATA_COUNT = 2 ** p_DATA_ADDR_LEN;
	localparam p_LOG_TRACE = 1;
	
	// Instruction to execute and instruction window
	instruction inst;
  	instruction inst2;
  	instruction inst_window[$];
	int pc_pointer = 0;

	// Signals to connect to the DUT
	bit clk;
	bit rst;
	bit[15:0] inst_reg;	
	wire[15:0] pc;

  	event update_evt;
  
	// Generate clock signal
	always #5 clk = ~clk;

  	wire[15:0] w_rd_data;
  	wire[15:0] w_wr_data;
  	wire[15:0] w_addr;
	wire w_wr_en;

	// The DUT	
	core core_dut (
		.i_clk(clk),
		.i_rst(rst),

		.i_inst(inst_reg),
		.o_pc_next(pc),

    	.i_mem_rd_data((w_addr < p_DATA_COUNT) ? w_rd_data : 0),
		.o_mem_wr_data(w_wr_data),
		.o_mem_addr(w_addr),
		.o_mem_wr_en(w_wr_en)
	);
	
	mem_data #(
    	.p_WORD_LEN(16),
		.p_ADDR_LEN(p_DATA_ADDR_LEN)
	) datamem (
    	.i_clk(clk),
		.i_wr_en(w_wr_en && (w_addr < p_DATA_COUNT)),
		
    	.i_addr(w_addr),
		.o_rd_data(w_rd_data),
		.i_wr_data(w_wr_data)
	);

	// The reference model
	simulator #(
		.INSTRUCTION_COUNT(p_INST_COUNT), 
		.DATA_COUNT(p_DATA_COUNT)
	) sim;	

	// Misc helper variables	
	string temp;
	int fail_count = 0;
	
	initial begin
        $display("Staring core processor test");
      
		// Prepare dumpfile
		$dumpfile("dump.vcd");
		$dumpvars(0, core_test);

		// Initialize simulator		
		sim = new();
		inst = new();

      	rst = 1;
      	@(negedge clk);
		rst = 0;      	

		// Main loop			
		for(int i = 0; i < p_INST_COUNT; i = i + 1) begin
      		// // Randomize the instruction
			// inst.randomize();
          	// inst.cg.sample();

			// // Set instruction to execute in the simulator
			// sim.set_inst(inst);
			// // Set instruction to execute in the DUT
			// inst_reg = inst.to_bin();

			// // Display the states of DUT and simulator
			// if(p_LOG_TRACE) begin
			// 	$display("sim : %s", sim.to_string());
			// 	$display("dut : %s", dut_to_string());
            //   	$display("%s", dut_to_string_detailed());
			// 	$display();
			// end
          
          	// Counter for number of instructions completed			
			if(i % (p_INST_COUNT / 10) == 0)
				$display("%d instructions completed", i);
												
			// Flush invalid bubbles from the pipeline
			do begin
				@(negedge clk);
            end while(~core_dut.r_valid_wb);
          	
          	@(update_evt);
			
          	// Show the instruction queue
          	if(p_LOG_TRACE) begin
          		$display("Instruction window");
                foreach(inst_window[i])
                    $display(inst_window[i].to_string());
                $display();
        	end
          
          	// Remove from the tail of the queue
          	sim.set_inst(inst_window.pop_front());
			sim.exec_inst();
          	
          	// Verify that both simulator and DUT have identical states			
			if(~verify_status()) break;
		end

      	$display("Number of failures : %d", fail_count);
      	$display("Instruction coverage : %s", inst.get_coverage());

        $display("Finished core processor test");
		$finish;
	end
	
  	always @(negedge clk) begin
    	// Display the states of DUT and simulator
		if(p_LOG_TRACE) begin
          	$display("----------------------------------------------------");
          	$display("time: %t", $time);
            $display("dut : %s", dut_to_string());
            $display("%s", dut_to_string_detailed());
		end

		// Send the next instruction if last PC requested was different
      	if(~core_dut.w_stall_fetch) begin
			generate_inst();
			inst_reg = inst.to_bin();

			if(p_LOG_TRACE)
				$display("Sending new instruction : %s", inst.to_string());
		end
		else
			if(p_LOG_TRACE)
				$display("Fetch stalled!");
      	if(p_LOG_TRACE)
        	$display();
      
      	->update_evt;

    end
  	
	function generate_inst();
		inst.randomize();
		inst.cg.sample();
		inst2 = new inst;
      	inst_window.push_back(inst2);
	endfunction
	
	// Verify that DUT and simulator have identical states in commit
	function bit verify_status();
		bit failed = 0;
		
		// Compare program counter
      	assert(core_dut.r_pc_wb === sim.program_counter_prev) else begin
			fail_count++;
			failed = 1;
		end;

		// Compare register values	
		for(int i = 1; i < 8; i = i + 1)
          assert(sim.registers.read_reg(i) === core_dut.regfile_inst.r_memory[i]) else begin
				fail_count++;
				failed = 1;
			end;
      
		// Output states for debugging		
      	if(failed || p_LOG_TRACE) begin
          	if(failed)
				$display("Verification failed!");
			$display("dut : %s", dut_to_string());
			$display("sim : %s", sim.to_string());
		
			if(inst.opcode == LW) begin
				$display(sim.data_mem.write_hist);
				$display(sim.data_mem.write_data_hist);
			end
          	$display();
		end
		
		return ~failed;
	endfunction
	
	// Return string representation of the DUT state (program_count : next_inst : register values)
	function string dut_to_string();
		automatic string temp = "";
		
      	temp = $sformatf("%4h : %-17s: ", core_dut.r_pc_wb, inst.to_string());
		
		for(int i = 0; i < 8; i = i + 1)
        	temp = $sformatf("%s r%1d-%h", temp, i, core_dut.regfile_inst.r_memory[i]);
		
		return temp;
	endfunction
	
    function string dut_to_string_detailed();
		automatic string temp = "";
		
		temp = $sformatf("%sStall origins     : %4d %4d %4d %4d %4d \n", "", core_dut.r_stall_fetch, core_dut.r_stall_decode, core_dut.r_stall_exec, core_dut.r_stall_mem, core_dut.r_stall_wb);
		temp = $sformatf("%sStalled           : %4d %4d %4d %4d %4d \n", temp, core_dut.w_stall_fetch, core_dut.w_stall_decode, core_dut.w_stall_exec, core_dut.w_stall_mem, core_dut.w_stall_wb);
		temp = $sformatf("%sValid             : %4d %4d %4d %4d %4d \n", temp, core_dut.r_valid_fetch, core_dut.r_valid_decode, core_dut.r_valid_exec, core_dut.r_valid_mem, core_dut.r_valid_wb);
		temp = $sformatf("%sProgram counters  : %4h %4h %4h %4h %4h \n", temp, core_dut.r_pc_fetch, core_dut.r_pc_decode, core_dut.r_pc_exec, core_dut.r_pc_mem, core_dut.r_pc_wb);
		temp = $sformatf("%sOpcodes           : ", temp);
		temp = $sformatf("%s%4s %4s %4s %4s %4s\n", temp, 
				opcode_to_string(core_dut.w_opcode_fetch), 
				opcode_to_string(core_dut.r_opcode_decode), 
				opcode_to_string(core_dut.r_opcode_exec), 
				opcode_to_string(core_dut.r_opcode_mem), 
				opcode_to_string(core_dut.r_opcode_wb));
		temp = $sformatf("%sResults           : %4s %4s %4h %4h %4h\n", temp, "", "", core_dut.r_result_alu_exec, core_dut.w_result_mem, core_dut.r_result_wb);
		temp = $sformatf("%sTarget            : %4s %4d %4d %4d %4d\n", temp, "", core_dut.r_tgt_decode, core_dut.r_tgt_exec, core_dut.r_tgt_mem, core_dut.r_tgt_wb);
		temp = $sformatf("%sSource1           : %4s %4d %4s %4s %4s\n", temp, "", core_dut.r_src1_decode, "", "", "");
		temp = $sformatf("%sSource2           : %4s %4d %4s %4s %4s\n", temp, "", core_dut.r_src2_decode, "", "", "");
		temp = $sformatf("%sOperand1          : %4s %4h:%4h %4s %4s\n", temp, "", core_dut.r_operand1_decode, core_dut.r_operand1_fwd, "", "");
		temp = $sformatf("%sOperand2          : %4s %4h:%4h %4s %4s\n", temp, "", core_dut.r_operand2_decode, core_dut.r_operand2_fwd, "", "");
		temp = $sformatf("%sImmediate operand : %4s %4h %4h %4s %4s\n", temp, "", core_dut.r_operand_imm_decode, core_dut.r_operand_imm_exec, "", "");

		return temp;
    endfunction

	function string opcode_to_string(bit[2:0] inp);
		case (inp)
			0 : return "ADD";
			1 : return "ADDI";
			2 : return "NAND";
			3 : return "LUI";
			4 : return "SW";
			5 : return "LW";
			6 : return "BEQ";
			7 : return "JALR";
			default: return "??"; 
		endcase
	endfunction

endmodule

`endif
