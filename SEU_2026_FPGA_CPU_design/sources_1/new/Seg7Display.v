module Seg7Display(
    input clk,
    input [15:0] data,
    output [7:0] seg,
    output reg [3:0] sel
    );
    wire [3:0] a;
    wire [3:0] b;
    wire [3:0] c;
    wire [3:0] d;

    assign d = data[3:0];
    assign c = data[7:4];
    assign b = data[11:8];
    assign a = data[15:12];
	 
    reg [3:0] dec;
	wire [6:0] segt;
	reg dp;
	
   //4位二进制段码显示转换模块
	dec2seg u1 (
		 .dec(dec), 
		 .seg(segt));
	
	assign  seg = {dp,segt};	

   	 
    reg [27:0]cn28=0;
   //50000进制计数器，即1ms的计数器
	always @(posedge clk)
		if (cn28>99998)
			cn28<=0;
		else
			cn28<=cn28+1;
	  
	reg [1:0] cn2=0;
	//4ms的计数器
	always @(posedge clk)
		if (cn28==0) 
		cn2 <= cn2 + 1;
			  
   //根据cn2的值，数码管动态扫描显示4个数据
    always @(*)
		case (cn2)	  
	     0: begin
			  sel<=4'b0111;
			  dec<=a[3:0];
			  dp <= a[4];
			  end
	     1: begin
			  sel<=4'b1011;
			  dec<=b[3:0];
			  dp <= b[4];
			  end
	     2: begin
			  sel<=4'b1101;
			  dec<=c[3:0];
			  dp <= c[4];
			  end
	     default:begin
			  sel<=4'b1110;
			  dec<=d[3:0];
			  dp <= d[4];
			  end
		endcase
			

endmodule