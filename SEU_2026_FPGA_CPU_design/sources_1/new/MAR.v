module MAR(

    input wire clk,
    input wire rst,

    input wire mar_we,
    input wire [7:0] mar_in,

    output reg [7:0] mar_out

);

always @(posedge clk or posedge rst)
begin

    if(rst)
        mar_out <= 8'd0;

    else if(mar_we)
        mar_out <= mar_in;

end

endmodule
