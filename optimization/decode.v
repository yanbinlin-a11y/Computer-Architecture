module decode_stage(
    input wire clk,
    input wire rst,
    input wire [31:0] instr,
    input wire regWrite,
    input wire [31:0] npc,
    input wire [4:0] writeReg,
    input wire [31:0] writeData,

    output wire [1:0] writeBack,
    output wire [2:0] memory,
    output wire [1:0] aluOp,
    output wire aluSrc,
    output wire regDst,
    output wire [31:0] nextPc,
    output wire [31:0] readdata1,
    output wire [31:0] readdata2,
    output wire [31:0] signExtend,
    output wire [4:0] instruct2016,
    output wire [4:0] instruct1511,
    output wire [4:0] instruct2521
);

    wire [3:0] ex_internal;
    wire [2:0] mem_internal;
    wire [1:0] wb_internal;
    wire [31:0] read_data1_internal;
    wire [31:0] read_data2_internal;
    wire [31:0] sign_ext_internal;

    control_unit cu(
        .opcode(instr[31:26]),
        .ex_out(ex_internal),
        .m_out(mem_internal),
        .wb_out(wb_internal)
    );

    register reg0(
        .clk(clk),
        .rst(rst),
        .RegWrite(regWrite),
        .Read_Reg1(instr[25:21]),
        .Read_Reg2(instr[20:16]),
        .Write_Reg(writeReg),
        .Write_Data(writeData),
        .Read_Data1(read_data1_internal),
        .Read_Data2(read_data2_internal)
    );

    sign_extend se(
        .immediate_in(instr[15:0]),
        .immediate_out(sign_ext_internal)
    );

    assign writeBack    = wb_internal;
    assign memory       = mem_internal;
    assign regDst       = ex_internal[3];
    assign aluOp        = ex_internal[2:1];
    assign aluSrc       = ex_internal[0];
    assign nextPc       = npc;
    assign readdata1    = read_data1_internal;
    assign readdata2    = read_data2_internal;
    assign signExtend   = sign_ext_internal;
    assign instruct2016 = instr[20:16];
    assign instruct1511 = instr[15:11];
    assign instruct2521 = instr[25:21];
endmodule

module control_unit (
    input wire [5:0] opcode,
    output reg [3:0] ex_out,
    output reg [2:0] m_out,
    output reg [1:0] wb_out
);

parameter RTYPE = 6'b000000, LW = 6'b100011, SW = 6'b101011, BEQ = 6'b000100;

    always @(*) begin
        case (opcode)
            RTYPE: begin
                ex_out = 4'b1_10_0; m_out = 3'b0_0_0; wb_out = 2'b1_0;
            end
            LW: begin
                ex_out = 4'b0_00_1; m_out = 3'b0_1_0; wb_out = 2'b1_1;
            end
            SW: begin
                ex_out = 4'b0_00_1; m_out = 3'b0_0_1; wb_out = 2'b0_0;
            end
            BEQ: begin
                ex_out = 4'b0_01_0; m_out = 3'b1_0_0; wb_out = 2'b0_0;
            end
            default: begin
                ex_out = 4'b0_00_0; m_out = 3'b0_0_0; wb_out = 2'b0_0;
            end
        endcase
    end
endmodule

module register(
    input wire clk,
    input wire rst,
    input wire RegWrite,
    input wire [4:0] Read_Reg1,
    input wire [4:0] Read_Reg2,
    input wire [4:0] Write_Reg,
    input wire [31:0] Write_Data,
    output reg [31:0] Read_Data1,
    output reg [31:0] Read_Data2
);

    reg [31:0] registers [31:0];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end else begin
            if (RegWrite && (Write_Reg != 5'd0))
                registers[Write_Reg] <= Write_Data;
            registers[0] <= 32'd0;
        end
    end

    always @(*) begin
        Read_Data1 = (Read_Reg1 == 5'd0) ? 32'd0 : registers[Read_Reg1];
        Read_Data2 = (Read_Reg2 == 5'd0) ? 32'd0 : registers[Read_Reg2];
    end
endmodule

module sign_extend (
    input wire [15:0] immediate_in,
    output wire [31:0] immediate_out
);
    assign immediate_out = {{16{immediate_in[15]}}, immediate_in};
endmodule

module id_ex_latch (
    input wire clk,
    input wire rst,
    input wire [1:0] wb_in,
    input wire [2:0] m_in,
    input wire [3:0] ex_in,
    input wire [31:0] npc_in,
    input wire [31:0] read_data1_in,
    input wire [31:0] read_data2_in,
    input wire [31:0] sign_ext_in,
    input wire [4:0] instr_2016_in,
    input wire [4:0] instr_1511_in,
    input  wire [4:0] instr_2521_in,
    
    output reg [1:0] wb_out,
    output reg [2:0] m_out,
    output reg [3:0] ex_out,
    output reg [31:0] npc_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] sign_ext_out,
    output reg [4:0] instr_2016_out,
    output reg [4:0] instr_1511_out,
    output reg  [4:0] instr_2521_out
);
    always @(posedge clk) begin
        if (rst) begin
            {wb_out, m_out, ex_out} <= 9'd0;
            npc_out <= 32'd0;
            read_data1_out <= 32'd0;
            read_data2_out <= 32'd0;
            sign_ext_out <= 32'd0;
            instr_2016_out <= 5'd0;
            instr_1511_out <= 5'd0;
            instr_2521_out <= 5'd0;
        end else begin
            wb_out <= wb_in;
            m_out <= m_in;
            ex_out <= ex_in;
            npc_out <= npc_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            sign_ext_out <= sign_ext_in;
            instr_2016_out <= instr_2016_in;
            instr_1511_out <= instr_1511_in;
            instr_2521_out <= instr_2521_in;
        end
    end
endmodule