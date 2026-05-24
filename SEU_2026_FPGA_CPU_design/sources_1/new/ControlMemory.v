module ControlMemory(
    input wire clk,
    input wire [6:0] addr,
    output wire [21:0] micro_instr
);

// 说明：
// 1. 本模块是微程序控制存储器，rom[addr] 的每一位对应一条控制信号 C0~C21。
// 2. 本设计里 C0 没有单独在 rom 中使用，CAR 默认在 CU 中按顺序加 1，
//    因此这里主要显式使用 C1~C21。

// 各控制信号含义如下：
// C1  : CAR<=***      微程序分支，下一微地址由 CU 中 opcode 译码决定
// C2  : CAR<=0        微程序返回到取指入口 rom[0]
// C3  : MBR<=Memory   存储器当前地址单元内容读入 MBR
// C4  : IR<=MBR[15:8] 指令操作码送入 IR
// C5  : MAR<=MBR[7:0] 指令地址字段送入 MAR
// C6  : PC<=PC+1      PC 自增，指向下一条主存指令
// C7  : BR<=MBR       MBR 数据送入 BR
// C9  : ACC<=ACC+BR   ACC 与 BR 相加，结果写回 ACC
// C10 : MAR<=PC       取指时把 PC 指向的地址送入 MAR
// C11 : ACC<=BR       BR 内容直接送入 ACC
// C12 : MBR<=ACC      ACC 内容送入 MBR，供 STORE 写存储器
// C13 : Memory<=MBR   MBR 内容写回当前 MAR 指向的存储器
// C14 : ACC<=ACC-BR   ACC 减 BR，结果写回 ACC
// C15 : PC<=MBR[7:0]  跳转，把 MBR 低 8 位地址送入 PC
// C16 : ACC<=ACC*BR   乘法低 16 位送入 ACC（高 16 位在 ALU 中产生 mul_high）
// C17 : ACC<=ACC&BR   按位与
// C18 : ACC<=ACC|BR   按位或
// C19 : ACC<=~BR      对 BR 按位取反，结果送入 ACC
// C20 : ACC<=BR>>1    BR 逻辑右移 1 位，结果送入 ACC
// C21 : ACC<=BR<<1    BR 逻辑左移 1 位，结果送入 ACC

// 用 22 位 one-hot 常量表示单个控制信号，便于后面按位或组合成微指令
localparam [21:0] C1  = (22'b1 << 1);
localparam [21:0] C2  = (22'b1 << 2);
localparam [21:0] C3  = (22'b1 << 3);
localparam [21:0] C4  = (22'b1 << 4);
localparam [21:0] C5  = (22'b1 << 5);
localparam [21:0] C6  = (22'b1 << 6);
localparam [21:0] C7  = (22'b1 << 7);
localparam [21:0] C9  = (22'b1 << 9);
localparam [21:0] C10 = (22'b1 << 10);
localparam [21:0] C11 = (22'b1 << 11);
localparam [21:0] C12 = (22'b1 << 12);
localparam [21:0] C13 = (22'b1 << 13);
localparam [21:0] C14 = (22'b1 << 14);
localparam [21:0] C15 = (22'b1 << 15);
localparam [21:0] C16 = (22'b1 << 16);
localparam [21:0] C17 = (22'b1 << 17);
localparam [21:0] C18 = (22'b1 << 18);
localparam [21:0] C19 = (22'b1 << 19);
localparam [21:0] C20 = (22'b1 << 20);
localparam [21:0] C21 = (22'b1 << 21);

reg [21:0] rom [0:127];
integer i;

initial begin
    // 缺省全部清零，表示该微地址下不发出任何控制信号
    for (i = 0; i < 128; i = i + 1) begin
        rom[i] = 22'd0;
    end

    // -------------------- 公共取指周期 --------------------
    // rom[0]：MAR<=PC
    // 把 PC 指向的主存地址送到 MAR，准备取下一条机器指令
    rom[0]   = C10;

    // rom[1]：MBR<=Memory
    // 将 MAR 指向的存储器内容读入 MBR
    rom[1]   = C3;

    // rom[2]：IR<=MBR[15:8], MAR<=MBR[7:0], PC<=PC+1
    // 同时完成三件事：
    // 1) 取操作码到 IR
    // 2) 取地址字段到 MAR，供后续执行周期使用
    // 3) PC 加 1，指向下一条机器指令
    rom[2]   = C4 | C5 | C6;

    // rom[3]：CAR<=***
    // 根据 IR 中 opcode 跳到不同指令的执行入口
    rom[3]   = C1;

    // -------------------- LOAD X : opcode = 01 --------------------
    // 入口地址由 CU 指到 rom[10]
    // 目标：ACC<=[X]
    rom[10]  = C3;          // MBR<=Memory    ; 读出地址 X 中的数据
    rom[11]  = C7;          // BR<=MBR        ; 数据送 BR
    rom[12]  = C11 | C2;    // ACC<=BR,CAR<=0 ; BR 送 ACC，然后返回取指

    // -------------------- STORE X : opcode = 02 --------------------
    // 目标：[X]<=ACC
    rom[20]  = C12;         // MBR<=ACC       ; 先把 ACC 数据送入 MBR
    rom[21]  = C13;         // Memory<=MBR    ; 将 MBR 写回地址 X
    rom[22]  = C2;          // CAR<=0         ; 返回取指

    // -------------------- ADD X : opcode = 03 --------------------
    // 目标：ACC<=ACC+[X]
    rom[30]  = C3;          // MBR<=Memory    ; 读出地址 X 中的数据
    rom[31]  = C7;          // BR<=MBR        ; 数据送 BR
    rom[32]  = C9 | C2;     // ACC<=ACC+BR,CAR<=0

    // -------------------- SUB X : opcode = 04 --------------------
    // 目标：ACC<=ACC-[X]
    rom[40]  = C3;          // MBR<=Memory
    rom[41]  = C7;          // BR<=MBR
    rom[42]  = C14 | C2;    // ACC<=ACC-BR,CAR<=0

    // -------------------- JMPGEZ X : opcode = 05 --------------------
    // 在 CU 中判断 acc[15]：
    // 若 ACC>=0，则 rom[3] 跳到 rom[50]
    // 若 ACC<0，则 rom[3] 直接回 rom[0]，等价于不跳转
    rom[50]  = C15 | C2;    // PC<=MBR[7:0],CAR<=0 ; 条件满足时执行跳转

    // -------------------- JMP X : opcode = 06 --------------------
    // 无条件跳转
    rom[60]  = C15 | C2;    // PC<=MBR[7:0],CAR<=0

    // -------------------- HALT : opcode = 07 --------------------
    // 本设计中真正的停机由顶层 CpuTop 中 halt_flag=1 后停止 cpu_run 来实现，
    // 这里微程序本身只需回到 rom[0]，不会继续推进 CAR。
    rom[70]  = C2;          // CAR<=0

    // -------------------- MUL X : opcode = 08 --------------------
    // 目标：ACC<=ACC*[X] 的低 16 位
    rom[80]  = C3;          // MBR<=Memory
    rom[81]  = C7;          // BR<=MBR
    rom[82]  = C16 | C2;    // ACC<=ACC*BR,CAR<=0

    // -------------------- AND X : opcode = 0A --------------------
    rom[90]  = C3;          // MBR<=Memory
    rom[91]  = C7;          // BR<=MBR
    rom[92]  = C17 | C2;    // ACC<=ACC&BR,CAR<=0

    // -------------------- OR X : opcode = 0B --------------------
    rom[100] = C3;          // MBR<=Memory
    rom[101] = C7;          // BR<=MBR
    rom[102] = C18 | C2;    // ACC<=ACC|BR,CAR<=0

    // -------------------- NOT X : opcode = 0C --------------------
    // 注意：按你的指令定义，NOT X 是对 [X] 取反，不是对 ACC 取反
    rom[110] = C3;          // MBR<=Memory
    rom[111] = C7;          // BR<=MBR
    rom[112] = C19 | C2;    // ACC<=~BR,CAR<=0

    // -------------------- SHIFTR X : opcode = 0D --------------------
    // 注意：按你的指令定义，是对 [X] 逻辑右移 1 位，不是对 ACC 右移
    rom[120] = C3;          // MBR<=Memory
    rom[121] = C7;          // BR<=MBR
    rom[122] = C20 | C2;    // ACC<=BR>>1,CAR<=0

    // -------------------- SHIFTL X : opcode = 0E --------------------
    // 注意：按你的指令定义，是对 [X] 逻辑左移 1 位，不是对 ACC 左移
    rom[125] = C3;          // MBR<=Memory
    rom[126] = C7;          // BR<=MBR
    rom[127] = C21 | C2;    // ACC<=BR<<1,CAR<=0
end

assign micro_instr = rom[addr];

endmodule
