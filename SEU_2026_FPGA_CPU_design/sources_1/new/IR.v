module IR(

    input wire clk,
    input wire rst,

    input wire ir_we,
    input wire [7:0] ir_in,

    output reg [7:0] ir_out

);

always @(posedge clk or posedge rst)
begin

    if(rst)
        ir_out <= 8'd0;

    else if(ir_we)
        ir_out <= ir_in;

end

endmodule
