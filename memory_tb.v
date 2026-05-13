`timescale 1ns / 1ps


module memory_tb();

    reg         clk;
    reg         rst;

    // Inputs from EX/MEM stage
    reg  [1:0]  ex_mem_wb;         
    reg         ex_mem_branch;     
    reg         ex_mem_memread;    
    reg         ex_mem_memwrite;   
    reg         ex_mem_zero;       
    reg  [31:0] ex_mem_alu_result; 
    reg  [31:0] ex_mem_read_data2; 
    reg  [4:0]  ex_mem_write_reg;  

    // Outputs
    wire        pc_src;
    wire        reg_write;
    wire [4:0]  write_reg;
    wire [31:0] write_data;

    // Instantiate DUT
    mem_wb_stage dut (
        .clk(clk),
        .rst(rst),
        .ex_mem_wb(ex_mem_wb),
        .ex_mem_branch(ex_mem_branch),
        .ex_mem_memread(ex_mem_memread),
        .ex_mem_memwrite(ex_mem_memwrite),
        .ex_mem_zero(ex_mem_zero),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_read_data2(ex_mem_read_data2),
        .ex_mem_write_reg(ex_mem_write_reg),
        .pc_src(pc_src),
        .reg_write(reg_write),
        .write_reg(write_reg),
        .write_data(write_data)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

         // initialize inputs
        ex_mem_wb         = 2'b00;
        ex_mem_branch     = 1'b0;
        ex_mem_memread    = 1'b0;
        ex_mem_memwrite   = 1'b0;
        ex_mem_zero       = 1'b0;
        ex_mem_alu_result = 32'd0;
        ex_mem_read_data2 = 32'd0;
        ex_mem_write_reg  = 5'd0;

        // reset
        #5;
        rst = 0;

        // --------------------------------------------------
        // 1) SW test
        // sw , 4($t)
        // store value 99 into memory word index 1
        // alu_result = 4 -> addr = 1
        // --------------------------------------------------
        #10;
        ex_mem_wb         = 2'b00;   // no WB
        ex_mem_branch     = 1'b0;
        ex_mem_memread    = 1'b0;
        ex_mem_memwrite   = 1'b1;    // store
        ex_mem_zero       = 1'b0;
        ex_mem_alu_result = 32'd4;   // memory address
        ex_mem_read_data2 = 32'd99;  // data to store
        ex_mem_write_reg  = 5'd0;

        #10; 

        // --------------------------------------------------
        // 2) LW 
        // load from same address 4, should get 99
        // write back to register 8
        // ex_mem_wb[1]=RegWrite, ex_mem_wb[0]=MemtoReg
        // for lw => 2'b11
        // --------------------------------------------------
        ex_mem_wb         = 2'b11;   // RegWrite=1, MemtoReg=1
        ex_mem_branch     = 1'b0;
        ex_mem_memread    = 1'b1;    // load
        ex_mem_memwrite   = 1'b0;
        ex_mem_zero       = 1'b0;
        ex_mem_alu_result = 32'd4;   // same address
        ex_mem_read_data2 = 32'd0;
        ex_mem_write_reg  = 5'd8;    // destination reg

        #10; 

        // --------------------------------------------------
        // 3) R-type 
        // ALU result should pass through to WB
        // write back ALU result 25 to register 10
        // for R-type => RegWrite=1, MemtoReg=0 => 2'b10
        // --------------------------------------------------
        ex_mem_wb         = 2'b10;
        ex_mem_branch     = 1'b0;
        ex_mem_memread    = 1'b0;
        ex_mem_memwrite   = 1'b0;
        ex_mem_zero       = 1'b0;
        ex_mem_alu_result = 32'd25;  // ALU result
        ex_mem_read_data2 = 32'd0;
        ex_mem_write_reg  = 5'd10;

        #10;

        // --------------------------------------------------
        // 4) BEQ 
        // branch = 1 and zero = 1 => pc_src = 1
        // no memory write, no reg write
        // --------------------------------------------------
        ex_mem_wb         = 2'b00;
        ex_mem_branch     = 1'b1;
        ex_mem_memread    = 1'b0;
        ex_mem_memwrite   = 1'b0;
        ex_mem_zero       = 1'b1;
        ex_mem_alu_result = 32'd0;
        ex_mem_read_data2 = 32'd0;
        ex_mem_write_reg  = 5'd0;

        #20;

        $finish;
    end


endmodule
