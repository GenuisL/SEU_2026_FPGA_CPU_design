module MBR(

    input wire clk,
    input wire rst,

    input wire mbr_we,
    input wire [15:0] mbr_in,

    output reg [15:0] mbr_out

);

always @(posedge clk or posedge rst)
begin

    if(rst)
        mbr_out <= 16'd0;

    else if(mbr_we)
        mbr_out <= mbr_in;

end

endmodule
