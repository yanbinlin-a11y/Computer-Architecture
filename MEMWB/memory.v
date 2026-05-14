`timescale 1ns / 1ps


module mem_wb_stage (
    input  wire        clk,
    input  wire        rst,

    // -----------------------------
    // Inputs from 
    // -----------------------------
    input  wire [1:0]  ex_mem_wb,          // [1]=RegWrite, [0]=MemtoReg
    input  wire        ex_mem_branch,      // branch control
    input  wire        ex_mem_memread,     // memory read enable
    input  wire        ex_mem_memwrite,    // memory write enable
    input  wire        ex_mem_zero,        // ALU zero flag
    input  wire [31:0] ex_mem_alu_result,  // ALU result / memory address
    input  wire [31:0] ex_mem_read_data2,  // data to write into memory
    input  wire [4:0]  ex_mem_write_reg,   // destination register number

    // -----------------------------
    // Outputs to Fetch stage
    // -----------------------------
    output wire        pc_src,             // branch taken signal

    // -----------------------------
    // Outputs to Decode/Register File
    // -----------------------------
    output wire        reg_write,          // register write enable
    output wire [4:0]  write_reg,          // destination register
    output wire [31:0] write_data          // data written back
);

    // =========================================================
    // 1) Branch decision logic (MEM stage)
    // =========================================================
    assign pc_src = ex_mem_branch & ex_mem_zero;

    // =========================================================
    // 2) Data Memory
    // =========================================================
    reg [31:0] data_mem [0:255];
    reg [31:0] mem_read_data;

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            data_mem[i] = i;
    end

    // write memory on clock edge
    always @(posedge clk) begin
        if (ex_mem_memwrite)
            data_mem[ex_mem_alu_result>>2] <= ex_mem_read_data2;
    end

    // asynchronous read
    always @(*) begin
        if (ex_mem_memread)
            mem_read_data = data_mem[ex_mem_alu_result>>2];
        else
            mem_read_data = 32'd0;
    end

    // =========================================================
    // 3) MEM/WB pipeline latch
    // =========================================================
    reg [1:0]  mem_wb_wb;
    reg [31:0] mem_wb_read_data;
    reg [31:0] mem_wb_alu_result;
    reg [4:0]  mem_wb_write_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_wb_wb         <= 2'b00;
            mem_wb_read_data  <= 32'd0;
            mem_wb_alu_result <= 32'd0;
            mem_wb_write_reg  <= 5'd0;
        end
        else begin
            mem_wb_wb         <= ex_mem_wb;
            mem_wb_read_data  <= mem_read_data;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_write_reg  <= ex_mem_write_reg;
        end
    end

    // =========================================================
    // 4) Write Back stage
    //    mem_wb_wb[1] = RegWrite
    //    mem_wb_wb[0] = MemtoReg
    // =========================================================
    assign reg_write  = mem_wb_wb[1];
    assign write_reg  = mem_wb_write_reg;
    assign write_data = (mem_wb_wb[0]) ? mem_wb_read_data : mem_wb_alu_result;

endmodule
