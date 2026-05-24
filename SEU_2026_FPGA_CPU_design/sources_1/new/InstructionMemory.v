module InstructionMemory(
    input wire clk,
    input wire [7:0] addr,
    input wire mem_we,
    input wire [15:0] mem_in,
    input wire load_program,
    input wire [1:0] program_sel,
    output wire [15:0] instr
);

reg [15:0] mem [0:255];
integer i;

task load_image;
    input [1:0] sel;
    begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 16'h0000;
        end

        case (sel)
            2'd0: begin
                // key[1] : 1+2+...+100 = 5050=0x13BA 综合测试，正确结果 5050(0x13BA)
                mem[8'h00] = 16'h010B; // LOAD  0x0B -> ACC = sum, initial value 0
                mem[8'h01] = 16'h030C; // ADD   0x0C -> ACC = sum + i
                mem[8'h02] = 16'h020B; // STORE 0x0B -> sum = ACC
                mem[8'h03] = 16'h010C; // LOAD  0x0C -> ACC = i
                mem[8'h04] = 16'h030D; // ADD   0x0D -> ACC = i + 1
                mem[8'h05] = 16'h020C; // STORE 0x0C -> i = i + 1
                mem[8'h06] = 16'h040E; // SUB   0x0E -> ACC = i - 101
                mem[8'h07] = 16'h0509; // JMPGEZ 0x09 -> if i >= 101 then jump to output
                mem[8'h08] = 16'h0600; // JMP   0x00 -> loop back
                mem[8'h09] = 16'h010B; // LOAD  0x0B -> ACC = final sum
                mem[8'h0A] = 16'h0700; // HALT      -> stop, ACC should be 5050

                mem[8'h0B] = 16'h0000; // data sum  = 0
                mem[8'h0C] = 16'h0001; // data i    = 1
                mem[8'h0D] = 16'h0001; // data one  = 1
                mem[8'h0E] = 16'h0065; // data 101  = 101, used by SUB for loop end
            end

            2'd1: begin
                // key[2] : MUL / AND / OR 综合测试，正确结果 287(0x011F)
                mem[8'h00] = 16'h0110; // LOAD 0x10 -> 6    
                mem[8'h01] = 16'h0811; // MUL  0x11 -> 6*7=42
                mem[8'h02] = 16'h0215; // STORE 0x15
                mem[8'h03] = 16'h0112; // LOAD 0x12 -> 0x00F0
                mem[8'h04] = 16'h0A13; // AND  0x13 -> 0x00F0
                mem[8'h05] = 16'h0B14; // OR   0x14 -> 0x00F5
                mem[8'h06] = 16'h0315; // ADD  0x15 -> 0x00F5 + 42 = 287
                mem[8'h07] = 16'h0700; // HALT

                mem[8'h10] = 16'h0006; // data A = 6
                mem[8'h11] = 16'h0007; // data B = 7
                mem[8'h12] = 16'h00F0; // data C = 0x00F0
                mem[8'h13] = 16'h0FF0; // data D = 0x0FF0
                mem[8'h14] = 16'h0005; // data E = 5
                mem[8'h15] = 16'h0000; // data TEMP = 0, stores MUL result 42
            end

            2'd2: begin
                // key[3] : NOT / SHIFTR / SHIFTL 综合测试，正确结果 65310(0xFF1E)
                mem[8'h00] = 16'h0C10; // NOT    0x10 -> ~0x00F0 = 0xFF0F
                mem[8'h01] = 16'h0213; // STORE  0x13
                mem[8'h02] = 16'h0D11; // SHIFTR 0x11 -> 0x0009
                mem[8'h03] = 16'h0214; // STORE  0x14
                mem[8'h04] = 16'h0E12; // SHIFTL 0x12 -> 0x0006
                mem[8'h05] = 16'h0314; // ADD    0x14 -> 0x000F
                mem[8'h06] = 16'h0313; // ADD    0x13 -> 0xFF1E
                mem[8'h07] = 16'h0700; // HALT

                mem[8'h10] = 16'h00F0; // data A = 0x00F0, used by NOT
                mem[8'h11] = 16'h0012; // data B = 0x0012, used by SHIFTR -> 0x0009
                mem[8'h12] = 16'h0003; // data C = 0x0003, used by SHIFTL -> 0x0006
                mem[8'h13] = 16'h0000; // data TEMP1 = 0, stores NOT result
                mem[8'h14] = 16'h0000; // data TEMP2 = 0, stores SHIFTR result
            end

            default: begin
                // key[4] : JMPGEZ / JMP 分支测试，正确结果 1234(0x04D2)
                mem[8'h00] = 16'h0110; // LOAD  0x10 -> 1
                mem[8'h01] = 16'h0504; // JMPGEZ 0x04，条件成立，应跳转
                mem[8'h02] = 16'h0115; // LOAD  0x15，错误路径，应被跳过
                mem[8'h03] = 16'h0700; // HALT，错误路径，应被跳过
                mem[8'h04] = 16'h0111; // LOAD  0x11 -> 0
                mem[8'h05] = 16'h0412; // SUB   0x12 -> -1
                mem[8'h06] = 16'h0508; // JMPGEZ 0x08，条件不成立，不应跳转
                mem[8'h07] = 16'h0609; // JMP   0x09，跳到正确出口
                mem[8'h08] = 16'h0116; // LOAD  0x16，错误路径，不应执行
                mem[8'h09] = 16'h0113; // LOAD  0x13 -> 1234
                mem[8'h0A] = 16'h0700; // HALT

                mem[8'h10] = 16'h0001; // data A = 1
                mem[8'h11] = 16'h0000; // data B = 0
                mem[8'h12] = 16'h0001; // data C = 1, used to create -1 by SUB
                mem[8'h13] = 16'h04D2; // data RESULT = 1234, correct final answer
                mem[8'h15] = 16'h1111; // data WRONG1 = 0x1111, should never be loaded finally
                mem[8'h16] = 16'h2222; // data WRONG2 = 0x2222, should never be loaded finally
            end
        endcase
    end
endtask

initial begin
    load_image(2'd0);
end

always @(posedge clk) begin
    if (load_program) begin
        load_image(program_sel);
    end else if (mem_we) begin
        mem[addr] <= mem_in;
    end
end

assign instr = mem[addr];

endmodule
