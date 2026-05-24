
module KeyDebounce(
    input clk,
    input key,
    output reg shape=1'b0
    );
   
	reg kt=0;
	reg rs=0;
	reg rf=0;
	
	always @(posedge clk)
	    kt <= key;
        
    always @(posedge clk)
	begin
        rs<=key&(!kt);    //上升沿检测信号
        rf<=(!key)&kt;    //下降沿检测信号
	end
		
	wire [27:0] t20ms=28'd2000000;
    reg [27:0] cn_begin=0;
	reg [27:0] cn_end=0;
	always @(posedge clk)
    begin
	   //按键第一次松开20ms后清零
        if ((cn_begin==t20ms) & (cn_end==t20ms))
		    cn_begin <=0;
		//当检测到按键动作，且未计满20ms时计数
	    else if ((rs) & (cn_begin<t20ms))
		    cn_begin <= cn_begin + 1;
		//当已开始计数，且未计满20ms时计数	 
		else if ((cn_begin>0) & (cn_begin<t20ms))
		    cn_begin <= cn_begin + 1;
    end
	
	always @(posedge clk)
    begin
	    if (cn_end > t20ms)
		    cn_end <= 0;
		else if (rf & (cn_begin==t20ms))
		    cn_end <= cn_end + 1;
		else if (cn_end>0)
		    cn_end <= cn_end + 1;
    end
			
	//输出按键消抖后的信号		
	always @(posedge clk)
        shape<=(cn_begin==1)?1'b1:1'b0;	
			 
endmodule

