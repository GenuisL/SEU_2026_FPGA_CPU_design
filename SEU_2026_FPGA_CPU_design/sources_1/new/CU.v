module CU(

    input wire clk,
    input wire rst,

    input wire [7:0] opcode,
    input wire [15:0] acc,

    output wire [21:0] micro_instr,
    input wire [6:0] car_out,
    output reg [6:0] next_car

);

wire [21:0] cm_out;

ControlMemory u_ControlMemory(
    .clk(clk),
    .addr(car_out),
    .micro_instr(cm_out)
);

assign micro_instr = cm_out;

always @(*)
begin

    if(cm_out[2])

        next_car = 7'd0;

    else if(cm_out[1])
    begin

        case(opcode)

            8'h01: next_car = 7'd10;
            8'h02: next_car = 7'd20;
            8'h03: next_car = 7'd30;
            8'h04: next_car = 7'd40;
            8'h05: next_car = (acc[15] == 1'b0) ? 7'd50 : 7'd0;
            8'h06: next_car = 7'd60;
            8'h07: next_car = 7'd70;
            8'h08: next_car = 7'd80;
            8'h0A: next_car = 7'd90;
            8'h0B: next_car = 7'd100;
            8'h0C: next_car = 7'd110;
            8'h0D: next_car = 7'd120;
            8'h0E: next_car = 7'd125;

            default:
                next_car = 7'd0;

        endcase

    end

    else

        next_car = car_out + 7'd1;

end

endmodule
