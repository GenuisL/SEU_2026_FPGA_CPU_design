`timescale 1ns / 1ps

module CpuTb;

reg clk;
reg rst;
reg [4:1] key;
integer cycle_count;

wire [7:0] seg;
wire [3:0] an;
wire [8:1] led;

CpuTop uut(
    .clk(clk),
    .rst(rst),
    .key(key),
    .seg_ap(seg),
    .seg_s(an),
    .led(led)
);

always #5 clk = ~clk;

task press_reset;
    begin
        rst = 1'b1;
        repeat (8) @(posedge clk);
        rst = 1'b0;
        repeat (4) @(posedge clk);
    end
endtask

task press_key;
    input integer idx;
    begin
        key[idx] = 1'b1;
        repeat (8) @(posedge clk);
        key[idx] = 1'b0;
    end
endtask

task wait_halt_and_check;
    input [15:0] expected;
    input [127:0] name;
    begin
        cycle_count = 0;
        while ((led[2] == 1'b1) && (cycle_count < 100)) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        cycle_count = 0;
        while ((led[2] != 1'b1) && (cycle_count < 12000)) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        if (led[2] != 1'b1) begin
            $display("====================================");
            $display("TEST FAIL : %0s", name);
            $display("REASON    : TIMEOUT WAITING FOR HALT");
            $display("CYCLES    : %0d", cycle_count);
            $display("====================================");
            $finish;
        end

        repeat (2) @(posedge clk);

        if (uut.acc_out == expected) begin
            $display("====================================");
            $display("TEST PASS : %0s", name);
            $display("ACC       : %0d (0x%04h)", uut.acc_out, uut.acc_out);
            $display("====================================");
        end else begin
            $display("====================================");
            $display("TEST FAIL : %0s", name);
            $display("EXPECTED  : %0d (0x%04h)", expected, expected);
            $display("ACTUAL    : %0d (0x%04h)", uut.acc_out, uut.acc_out);
            $display("====================================");
            $finish;
        end
    end
endtask

initial begin
    $display("CPU_TB_SUITE_V2");
    clk = 1'b0;
    rst = 1'b0;
    key = 4'b0000;

    repeat (10) @(posedge clk);

    // key[1] : 1+...+100 = 5050
    press_key(1);
    wait_halt_and_check(16'd5050, "KEY1 SUM1TO100");

    // rst -> key[2] : MUL/AND/OR test = 287
    press_reset;
    press_key(2);
    wait_halt_and_check(16'd287, "KEY2 LOGIC_MUL");

    // rst -> key[3] : NOT/SHIFTR/SHIFTL test = 0xFF1E
    press_reset;
    press_key(3);
    wait_halt_and_check(16'hFF1E, "KEY3 SHIFT_NOT");

    // rst -> key[4] : JMPGEZ/JMP test = 1234
    press_reset;
    press_key(4);
    wait_halt_and_check(16'd1234, "KEY4 JUMP");

    $display("------------------------------------");
    $display("ALL TESTS FINISHED");
    $display("------------------------------------");
    $finish;
end

endmodule
