module BR(

    input wire clk,
    input wire rst,

    input wire br_we,
    input wire [15:0] br_in,

    output reg [15:0] br_out

);

always @(posedge clk or posedge rst)
begin

    if(rst)
        br_out <= 16'd0;

    else if(br_we)
        br_out <= br_in;

end

endmodule
