module CpuTop(
    input wire clk,
    input wire rst,
    input wire [4:1] key,
    output wire [7:0] seg_ap,
    output wire [3:0] seg_s,
    output wire [8:1] led
);

wire [7:0] pc_out;
wire [7:0] mar_out;
wire [15:0] mbr_out;
wire [7:0] ir_out;
wire [15:0] br_out;
wire [15:0] acc_out;
wire [6:0] car_out;
wire [6:0] next_car;

wire halt_flag;
wire key_reset_pulse;
wire key1_pulse;
wire key2_pulse;
wire key3_pulse;
wire key4_pulse;
wire key_run_pulse;
wire cpu_rst;
wire cpu_step_en;
wire load_program;

wire [15:0] memory_data;
wire [21:0] micro_instr;
wire [15:0] alu_result;
wire [15:0] mul_high;

reg cpu_run = 1'b0;
reg [1:0] program_sel = 2'd0;

assign halt_flag = (ir_out == 8'h07);
assign key_run_pulse = key1_pulse | key2_pulse | key3_pulse | key4_pulse;
assign cpu_rst = key_reset_pulse | key_run_pulse;
assign cpu_step_en = cpu_run & ~halt_flag;
assign load_program = key_reset_pulse | key_run_pulse;

always @(posedge clk) begin
    if (key_reset_pulse) begin
        program_sel <= 2'd0;
    end else if (key1_pulse) begin
        program_sel <= 2'd0;
    end else if (key2_pulse) begin
        program_sel <= 2'd1;
    end else if (key3_pulse) begin
        program_sel <= 2'd2;
    end else if (key4_pulse) begin
        program_sel <= 2'd3;
    end
end

always @(posedge clk or posedge cpu_rst) begin
    if (cpu_rst) begin
        cpu_run <= key_run_pulse;
    end else if (halt_flag) begin
        cpu_run <= 1'b0;
    end
end

PC u_PC(
    .clk(clk),
    .rst(cpu_rst),
    .pc_we(cpu_step_en & (micro_instr[6] | micro_instr[15])),
    .pc_next(micro_instr[15] ? mbr_out[7:0] : (pc_out + 8'd1)),
    .pc(pc_out)
);

MAR u_MAR(
    .clk(clk),
    .rst(cpu_rst),
    .mar_we(cpu_step_en & (micro_instr[5] | micro_instr[10])),
    .mar_in(micro_instr[10] ? pc_out : mbr_out[7:0]),
    .mar_out(mar_out)
);

InstructionMemory u_InstructionMemory(
    .clk(clk),
    .addr(mar_out),
    .mem_we(cpu_step_en & micro_instr[13]),
    .mem_in(mbr_out),
    .load_program(load_program),
    .program_sel(
        key1_pulse ? 2'd0 :
        key2_pulse ? 2'd1 :
        key3_pulse ? 2'd2 :
        key4_pulse ? 2'd3 :
        program_sel
    ),
    .instr(memory_data)
);

MBR u_MBR(
    .clk(clk),
    .rst(cpu_rst),
    .mbr_we(cpu_step_en & (micro_instr[3] | micro_instr[12])),
    .mbr_in(micro_instr[12] ? acc_out : memory_data),
    .mbr_out(mbr_out)
);

IR u_IR(
    .clk(clk),
    .rst(cpu_rst),
    .ir_we(cpu_step_en & micro_instr[4]),
    .ir_in(mbr_out[15:8]),
    .ir_out(ir_out)
);

BR u_BR(
    .clk(clk),
    .rst(cpu_rst),
    .br_we(cpu_step_en & micro_instr[7]),
    .br_in(mbr_out),
    .br_out(br_out)
);

ACC u_ACC(
    .clk(clk),
    .rst(cpu_rst),
    .acc_we(cpu_step_en & (micro_instr[8] | micro_instr[9] | micro_instr[11] |
            micro_instr[14] | micro_instr[16] | micro_instr[17] |
            micro_instr[18] | micro_instr[19] | micro_instr[20] |
            micro_instr[21])),
    .acc_in(
        micro_instr[8]  ? 16'd0 :
        micro_instr[11] ? br_out :
        alu_result
    ),
    .acc_out(acc_out)
);

ALU u_ALU(
    .acc(acc_out),
    .br(br_out),
    .c9(micro_instr[9]),
    .c14(micro_instr[14]),
    .c16(micro_instr[16]),
    .c17(micro_instr[17]),
    .c18(micro_instr[18]),
    .c19(micro_instr[19]),
    .c20(micro_instr[20]),
    .c21(micro_instr[21]),
    .result(alu_result),
    .mul_high(mul_high)
);

CU u_CU(
    .clk(clk),
    .rst(cpu_rst),
    .opcode(ir_out),
    .acc(acc_out),
    .car_out(car_out),
    .micro_instr(micro_instr),
    .next_car(next_car)
);

CAR u_CAR(
    .clk(clk),
    .rst(cpu_rst),
    .car_we(cpu_step_en),
    .car_in(next_car),
    .car_out(car_out)
);

KeyDebounce u_rst_KeyDebounce(
    .clk(clk),
    .key(rst),
    .shape(key_reset_pulse)
);

KeyDebounce u_key1_KeyDebounce(
    .clk(clk),
    .key(key[1]),
    .shape(key1_pulse)
);

KeyDebounce u_key2_KeyDebounce(
    .clk(clk),
    .key(key[2]),
    .shape(key2_pulse)
);

KeyDebounce u_key3_KeyDebounce(
    .clk(clk),
    .key(key[3]),
    .shape(key3_pulse)
);

KeyDebounce u_key4_KeyDebounce(
    .clk(clk),
    .key(key[4]),
    .shape(key4_pulse)
);

Seg7Display u_Seg7Display(
    .clk(clk),
    .data(acc_out),
    .seg(seg_ap),
    .sel(seg_s)
);

assign led[1] = cpu_run;
assign led[2] = halt_flag;
assign led[3] = (program_sel == 2'd0);
assign led[4] = (program_sel == 2'd1);
assign led[5] = (program_sel == 2'd2);
assign led[6] = (program_sel == 2'd3);
assign led[7] = key_run_pulse;
assign led[8] = key_reset_pulse;

endmodule
