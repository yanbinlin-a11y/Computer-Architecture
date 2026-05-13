module mem_wb_stage (
    input  wire        clk,
    input  wire        rst,
    input  wire [1:0]  ex_mem_wb,
    input  wire        ex_mem_branch,
    input  wire        ex_mem_memread,
    input  wire        ex_mem_memwrite,
    input  wire        ex_mem_zero,
    input  wire [31:0] ex_mem_alu_result,
    input  wire [31:0] ex_mem_read_data2,
    input  wire [4:0]  ex_mem_write_reg,
    output wire        pc_src,
    output wire        reg_write,
    output wire [4:0]  write_reg,
    output wire [31:0] write_data
);

    reg [31:0] data_mem [0:255];
    reg [31:0] mem_read_data;
    reg [1:0]  mem_wb_wb;
    reg [31:0] mem_wb_read_data;
    reg [31:0] mem_wb_alu_result;
    reg [4:0]  mem_wb_write_reg;

    assign pc_src = ex_mem_branch & ex_mem_zero;

    initial begin
        $readmemb("dataMem.mem", data_mem);
    end


    always @(posedge clk) begin
        if (ex_mem_memwrite)
            data_mem[ex_mem_alu_result[9:2]] <= ex_mem_read_data2;
    end

    always @(*) begin
        if (ex_mem_memread)
            mem_read_data = data_mem[ex_mem_alu_result[9:2]];
        else
            mem_read_data = 32'd0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_wb_wb         <= 2'b00;
            mem_wb_read_data  <= 32'd0;
            mem_wb_alu_result <= 32'd0;
            mem_wb_write_reg  <= 5'd0;
        end else begin
            mem_wb_wb         <= ex_mem_wb;
            mem_wb_read_data  <= mem_read_data;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_write_reg  <= ex_mem_write_reg;
        end
    end

    assign reg_write  = mem_wb_wb[1];
    assign write_reg  = mem_wb_write_reg;
    assign write_data = mem_wb_wb[0] ? mem_wb_read_data : mem_wb_alu_result;

endmodule
