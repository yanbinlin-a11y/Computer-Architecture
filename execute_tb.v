`timescale 1ns / 1ps
`timescale 1ns / 1ps

module execute_stage_tb;

    reg clk;

    // control inputs
    reg  [1:0]  wb_in;
    reg  [2:0]  mem_in;
    reg         reg_dst_in;
    reg         alu_src_in;
    reg  [1:0]  alu_op_in;

    // data inputs
    reg  [31:0] npc_in;
    reg  [31:0] read_data1_in;
    reg  [31:0] read_data2_in;
    reg  [31:0] sign_ext_imm_in;
    reg  [4:0]  instr_20_16_in;
    reg  [4:0]  instr_15_11_in;

    // outputs
    wire [1:0]  wb_out;
    wire [2:0]  mem_out;
    wire [31:0] add_result_out;
    wire        zero_out;
    wire [31:0] alu_result_out;
    wire [31:0] read_data2_exmem_out;
    wire [4:0]  dest_reg_out;

    // DUT
    execute_stage dut (
        .clk(clk),
        .wb_in(wb_in),
        .mem_in(mem_in),
        .reg_dst_in(reg_dst_in),
        .alu_src_in(alu_src_in),
        .alu_op_in(alu_op_in),
        .npc_in(npc_in),
        .read_data1_in(read_data1_in),
        .read_data2_in(read_data2_in),
        .sign_ext_imm_in(sign_ext_imm_in),
        .instr_20_16_in(instr_20_16_in),
        .instr_15_11_in(instr_15_11_in),
        .wb_out(wb_out),
        .mem_out(mem_out),
        .add_result_out(add_result_out),
        .zero_out(zero_out),
        .alu_result_out(alu_result_out),
        .read_data2_exmem_out(read_data2_exmem_out),
        .dest_reg_out(dest_reg_out)
    );

    // clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // initialize
        wb_in           = 2'b00;
        mem_in          = 3'b000;
        reg_dst_in      = 1'b0;
        alu_src_in      = 1'b0;
        alu_op_in       = 2'b00;
        npc_in          = 32'd0;
        read_data1_in   = 32'd0;
        read_data2_in   = 32'd0;
        sign_ext_imm_in = 32'd0;
        instr_20_16_in  = 5'd0;
        instr_15_11_in  = 5'd0;

        #10;

        // ----------------------------------------------------
        // 1) R-type: add $2, $0, $1
        // reg[0] = 0, reg[1] = 1
        // result = 1, destination at reg[2]
        // ----------------------------------------------------
        wb_in           = 2'b10;
        mem_in          = 3'b000;
        reg_dst_in      = 1'b1;
        alu_src_in      = 1'b0;
        alu_op_in       = 2'b10;
        npc_in          = 32'd4;
        read_data1_in   = 32'd0;          // rs = $0
        read_data2_in   = 32'd1;          // rt = $1
        sign_ext_imm_in = 32'h00000020;   // funct = 100000 (add)
        instr_20_16_in  = 5'd1;           // rt
        instr_15_11_in  = 5'd2;           // rd

        #10;

        // ----------------------------------------------------
        // 2) R-type: add $1, $1, $3
        // reg[1] = 1, reg[3] = 3
        // result = 4, destination at reg[1]
        // ----------------------------------------------------
        wb_in           = 2'b10;
        mem_in          = 3'b000;
        reg_dst_in      = 1'b1;
        alu_src_in      = 1'b0;
        alu_op_in       = 2'b10;
        npc_in          = 32'd8;
        read_data1_in   = 32'd1;          // rs = $1
        read_data2_in   = 32'd3;          // rt = $3
        sign_ext_imm_in = 32'h00000020;   // funct = add
        instr_20_16_in  = 5'd3;           // rt
        instr_15_11_in  = 5'd1;           // rd

        #10;

        // ----------------------------------------------------
        // 3) I-type: lw $1, 2($0)
        // address = reg[0] + 2 = 0 + 2 = 2
        // destination  at reg[1]
        // ----------------------------------------------------
        wb_in           = 2'b01;
        mem_in          = 3'b010;         // mem_read = 1
        reg_dst_in      = 1'b0;
        alu_src_in      = 1'b1;
        alu_op_in       = 2'b00;
        npc_in          = 32'd12;
        read_data1_in   = 32'd0;          // base = $0
        read_data2_in   = 32'd1;          // rt = $1 
        sign_ext_imm_in = 32'd2;          // offset
        instr_20_16_in  = 5'd1;           // rt
        instr_15_11_in  = 5'd0;           // 

        #10;

        // ----------------------------------------------------
        // 4) I-type: sw $5, 4($4)
        // reg[4] = 4, reg[5] = 5
        // address = 4 + 4 = 8
        // ReadData2 passed forward should be 5
        // ----------------------------------------------------
        wb_in           = 2'b00;
        mem_in          = 3'b001;         
        reg_dst_in      = 1'b0;
        alu_src_in      = 1'b1;
        alu_op_in       = 2'b00;
        npc_in          = 32'd16;
        read_data1_in   = 32'd4;          // base = $4
        read_data2_in   = 32'd5;          // data from $5
        sign_ext_imm_in = 32'd4;          // offset
        instr_20_16_in  = 5'd5;           // rt
        instr_15_11_in  = 5'd0;           // unused

        #10;

        // ----------------------------------------------------
        // 5) I-type: beq $7, $7, 2
        // reg[7] = 7, reg[7] = 7
        // ALU does subtraction: 7 - 7 = 0
        // zero = 1
        // add_result = npc + immediate
        // ----------------------------------------------------
        wb_in           = 2'b00;
        mem_in          = 3'b100;         // branch = 1
        reg_dst_in      = 1'b0;
        alu_src_in      = 1'b0;
        alu_op_in       = 2'b01;          // subtract for beq
        npc_in          = 32'd20;
        read_data1_in   = 32'd7;
        read_data2_in   = 32'd7;
        sign_ext_imm_in = 32'd2;
        instr_20_16_in  = 5'd7;
        instr_15_11_in  = 5'd0;

        #10;

        // ----------------------------------------------------
        // 6) invalid / unknown case
        // ----------------------------------------------------
        wb_in           = 2'b00;
        mem_in          = 3'b000;
        reg_dst_in      = 1'b0;
        alu_src_in      = 1'b0;
        alu_op_in       = 2'b11;
        npc_in          = 32'd24;
        read_data1_in   = 32'd1;
        read_data2_in   = 32'd2;
        sign_ext_imm_in = 32'd0;
        instr_20_16_in  = 5'd0;
        instr_15_11_in  = 5'd0;

        #20;
        $finish;
    end

endmodule
