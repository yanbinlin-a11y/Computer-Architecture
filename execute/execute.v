module execute_stage (
    input  wire        clk,
    input  wire [1:0]  wb_in,
    input  wire [2:0]  mem_in,
    input  wire        reg_dst_in,
    input  wire        alu_src_in,
    input  wire [1:0]  alu_op_in,
    input  wire [31:0] npc_in,
    input  wire [31:0] read_data1_in,
    input  wire [31:0] read_data2_in,
    input  wire [31:0] sign_ext_imm_in,
    input  wire [4:0]  instr_20_16_in,
    input  wire [4:0]  instr_15_11_in,
    output wire [1:0]  wb_out,
    output wire [2:0]  mem_out,
    output wire [31:0] add_result_out,
    output wire        zero_out,
    output wire [31:0] alu_result_out,
    output wire [31:0] read_data2_exmem_out,
    output wire [4:0]  dest_reg_out
);

    wire [31:0] branch_add_result;
    wire [31:0] alu_input_b;
    wire [31:0] alu_result_internal;
    wire [2:0]  alu_control_signal;
    wire        alu_zero_internal;
    wire [4:0]  selected_dest_reg;

    ex_branch_adder u_branch_adder (
        .a(npc_in),
        .b(sign_ext_imm_in),
        .sum(branch_add_result)
    );

    ex_dest_reg_mux u_dest_reg_mux (
        .in0(instr_20_16_in),
        .in1(instr_15_11_in),
        .sel(reg_dst_in),
        .y(selected_dest_reg)
    );

    ex_alu_src_mux u_alu_src_mux (
        .in0(read_data2_in),
        .in1(sign_ext_imm_in),
        .sel(alu_src_in),
        .y(alu_input_b)
    );

    ex_alu_control u_alu_control (
        .alu_op(alu_op_in),
        .funct(sign_ext_imm_in[5:0]),
        .alu_ctrl(alu_control_signal)
    );

    ex_alu u_alu (
        .a(read_data1_in),
        .b(alu_input_b),
        .alu_ctrl(alu_control_signal),
        .result(alu_result_internal),
        .zero(alu_zero_internal)
    );

    ex_mem_latch u_ex_mem_latch (
        .clk(clk),
        .wb_in(wb_in),
        .mem_in(mem_in),
        .add_result_in(branch_add_result),
        .zero_in(alu_zero_internal),
        .alu_result_in(alu_result_internal),
        .read_data2_in(read_data2_in),
        .dest_reg_in(selected_dest_reg),
        .wb_out(wb_out),
        .mem_out(mem_out),
        .add_result_out(add_result_out),
        .zero_out(zero_out),
        .alu_result_out(alu_result_out),
        .read_data2_out(read_data2_exmem_out),
        .dest_reg_out(dest_reg_out)
    );

endmodule

module ex_branch_adder (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] sum
);
    assign sum = a + (b << 2);
endmodule

module ex_dest_reg_mux (
    input  wire [4:0] in0,
    input  wire [4:0] in1,
    input  wire       sel,
    output wire [4:0] y
);
    assign y = sel ? in1 : in0;
endmodule

module ex_alu_control (
    input  wire [1:0] alu_op,
    input  wire [5:0] funct,
    output reg  [2:0] alu_ctrl
);

    localparam ALU_AND = 3'b000;
    localparam ALU_OR  = 3'b001;
    localparam ALU_ADD = 3'b010;
    localparam ALU_SUB = 3'b110;
    localparam ALU_SLT = 3'b111;
    localparam ALU_XXX = 3'b011;

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = ALU_ADD;
            2'b01: alu_ctrl = ALU_SUB;
            2'b10: begin
                case (funct)
                    6'b100000: alu_ctrl = ALU_ADD;
                    6'b100010: alu_ctrl = ALU_SUB;
                    6'b100100: alu_ctrl = ALU_AND;
                    6'b100101: alu_ctrl = ALU_OR;
                    6'b101010: alu_ctrl = ALU_SLT;
                    default:   alu_ctrl = ALU_XXX;
                endcase
            end
            default: alu_ctrl = ALU_XXX;
        endcase
    end

endmodule

module ex_alu_src_mux (
    input  wire [31:0] in0,
    input  wire [31:0] in1,
    input  wire        sel,
    output wire [31:0] y
);
    assign y = sel ? in1 : in0;
endmodule

module ex_alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [2:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero
);

    localparam ALU_AND = 3'b000;
    localparam ALU_OR  = 3'b001;
    localparam ALU_ADD = 3'b010;
    localparam ALU_SUB = 3'b110;
    localparam ALU_SLT = 3'b111;

    always @(*) begin
        case (alu_ctrl)
            ALU_ADD: result = a + b;
            ALU_SUB: result = a - b;
            ALU_AND: result = a & b;
            ALU_OR : result = a | b;
            ALU_SLT: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            default: result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule

module ex_mem_latch (
    input  wire        clk,
    input  wire [1:0]  wb_in,
    input  wire [2:0]  mem_in,
    input  wire [31:0] add_result_in,
    input  wire        zero_in,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] read_data2_in,
    input  wire [4:0]  dest_reg_in,
    output reg  [1:0]  wb_out,
    output reg  [2:0]  mem_out,
    output reg  [31:0] add_result_out,
    output reg         zero_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] read_data2_out,
    output reg  [4:0]  dest_reg_out
);

    initial begin
        wb_out         = 2'b00;
        mem_out        = 3'b000;
        add_result_out = 32'd0;
        zero_out       = 1'b0;
        alu_result_out = 32'd0;
        read_data2_out = 32'd0;
        dest_reg_out   = 5'd0;
    end

    always @(posedge clk) begin
        wb_out         <= wb_in;
        mem_out        <= mem_in;
        add_result_out <= add_result_in;
        zero_out       <= zero_in;
        alu_result_out <= alu_result_in;
        read_data2_out <= read_data2_in;
        dest_reg_out   <= dest_reg_in;
    end
endmodule
