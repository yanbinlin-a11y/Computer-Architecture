
module fetch(
    input  wire        clk,
    input  wire        rst,
    input  wire        ex_mem_pc_src,
    input  wire [31:0] ex_mem_npc,
    output wire [31:0] if_id_instr,
    output wire [31:0] if_id_npc
);

    wire [31:0] pc_out;
    wire [31:0] pc_mux;
    wire [31:0] next_pc;
    wire [31:0] instr_data;

    mux m0(
        .y(pc_mux),
        .a_true(ex_mem_npc),
        .b_false(next_pc),
        .sel(ex_mem_pc_src)
    );

    pc pc0(
        .clk(clk),
        .rst(rst),
        .pc_in(pc_mux),
        .pc_out(pc_out)
    );

    incrementer in0(
        .pcin(pc_out),
        .pcout(next_pc)
    );

    instrMem inMem0(
        .clk(clk),
        .addr(pc_out),
        .data(instr_data)
    );

    ifIdLatch ifIdLatch0(
        .clk(clk),
        .rst(rst),
        .pc_in(next_pc),
        .instr_in(instr_data),
        .pc_out(if_id_npc),
        .instr_out(if_id_instr)
    );

endmodule

module mux(
    output wire [31:0] y,
    input  wire [31:0] a_true,
    input  wire [31:0] b_false,
    input  wire        sel
);
    assign y = sel ? a_true : b_false;
endmodule

module pc(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc_in,
    output reg  [31:0] pc_out
);
    always @(posedge clk) begin
        if (rst)
            pc_out <= 32'd0;
        else
            pc_out <= pc_in;
    end
endmodule

module incrementer(
    input  wire [31:0] pcin,
    output wire [31:0] pcout
);
    assign pcout = pcin + 32'd4;
endmodule

module instrMem(
    input  wire        clk,
    input  wire [31:0] addr,
    output reg  [31:0] data
);

    reg [31:0] mem [0:255];

initial begin
        $readmemb("instrMem.mem", mem);
    end 

    always @(posedge clk) begin
        data <= mem[addr[9:2]];
    end
//    assign data = mem[addr[9:2]];

endmodule

module ifIdLatch(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] instr_out
);
    always @(posedge clk) begin
        if (rst) begin
            pc_out    <= 32'd0;
            instr_out <= 32'd0;
        end
        else begin
            pc_out    <= pc_in;
            instr_out <= instr_in;
        end
    end
endmodule