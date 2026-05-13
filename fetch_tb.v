`timescale 1ns/1ps

module fetch_tb;

    reg         clk;
    reg         rst;
    reg         ex_mem_pc_src;
    reg  [31:0] ex_mem_npc;
    wire [31:0] if_id_instr;
    wire [31:0] if_id_npc;


    fetch dut (
        .clk(clk),
        .rst(rst),
        .ex_mem_pc_src(ex_mem_pc_src),
        .ex_mem_npc(ex_mem_npc),
        .if_id_instr(if_id_instr),
        .if_id_npc(if_id_npc)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        ex_mem_pc_src = 0;
        ex_mem_npc = 32'd0;
        #6
        rst = 0;
       #205
        ex_mem_pc_src = 1;
        ex_mem_npc    = 32'd16;
       #20
        ex_mem_pc_src = 0;
        ex_mem_npc    = 32'd0;
       #20
        $finish;
    end

endmodule