module CAR(

    input wire clk,
    input wire rst,

    input wire car_we,
    input wire [6:0] car_in,

    output reg [6:0] car_out

);

always @(posedge clk or posedge rst)
begin

    if(rst)
        car_out <= 7'd0;

    else if(car_we)
        car_out <= car_in;

end

endmodule
