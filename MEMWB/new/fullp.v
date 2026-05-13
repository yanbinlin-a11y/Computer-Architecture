`timescale 1ns / 1ps

module fullp(
    input wire clk,
    input wire rst
);

    // ---------------- Fetch outputs ----------------
    wire [31:0] if_id_instr;
    wire [31:0] if_id_npc;

    // ---------------- Decode outputs ----------------
    wire [1:0]  id_writeBack;
    wire [2:0]  id_memory;
    wire [1:0]  id_aluOp;
    wire        id_aluSrc;
    wire        id_regDst;
    wire [31:0] id_nextPc;
    
    wire [31:0] id_readdata1;
    wire [31:0] id_readdata2;
    wire [31:0] id_signExtend;
    wire [4:0]  id_instr2016;
    wire [4:0]  id_instr1511;
    wire [4:0]  id_instr2521;

    // ---------------- ID/EX latch outputs ----------------
    wire [1:0]  id_ex_wb;
    wire [2:0]  id_ex_mem;
    wire [3:0]  id_ex_ex;
    wire [31:0] id_ex_npc;
    wire [31:0] id_ex_read_data1;
    wire [31:0] id_ex_read_data2;
    wire [31:0] id_ex_sign_ext;
    wire [4:0]  id_ex_instr2016;
    wire [4:0]  id_ex_instr1511;
    wire [4:0]  id_ex_instr2521;

    // ---------------- Execute / EX-MEM outputs ----------------
    wire [1:0]  ex_mem_wb;
    wire [2:0]  ex_mem_mem;
    wire [31:0] ex_mem_add_result;
    wire        ex_mem_zero;
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_read_data2;
    wire [4:0]  ex_mem_dest_reg;

    // ---------------- Memory / Writeback outputs ----------------
    wire        mem_pc_src;
    wire        wb_reg_write;
    wire [4:0]  wb_write_reg;
    wire [31:0] wb_write_data;
    
     // ---------------- forwarding----------------
    wire [1:0]  ex_read_data1_forward_sel;
    wire [1:0]  ex_read_data2_forward_sel;
    wire [31:0] ex_read_data1_forwarded;
    wire [31:0] ex_read_data2_forwarded;
    
    
    // ---------------- Fetch stage ----------------
    fetch u_fetch(
        .clk(clk),
        .rst(rst),
        .ex_mem_pc_src(mem_pc_src),
        .ex_mem_npc(ex_mem_add_result),
        .if_id_instr(if_id_instr),
        .if_id_npc(if_id_npc)
    );

    // ---------------- Decode stage ----------------
    decode_stage u_decode_stage(
        .clk(clk),
        .rst(rst),
        .instr(if_id_instr),
        .regWrite(wb_reg_write),
        .npc(if_id_npc),
        .writeReg(wb_write_reg),
        .writeData(wb_write_data),
        .writeBack(id_writeBack),
        .memory(id_memory),
        .aluOp(id_aluOp),
        .aluSrc(id_aluSrc),
        .regDst(id_regDst),
        .nextPc(id_nextPc),
        .readdata1(id_readdata1),
        .readdata2(id_readdata2),
        .signExtend(id_signExtend),
        .instruct2016(id_instr2016),
        .instruct1511(id_instr1511),
        .instruct2521(id_instr2521)
    );

    // ---------------- ID/EX latch ----------------
    id_ex_latch u_id_ex_latch(
        .clk(clk),
        .rst(rst),
        .wb_in(id_writeBack),
        .m_in(id_memory),
        .ex_in({id_regDst, id_aluOp, id_aluSrc}),
        .npc_in(id_nextPc),
        .read_data1_in(id_readdata1),
        .read_data2_in(id_readdata2),
        .sign_ext_in(id_signExtend),
        .instr_2016_in(id_instr2016),
        .instr_1511_in(id_instr1511),
        .instr_2521_in(id_instr2521),
        .wb_out(id_ex_wb),
        .m_out(id_ex_mem),
        .ex_out(id_ex_ex),
        .npc_out(id_ex_npc),
        .read_data1_out(id_ex_read_data1),
        .read_data2_out(id_ex_read_data2),
        .sign_ext_out(id_ex_sign_ext),
        .instr_2016_out(id_ex_instr2016),
        .instr_1511_out(id_ex_instr1511),
        .instr_2521_out(id_ex_instr2521)
    );

    // ---------------- Execute stage ----------------
    execute_stage u_execute_stage(
        .clk(clk),
        .wb_in(id_ex_wb),
        .mem_in(id_ex_mem),
        .reg_dst_in(id_ex_ex[3]),
        .alu_src_in(id_ex_ex[0]),
        .alu_op_in(id_ex_ex[2:1]),
        .npc_in(id_ex_npc),
        .read_data1_in(ex_read_data1_forwarded),
        .read_data2_in(ex_read_data2_forwarded),
        .sign_ext_imm_in(id_ex_sign_ext),
        .instr_20_16_in(id_ex_instr2016),
        .instr_15_11_in(id_ex_instr1511),
        .wb_out(ex_mem_wb),
        .mem_out(ex_mem_mem),
        .add_result_out(ex_mem_add_result),
        .zero_out(ex_mem_zero),
        .alu_result_out(ex_mem_alu_result),
        .read_data2_exmem_out(ex_mem_read_data2),
        .dest_reg_out(ex_mem_dest_reg)
    );

    // ---------------- Memory + Writeback stage ----------------
    mem_wb_stage u_mem_wb_stage(
        .clk(clk),
        .rst(rst),
        .ex_mem_wb(ex_mem_wb),
        .ex_mem_branch(ex_mem_mem[2]),
        .ex_mem_memread(ex_mem_mem[1]),
        .ex_mem_memwrite(ex_mem_mem[0]),
        .ex_mem_zero(ex_mem_zero),
        .ex_mem_alu_result(ex_mem_alu_result),
        .ex_mem_read_data2(ex_mem_read_data2),
        .ex_mem_write_reg(ex_mem_dest_reg),
        .pc_src(mem_pc_src),
        .reg_write(wb_reg_write),
        .write_reg(wb_write_reg),
        .write_data(wb_write_data)
    );
    
    
// ---------------- Forwarding ----------------    
    forwarding_unit u_forwarding(
    .ex_mem_reg_write(ex_mem_wb[1]),
    .ex_mem_memread (ex_mem_mem[1]),
    .ex_mem_rd      (ex_mem_dest_reg),
    .mem_wb_reg_write(wb_reg_write),
    .mem_wb_rd      (wb_write_reg),
    .id_ex_rs       (id_ex_instr2521),
    .id_ex_rt       (id_ex_instr2016),
    .ex_read_data1_forward_sel      (ex_read_data1_forward_sel),
    .ex_read_data2_forward_sel      (ex_read_data2_forward_sel)
    );

    forward_mux u_forward_mux_0(
        .in0(id_ex_read_data1),
        .in1(wb_write_data),
        .in2(ex_mem_alu_result),
        .sel(ex_read_data1_forward_sel),
        .out(ex_read_data1_forwarded)
    );
    
    forward_mux u_forward_mux_1(
        .in0(id_ex_read_data2),
        .in1(wb_write_data),
        .in2(ex_mem_alu_result),
        .sel(ex_read_data2_forward_sel),
        .out(ex_read_data2_forwarded)
    );

endmodule









