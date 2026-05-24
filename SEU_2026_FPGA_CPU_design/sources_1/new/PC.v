module PC(

    input wire clk,
    input wire rst,

    input wire pc_we,
    input wire [7:0] pc_next,

    output reg [7:0] pc

);

always @(posedge clk or posedge rst)
begin

    if(rst)
        pc <= 8'd0;

    else if(pc_we)
        pc <= pc_next;

end

endmodule
