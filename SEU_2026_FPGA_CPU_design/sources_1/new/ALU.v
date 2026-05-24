module ALU(

    input wire [15:0] acc,
    input wire [15:0] br,

    input wire c9,
    input wire c14,
    input wire c16,
    input wire c17,
    input wire c18,
    input wire c19,
    input wire c20,
    input wire c21,

    output reg [15:0] result,
    output reg [15:0] mul_high

);

// 乘法内部使用 32 位临时变量，低 16 位送 ACC，高 16 位可送 MR。
// 当前代码中的 reg/wire 都没有声明为 signed，因此 Verilog 会按无符号向量参与表达式运算。
// 但由于本机采用二进制补码保存数据，加/减运算的硬件结果与有符号加减的位级结果一致：
// 例如 16'hFFFF + 16'h0001 = 16'h0000。
// 需要注意的是，乘法 c16 在当前实现下是“无符号乘法”语义；
// 如果后续希望支持有符号乘法，应改为 $signed(acc) * $signed(br)。
reg [31:0] mul_temp;

always @(*)
begin

    result = acc;
    mul_high = 16'd0;

    // C9 : ADD
    // 16 位加法，结果仅保留低 16 位，不单独输出进位/溢出标志。
    // 从位级结果看，它既可用于无符号加法，也与补码有符号加法的低 16 位结果一致。
    if(c9)
        result = acc + br;

    // C14 : SUB
    // 16 位减法，结果仅保留低 16 位，不单独输出借位/溢出标志。
    // 与补码有符号减法的低 16 位结果一致。
    else if(c14)
        result = acc - br;

    // C16 : MUL
    // 当前为 16x16 无符号乘法：
    // result   = 积的低 16 位，对应 ACC
    // mul_high = 积的高 16 位，对应 MR
    // 若 acc/br 中存放负数补码，本实现不会按“有符号乘法”解释它们。
    else if(c16)
    begin
        mul_temp = acc * br;
        result = mul_temp[15:0];
        mul_high = mul_temp[31:16];
    end

    // C17 : AND
    // 按位与，纯逻辑运算，无有符号/无符号区别。
    else if(c17)
        result = acc & br;

    // C18 : OR
    // 按位或，纯逻辑运算，无有符号/无符号区别。
    else if(c18)
        result = acc | br;

    // C19 : NOT
    // 对 BR 逐位取反，纯逻辑运算，无有符号/无符号区别。
    else if(c19)
        result = ~br;

    // C20 : SHIFTR
    // 逻辑右移 1 位，高位补 0，不保留符号位。
    // 因此这不是算术右移；若 BR 表示负数补码，移位后不会保持负号。
    else if(c20)
        result = br >> 1;

    // C21 : SHIFTL
    // 逻辑左移 1 位，低位补 0，高位移出后丢弃。
    // 左移本身不区分有符号/无符号，但本实现也不检测溢出。
    else if(c21)
        result = br << 1;

end

endmodule
