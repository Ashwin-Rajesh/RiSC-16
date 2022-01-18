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

// Test the processor core
module core_test;
	// Parameters for configuration
	localparam p_INST_COUNT = 100000;
	localparam p_DATA_COUNT = 1024;
	localparam p_LOG_TRACE = 0;
	
	// Instruction to execute
	instruction inst;

	// Signals to connect to the DUT
	bit clk;
	bit rst;
	bit[15:0] inst_reg;	
	wire[15:0] pc;

	// Generate clock signal
	always #5 clk = ~clk;

	// The DUT	
	core #(
		.p_DATA_MEM_SIZE(p_DATA_COUNT)
	) core_dut (
		.i_clk(clk),
		.i_rst(rst),
		.i_inst(inst_reg),
		.o_pc(pc)
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
      
		#1;

		// Main loop			
		for(int i = 0; i < p_INST_COUNT; i = i + 1) begin
			// Randomize the instruction
			inst.randomize();
          	inst.cg.sample();

			// Set instruction to execute in the simulator
			sim.set_inst(inst);
			// Set instruction to execute in the DUT
			inst_reg = inst.to_bin();

			// Display the states of DUT and simulator
			if(p_LOG_TRACE) begin
				$display("sim : %s", sim.to_string());
				$display("dut : %s", dut_to_string());
				$display();
			end

			// Counter for number of instructions completed			
			if(i % (p_INST_COUNT / 10) == 0)
				$display("%d instructions completed", i);
												
			// Execute instruction in simulator
			sim.exec_inst();
			// Execute the instruction in the DUT
			@(negedge clk);        

			// Verify that both simulator and DUT have identical states			
			if(~verify_status()) break;
		end

      	$display("Number of failures : %d", fail_count);
      	$display("Instruction coverage : %s", inst.get_coverage());

        $display("Finished core processor test");
		$finish;
	end

	// Verify that DUT and simulator have identical states
	function bit verify_status();
		bit failed = 0;
		
		// Compare program counter
		assert(pc === sim.program_counter) else begin
			fail_count++;
			failed = 1;
		end;

		// Compare register values	
		for(int i = 1; i < 8; i = i + 1)
			assert(sim.registers.read_reg(i) === core_dut.regfile.memory[i]) else begin
				fail_count++;
				failed = 1;
			end;

		// Output states for debugging		
		if(failed) begin
			$display("Verification failed!");
			$display("dut : %s", dut_to_string());
			$display("sim : %s", sim.to_string());
		
			if(inst.opcode == LW) begin
				$display(sim.data_mem.write_hist);
				$display(sim.data_mem.write_data_hist);
			end
		end
		
		return ~failed;
	endfunction

	// Return string representation of the DUT state (program_count : next_inst : register values)
	function string dut_to_string();
		automatic string temp = "";
			
			temp = $sformatf("%3d : %-17s: ", pc, inst.to_string());
			
			for(int i = 0; i < 8; i = i + 1)
					temp = $sformatf("%s r%1d-%h", temp, i, core_dut.regfile.memory[i]);
		
		return temp;
	endfunction

endmodule

`endif
