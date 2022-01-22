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

`ifndef CORE_V
`define CORE_V

`include "mem_reg.v"
`include "alu.v"

// Everything except the instruction memory
module core (
    // Control signals
    input               i_clk,                  // Main clock signal
    input               i_rst,                  // Global reset

    // Instruction memory interface
    input[15:0]         i_inst,                 // Instruction input from instruction memory (read is assumed combinational)
    output[15:0]        o_pc_next,              // Program counter output to instruction memory

    // Data memory interface
    input[15:0]         i_mem_rd_data,          // Data read from memory
    output[15:0]        o_mem_wr_data,          // Data to write to memory
    output[15:0]        o_mem_addr,             // Address to write or read
    output              o_mem_wr_en             // Write enable for memory
);

    // Opcodes defined as localparam
    localparam ADD = 0,
        ADDI = 1,
        NAND = 2,
        LUI  = 3,
        SW   = 4,
        LW   = 5,
        BEQ  = 6,
        JALR = 7;

    // ---------------------------
    // Pipeline registers
    //
    // For communication between adjacent stages
    // ---------------------------
    reg r_valid_fetch   = 0;
    reg r_valid_decode  = 0;
    reg r_valid_exec    = 0;
    reg r_valid_mem     = 0;
    reg r_valid_wb      = 0;

    reg[15:0] r_pc_fetch        = 0;
    reg[15:0] r_pc_decode       = 0;
    reg[15:0] r_pc_exec         = 0;
    reg[15:0] r_pc_mem          = 0;
    reg[15:0] r_pc_wb           = 0;

    reg[15:0] r_instn_fetch     = 0;

    wire[2:0] w_opcode_fetch    = r_instn_fetch[15:13];
    reg[2:0] r_opcode_decode    = 0;
    reg[2:0] r_opcode_exec      = 0;

    reg[2:0] r_src1_decode      = 0;
    reg[2:0] r_src2_decode      = 0;

    reg[2:0] r_tgt_decode       = 0;
    reg[2:0] r_tgt_exec         = 0;
    reg[2:0] r_tgt_mem          = 0;
    reg[2:0] r_tgt_wb           = 0;

    reg[15:0] r_operand_imm_decode  = 0;
    wire[15:0] w_operand1_decode;
    wire[15:0] w_operand2_decode;

    reg[15:0] r_swdata_exec     = 0;

    reg[15:0] r_result_alu_exec = 0;
    reg[15:0] r_result_alu_mem  = 0;
    wire[15:0] w_result_mem;        // Result after mem can be from ALU or MEM
    reg[15:0] r_result_wb       = 0;

    reg r_result_eq_exec        = 0;

    // ---------------------------
    // Stall signals and stall logic
    //
    // When to stall the pipeline?
    // ---------------------------

    // Stall origins
    reg r_stall_fetch;
    reg r_stall_decode;
    reg r_stall_exec;
    reg r_stall_mem     = 0;
    reg r_stall_wb      = 0;

    // If earlier stages are stalled, then stall this stage too!
    wire w_stall_fetch;
    wire w_stall_decode;
    wire w_stall_exec;
    wire w_stall_mem;
    wire w_stall_wb;

    assign w_stall_fetch  = r_stall_fetch || w_stall_decode;
    assign w_stall_decode = r_stall_decode || w_stall_mem;
    assign w_stall_exec   = r_stall_exec || w_stall_mem;
    assign w_stall_mem    = r_stall_mem || w_stall_wb;
    assign w_stall_wb     = r_stall_wb;

    // Fetch stall logic
    always @(*) begin
        // If instruction was JALR or BEQ
        if(w_opcode_fetch == JALR 
        || w_opcode_fetch == BEQ)
            r_stall_fetch = 1'b1;
        else
            r_stall_fetch = 1'b0;
    end
    // Decode stall logic
    always @(*) begin
        // If instruction was BEQ
        if(r_opcode_decode == BEQ)
            r_stall_decode = 1'b1;
        else
            r_stall_decode = 1'b0;
    end
    // Execute stall logic
    always @(*) begin
        // LW with data hazard with next instruction
        if(r_opcode_exec == LW 
                && r_tgt_exec !== 0 
                && (r_tgt_exec == r_src1_decode || r_tgt_exec == r_src2_decode))
            r_stall_exec = 1'b1;
        else
            r_stall_exec = 1'b0;
    end
    // ---------------------------
    // Fetch stage
    //
    // Fetch next instruction
    // ---------------------------
    // The next instruction to fetch is stored here.
    // i_inst contains instruction newly fetched in this cycle
    reg[15:0] r_pc;

    initial begin
        r_pc        = 0;
    end

    assign o_pc_next = r_pc;

    // Combinational logic to decide PC to fetch next
    always @(posedge i_clk) begin
        // If stalled, retain old program counter. Dont fetch new
        if(w_stall_fetch) begin
            r_pc    <= r_pc;
        end else begin
            // BEQ after execute stage
            if(r_opcode_exec == BEQ)
                if(r_result_eq_exec)
                    r_pc    <= r_pc_decode + 1 + r_operand_imm_decode;
                else
                    r_pc    <= r_pc_decode + 1;
            // JALR after decode stage
            else if(r_opcode_decode == JALR)
                r_pc    <= r_src2_decode;
            // Any other instruction
            else
                r_pc    <= r_pc + 1;
        end
    end

    // Instruction (including stall)
    always @(posedge i_clk) begin
        // If stall originates from fetch, add a NOP
        if(r_stall_fetch) begin
            r_instn_fetch   <= 0;
            r_valid_fetch   <= 0;
        end else if(w_stall_fetch) begin
            r_instn_fetch   <= r_instn_fetch;
            r_valid_fetch   <= r_valid_fetch;
        end else begin
            r_instn_fetch   <= i_inst;
            r_valid_fetch   <= 1;
        end
    end

    // ---------------------------
    // Decode stage
    //
    // Get operands and opcode
    // ---------------------------
    // Get register mapping (from instruction to register file)

    reg[2:0] r_tgt_next;
    reg[2:0] r_src1_next;
    reg[2:0] r_src2_next;
    reg[15:0] r_imm_next;

    // Split the instruction into parts
    wire[2:0] w_opcode_decode = r_instn_fetch[15:13];
    wire[2:0] w_rega_decode   = r_instn_fetch[12:10];
    wire[2:0] w_regb_decode   = r_instn_fetch[9:7];
    wire[2:0] w_regc_decode   = r_instn_fetch[2:0];
    wire[9:0] w_limm_decode   = r_instn_fetch[9:0];
    wire[6:0] w_simm_decode   = r_instn_fetch[6:0];

    // Modify signed and long immediate to get actual immediate that will be used
    wire[15:0] w_simm_ext_decode = {{25{w_simm_decode[6]}}, w_simm_decode};
    wire[15:0] w_limm_ext_decode = {w_limm_decode, {9{1'b0}}};

    // Decide the source and destination addresses
    always @(*) begin
        case(w_opcode_fetch)
            ADD: begin
                r_tgt_next      = w_rega_decode;
                r_src1_next     = w_regb_decode;
                r_src2_next     = w_regc_decode;
                r_imm_next      = 0;
            end
            ADDI: begin
                r_tgt_next      = w_rega_decode;
                r_src1_next     = w_regb_decode;
                r_src2_next     = 3'b0;
                r_imm_next      = w_simm_ext_decode;
            end
            NAND: begin
                r_tgt_next      = w_rega_decode;
                r_src1_next     = w_regb_decode;
                r_src2_next     = w_regc_decode;
                r_imm_next      = 0;
            end
            LUI: begin
                r_tgt_next      = w_rega_decode;
                r_src1_next     = 3'b0;
                r_src2_next     = 3'b0;                
                r_imm_next      = w_limm_ext_decode;
            end
            SW: begin
                r_tgt_next      = 3'b0;
                r_src1_next     = w_regb_decode;
                r_src2_next     = w_rega_decode;
                r_imm_next      = w_simm_ext_decode;
            end
            LW: begin
                r_tgt_next      = w_rega_decode;
                r_src1_next     = w_regb_decode;
                r_src2_next     = 3'b0;
                r_imm_next      = w_simm_ext_decode;
            end
            BEQ: begin
                r_tgt_next      = 3'b0;
                r_src1_next     = w_regb_decode;
                r_src2_next     = w_rega_decode;
                r_imm_next      = 0;
            end
            JALR: begin
                r_tgt_next      = w_rega_decode;
                r_src1_next     = w_regb_decode;
                r_src2_next     = 3'b0;                
                r_imm_next      = 0;
            end
        endcase
    end

    mem_reg regfile_inst (
        .i_clk(i_clk),                      // Clock signal

        .i_src1(r_src1_next),               // Read address 1
        .i_src2(r_src2_next),               // Read address 2
        .i_tgt(r_tgt_mem),                  // Write register address

        .o_src1_data(w_operand1_decode),    // Read output 1 (asynchronous)
        .o_src2_data(w_operand2_decode),    // Read output 2 (asynchronous)
        .i_tgt_data(w_result_mem),          // Input to write to the target (on posedge)

        .i_wr_en(r_valid_mem)               // High to write on posedge
    );

    always @(posedge i_clk) begin
        // Insert bubbe
        if(r_stall_decode) begin
            r_valid_decode  <= 0;
            r_pc_decode     <= r_pc_decode;
            r_tgt_decode    <= 3'b0;
            r_src1_decode   <= 3'b0;
            r_src2_decode   <= 3'b0;
            r_opcode_decode <= ADD;
            r_operand_imm_decode <= 15'b0;
        end
        // Stall pipeline (pause)
        else if(w_stall_decode) begin
            r_valid_decode  <= r_valid_decode;
            r_pc_decode     <= r_pc_decode;
            r_tgt_decode    <= r_tgt_decode;
            r_src1_decode   <= r_src1_decode;
            r_src2_decode   <= r_src2_decode;
            r_opcode_decode <= r_opcode_decode;
            r_operand_imm_decode <= r_operand_imm_decode;
        // Send to next stage
        end else begin
            r_valid_decode  <= r_valid_fetch;
            r_pc_decode     <= r_pc_fetch;
            r_tgt_decode    <= r_tgt_next;
            r_src1_decode   <= r_src1_next;
            r_src2_decode   <= r_src2_next;
            r_opcode_decode <= w_opcode_decode;
            r_operand_imm_decode <= r_imm_next;
        end
    end

    // ---------------------------
    // Execute stage
    //
    // Execute the operation from fetched operands
    // ---------------------------

    reg         r_aluop;
    reg[15:0]   r_aluina;
    reg[15:0]   r_aluinb;
    
    wire[15:0]  w_aluout;
    wire        w_alueq;

    // Forwarded values of operand 1 and 2
    reg[15:0]   r_operand1_fwd;
    reg[15:0]   r_operand2_fwd;

    // Forward values for operand 1
    always @(*) begin
        // From EXEC
        if(r_src1_decode == r_tgt_exec)
            r_operand1_fwd <= r_result_alu_exec;
        // From MEM
        else if(r_src1_decode == r_tgt_mem)
            r_operand1_fwd <= w_result_mem;
        // From WB
        else if(r_src1_decode == r_tgt_wb)
            r_operand1_fwd <= r_result_wb;
        else
            r_operand1_fwd <= w_operand1_decode;
    end
    // Forward values for operand 2
    always @(*) begin
        // From EXEC
        if(r_src2_decode == r_tgt_exec)
            r_operand2_fwd <= r_result_alu_exec;
        // From MEM
        else if(r_src2_decode == r_tgt_mem)
            r_operand2_fwd <= w_result_mem;
        // From WB
        else if(r_src2_decode == r_tgt_wb)
            r_operand2_fwd <= r_result_wb;
        else
            r_operand2_fwd <= w_operand2_decode;
    end

    // Decide the operation and sources for the ALU
    always @(*) begin
        case(r_opcode_decode)
            ADD: begin
                r_aluop    = 1'b0;
                r_aluina   = r_operand1_fwd;
                r_aluinb   = r_operand2_fwd;
            end
            ADDI: begin
                r_aluop    = 1'b0;
                r_aluina   = r_operand1_fwd;
                r_aluinb   = r_operand_imm_decode;
            end
            NAND: begin
                r_aluop    = 1'b1;
                r_aluina   = r_operand1_fwd;
                r_aluinb   = r_operand2_fwd;
            end
            LUI: begin
                r_aluop    = 1'b0;
                r_aluina   = r_operand1_fwd;
                r_aluinb   = r_operand_imm_decode;
            end
            SW: begin
                r_aluop    = 1'b0;
                r_aluina   = r_operand1_fwd;
                r_aluinb   = r_operand_imm_decode;
            end
            LW: begin
                r_aluop    = 1'b0;
                r_aluina   = r_operand1_fwd;
                r_aluinb   = r_operand_imm_decode;
            end
            BEQ: begin
                r_aluop    = 1'b0;
                r_aluina   = r_operand1_fwd;
                r_aluinb   = r_operand2_fwd;
            end
            JALR: begin
                r_aluop    = 1'b0;
                r_aluina   = r_operand1_fwd;
                r_aluinb   = r_operand2_fwd;
            end
        endcase
    end

    alu alu_inst (
        .i_op(r_aluop),       // 0 for add, 1 for nand

        .i_ina(r_aluina),      // Input a
        .i_inb(r_aluinb),      // Input b
        
        .o_out(w_aluout),      // Output
        .o_eq(w_alueq)         // Were both inputs equal?
    );

    always @(posedge i_clk) begin
        // Insert bubble
        if(r_stall_exec) begin
            r_valid_exec        <= 0;
            r_pc_exec           <= r_pc_exec;
            r_tgt_exec          <= 3'b0;
            r_opcode_exec       <= 3'b0;
            r_swdata_exec       <= 0;
            r_result_eq_exec    <= 0;
            r_result_alu_exec   <= 0;
        // Stall (hold on to prev value)
        end else if(w_stall_exec) begin
            r_valid_exec        <= r_valid_exec;
            r_pc_exec           <= r_pc_exec;
            r_tgt_exec          <= r_tgt_exec;
            r_opcode_exec       <= r_opcode_exec;
            r_swdata_exec       <= r_swdata_exec;
            r_result_eq_exec    <= r_result_eq_exec;
            r_result_alu_exec   <= r_result_alu_exec;
        // Pass instruction through
        end else begin
            r_valid_exec        <= r_valid_decode;
            r_pc_exec           <= r_pc_decode;
            r_tgt_exec          <= r_tgt_decode;
            r_opcode_exec       <= r_opcode_decode;
            r_swdata_exec       <= w_operand2_decode;
            r_result_eq_exec    <= w_alueq;
            r_result_alu_exec   <= w_aluout;
        end    
    end

    // ---------------------------
    // Memory stage
    //
    // Read from or write to memory!
    // ---------------------------

    assign o_mem_addr       = r_result_alu_exec;
    assign o_mem_wr_data    = r_swdata_exec;
    assign o_mem_wr_en      = (r_opcode_exec == SW);

    always @(posedge i_clk) begin
        // Insert bubble
        if(r_stall_mem) begin
            r_valid_mem         <= 0;
            r_pc_mem            <= r_pc_mem;
            r_tgt_mem           <= 0;
            r_result_alu_mem    <= 0;
        // Stall (hold on to prev value)
        end else if(w_stall_mem) begin
            r_valid_mem         <= r_valid_mem;
            r_pc_mem            <= r_pc_mem;
            r_tgt_mem           <= r_tgt_mem;
            r_result_alu_mem    <= r_result_alu_mem;        
        // Move pipeline forward
        end else begin
            r_valid_mem         <= r_valid_exec;
            r_pc_mem            <= r_pc_exec;
            r_tgt_mem           <= r_tgt_exec;
            r_result_alu_mem    <= r_result_alu_exec;
        end
    end

    assign w_result_mem = (r_opcode_decode == LW) ? i_mem_rd_data : r_result_alu_mem;

    // ---------------------------
    // Writeback stage
    //
    // Write back to register file
    // ---------------------------

    // The write target and write data is set in the register file
    // instantiation itself, in the decode stage. Only job here is
    // to define the pipeline register flow!

    always @(posedge i_clk) begin
        // Insert bubble
        if(r_stall_wb) begin
            r_valid_wb          <= 0;
            r_pc_wb             <= r_pc_wb;
            r_tgt_wb            <= 0;
            r_result_wb         <= 0;
        // Stall (hold on to prev value)
        end else if(w_stall_wb) begin
            r_valid_wb          <= r_valid_wb;
            r_pc_wb             <= r_pc_wb;
            r_tgt_wb            <= r_tgt_wb;
            r_result_wb         <= r_result_wb;
        // Move pipeline forward
        end else begin
            r_valid_wb          <= r_valid_mem;
            r_pc_wb             <= r_pc_mem;
            r_tgt_wb            <= r_tgt_mem;
            r_result_wb         <= w_result_mem;
        end
    end

`ifdef FORMAL
    // Testing the pipelining and stalling
    reg[2:0] f_pipe_opcodes[4:0];
    reg[4:0] f_pipe_bubble;
    reg[2:0] f_pipe_tgt[4:0];
    

    reg f_past_valid = 0;

    integer f_i;

    always @(*) begin
        f_pipe_opcodes[0] = w_opcode_fetch;
        f_pipe_opcodes[1] = r_opcode_decode;
        f_pipe_opcodes[2] = r_opcode_exec;

        f_pipe_bubble[0] = ~r_valid_fetch;
        f_pipe_bubble[1] = ~r_valid_decode;
        f_pipe_bubble[2] = ~r_valid_exec;
        f_pipe_bubble[3] = ~r_valid_mem;
        f_pipe_bubble[4] = ~r_valid_wb;

        case(w_opcode_fetch)
            ADD: begin
                f_pipe_tgt[0]      = r_instn_fetch[12:10];
            end
            ADDI: begin
                f_pipe_tgt[0]      = r_instn_fetch[12:10];
            end
            NAND: begin
                f_pipe_tgt[0]      = r_instn_fetch[12:10];
            end
            LUI: begin
                f_pipe_tgt[0]      = r_instn_fetch[12:10];
            end
            SW: begin
                f_pipe_tgt[0]      = 3'b0;
            end
            LW: begin
                f_pipe_tgt[0]      = r_instn_fetch[12:10];
            end
            BEQ: begin
                f_pipe_tgt[0]      = 3'b0;
            end
            JALR: begin
                f_pipe_tgt[0]      = r_instn_fetch[12:10];
            end
        endcase

        f_pipe_tgt[1] = r_tgt_decode;
        f_pipe_tgt[2] = r_tgt_exec;
        f_pipe_tgt[3] = r_tgt_mem;
        f_pipe_tgt[4] = r_tgt_wb;
    end

    always @(posedge i_clk) begin
        if(f_past_valid) begin
            // Bubbles must move up the pipeline every cycle
            for(f_i = 0; f_i < 4; f_i = f_i + 1)
                if($past(f_pipe_bubble[f_i]))
                    assert(f_pipe_bubble[f_i + 1]);

            // Insert a bubble for load word
            if(f_pipe_opcodes[3] == LW) begin
                if(f_pipe_tgt[3] != 0 && (r_tgt_mem == $past(r_src1_decode) || r_tgt_mem == $past(r_src2_decode)))
                    assert(f_pipe_bubble[2]);
            end
        end
        
        f_pipe_opcodes[4] = f_pipe_opcodes[3];
        f_pipe_opcodes[3] = f_pipe_opcodes[2];
    
    
        f_past_valid = 1;
    end

    always @(*) begin
        // Check for bubbles in the pipeline
        for(f_i = 0; f_i < 5; f_i = f_i + 1) begin
            if(f_pipe_opcodes[f_i] == BEQ) begin
                if(f_i != 0)
                    assert(f_pipe_bubble[f_i - 1]);
                if(f_i > 1)
                    assert(f_pipe_bubble[f_i - 2]);
            end else if(f_pipe_opcodes[f_i] == JALR)
                if(f_i != 0)
                    assert(f_pipe_bubble[f_i - 1]);
        end
    end
`endif

endmodule

`endif
