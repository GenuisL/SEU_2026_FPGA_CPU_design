module dec2seg(
    input [3:0] dec,
    output reg [6:0] seg
    );
   
   //--共阳极数码管
	always @(*)
	   begin
		case (dec)
			4'd0: seg <= 8'b1000000;
			4'd1: seg <= 8'b1111001;
			4'd2: seg <= 8'b0100100;
			4'd3: seg <= 8'b0110000;
			4'd4: seg <= 8'b0011001;
			4'd5: seg <= 8'b0010010;
			4'd6: seg <= 8'b0000010;
			4'd7: seg <= 8'b1111000;
			4'd8: seg <= 8'b0000000;
			4'd9: seg <= 8'b0010000;
			4'd10: seg <= 8'b0001000;
			4'd11: seg <= 8'b0000011;
			4'd12: seg <= 8'b1000110;
			4'd13: seg <= 8'b0100001;
			4'd14: seg <= 8'b0000110;
			default: seg <= 8'b0001110;
		endcase
		end

endmodule
