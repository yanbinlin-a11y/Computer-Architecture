module forwarding_unit(
    input  wire       ex_mem_reg_write,
    input  wire       ex_mem_memread,
    input  wire [4:0] ex_mem_rd,
    input  wire       mem_wb_reg_write,
    input  wire [4:0] mem_wb_rd,
    input  wire [4:0] id_ex_rs,
    input  wire [4:0] id_ex_rt,
    output reg  [1:0] ex_read_data1_forward_sel,
    output reg  [1:0] ex_read_data2_forward_sel
);

    always @(*) begin
        ex_read_data1_forward_sel = 2'b00;
        ex_read_data2_forward_sel = 2'b00;

        if (ex_mem_reg_write && !ex_mem_memread &&
            ex_mem_rd == id_ex_rs)
            ex_read_data1_forward_sel = 2'b10;
        else if (mem_wb_reg_write &&
                 mem_wb_rd == id_ex_rs)
            ex_read_data1_forward_sel = 2'b01;

        if (ex_mem_reg_write && !ex_mem_memread &&
            ex_mem_rd == id_ex_rt)
            ex_read_data2_forward_sel = 2'b10;
        else if (mem_wb_reg_write &&
                 mem_wb_rd == id_ex_rt)
            ex_read_data2_forward_sel = 2'b01;
    end
endmodule

module forward_mux(
    input  wire [31:0] in0,   
    input  wire [31:0] in1,   
    input  wire [31:0] in2,  
    input  wire [1:0]  sel,
    output reg  [31:0] out
);

    always @(*) begin
        case (sel)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            default: out = in0;
        endcase
    end
endmodule