`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg rst;

    wire [31:0] r1;
    wire [31:0] r2;
    wire [31:0] r3;
    wire [31:0] instr;
    wire [31:0] write_data;
    wire [4:0]  write_reg;
    wire        reg_write;
    wire [31:0] pc_dbg;
    wire [1:0]  fwd1_sel;
    wire [1:0]  fwd2_sel;
    wire [31:0] src1_fwd;
    wire [31:0] src2_fwd;

assign fwd1_sel = dut.ex_read_data1_forward_sel;
assign fwd2_sel = dut.ex_read_data2_forward_sel;
assign src1_fwd = dut.ex_read_data1_forwarded;
assign src2_fwd = dut.ex_read_data2_forwarded;
    fullp dut (
        .clk(clk),
        .rst(rst)
    );
    
    assign pc_dbg = dut.u_fetch.pc0.pc_out;
    assign r1 = dut.u_decode_stage.reg0.registers[1];
    assign r2 = dut.u_decode_stage.reg0.registers[2];
    assign r3 = dut.u_decode_stage.reg0.registers[3];

    assign instr      = dut.if_id_instr;
    assign write_data = dut.wb_write_data;
    assign write_reg  = dut.wb_write_reg;
    assign reg_write  = dut.wb_reg_write;
    assign fwd1_sel = dut.ex_read_data1_forward_sel;
    assign fwd2_sel = dut.ex_read_data2_forward_sel;
    assign src1_fwd = dut.ex_read_data1_forwarded;
    assign src2_fwd = dut.ex_read_data2_forwarded;

    initial begin
        clk = 1'b0;
        forever #3 clk = ~clk;
    end

    initial begin
        $display("time\tinstr\t\twrite_data\twrite_reg\treg_write\tR1\tR2\tR3");
        $monitor("%0t\t%h\t%0d\t\t%0d\t\t%b\t\t%0d\t%0d\t%0d",
            $time, instr, write_data, write_reg, reg_write, r1, r2, r3);
    end

    initial begin
        rst = 1'b1;
        #10;
        rst = 1'b0;

        #100;

        $display("\n==== FINAL REGISTER VALUES ====");
        $display("R1 = %0d", r1);
        $display("R2 = %0d", r2);
        $display("R3 = %0d", r3);

        $finish;
    end

endmodule