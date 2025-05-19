module Datapath (
    input  wire        clk,
    output wire [31:0] Inst,
    output wire [31:0] PCOut
);
    
    wire [31:0] PCIn, PCNext;

    //Division de instruccion
    wire [5:0]  OpCode, Function;
    wire [4:0]  RS, RT, RD;

    //Unidad de Control
    wire RegDst, Branch, MemRead, MemtoReg, MemWrite, RegWrite, ALUSrc, ZF, BrAndZF, Jump;
    wire [2:0]  ALUOp;

    wire [31:0] DataReg1, DataReg2, ALURes, ReadMem, WriteData, B, SignExtended, Extendedx4, BranchRes, JumpAddr;
    wire [25:0] JumpInst;
    wire [3:0]  OpAlu;
    wire [4:0]  WriteReg;

    // Buffers
    wire [63:0] BufferIn1, BufferOut1;
    wire [186:0] BufferIn2, BufferOut2;
    wire [171:0] BufferIn3, BufferOut3;
    wire [70:0] BufferIn4, BufferOut4;

    // Señales de los buffers
    // Buffer 1
    wire [31:0] InstB1, PCNextB1;

    // Buffer 2
    wire RegDstB2, BranchB2, MemReadB2, MemtoRegB2, MemWriteB2, RegWriteB2, ALUSrcB2, JumpB2;
    wire [4:0] RTB2, RDB2;
    wire [5:0] FunctionB2;
    wire [2:0] ALUOpB2;
    wire [31:0] DataReg1B2, DataReg2B2, SignExtendedB2, PCNextB2, JumpAddrB2;

    // Buffer 3
    wire [31:0] PCNextB3;
    wire [4:0] WriteRegB3;
    wire [31:0] ALUResB3, BranchResB3, DataReg2B3, JumpAddrB3;
    wire  BranchB3, MemReadB3, MemtoRegB3, MemWriteB3, RegWriteB3, ZFB3, JumpB3;

    // Buffer 4
    wire [31:0]  ALUResB4, ReadMemB4;
    wire MemtoRegB4, RegWriteB4;
    wire [4:0] WriteRegB4;

    // PC
    PC Pc1 (
        .data_in(PCIn),
        .clk(clk),
        .data_out(PCOut)
    );

    // Suma PC + 4
    SUM SumPC (
        .data_in(PCOut),
        .data_out(PCNext)
    );

    // Memoria de instrucciones
    MemoriaInst MemI (
        .Dir(PCOut),
        .Inst(Inst)
    );

    // Buffer 1
    assign BufferIn1 = {Inst, PCNext};

    BufferParam #(64) Buffer1 (
        .DataIn(BufferIn1),
        .CLK(clk),
        .DataOut(BufferOut1)
    );

    assign InstB1   = BufferOut1[63:32];
    assign PCNextB1 = BufferOut1[31:0];

    assign JumpInst = InstB1[25:0];
    assign JumpAddr = {PCNextB1[31:28], JumpInst, 2'b00};

    assign OpCode   = InstB1[31:26];
    assign RS       = InstB1[25:21];
    assign RT       = InstB1[20:16];
    assign RD       = InstB1[15:11];
    assign Function = InstB1[5:0];

    // Unidad de Control
    UniCtrl UniControl (
        .Op(OpCode),
        .RegDst(RegDst),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemToReg(MemtoReg),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .Jump(Jump)
    );

    // Banco de registros
    BancoReg BR (
        .clk(clk),
        .RegEn(RegWriteB4),
        .Reg1(RS),
        .Reg2(RT),
        .WriteAddr(WriteRegB4),
        .Data(WriteData),
        .DataReg1(DataReg1),
        .DataReg2(DataReg2)
    );

    // Extensor de signo
    Extensor SignExt (
        .dataIN(InstB1[15:0]),
        .dataOUT(SignExtended)
    );

    // Buffer 2 (ID/EX)
    assign BufferIn2 = {RegDst, Branch, MemRead, MemtoReg, MemWrite, RegWrite, ALUSrc, Jump, ALUOp,
                        DataReg1, DataReg2, SignExtended, RT, RD, PCNextB1, Function, JumpAddr};

    BufferParam #(187) Buffer2 (
        .DataIn(BufferIn2),
        .CLK(clk),
        .DataOut(BufferOut2)
    );

    assign RegDstB2       = BufferOut2[186];
    assign BranchB2       = BufferOut2[185];
    assign MemReadB2      = BufferOut2[184];
    assign MemtoRegB2     = BufferOut2[183];
    assign MemWriteB2     = BufferOut2[182];
    assign RegWriteB2     = BufferOut2[181];
    assign ALUSrcB2       = BufferOut2[180];
    assign JumpB2         = BufferOut2[179];
    assign ALUOpB2        = BufferOut2[178:176];

    assign DataReg1B2     = BufferOut2[175:144];
    assign DataReg2B2     = BufferOut2[143:112];
    assign SignExtendedB2 = BufferOut2[111:80];

    assign RTB2           = BufferOut2[79:75];
    assign RDB2           = BufferOut2[74:70];

    assign PCNextB2       = BufferOut2[69:38];
    assign FunctionB2     = BufferOut2[37:32];
    assign JumpAddrB2     = BufferOut2[31:0];

    // Multiplexor para WriteReg
    Mux5b Mux2 (
        .rt(RTB2),
        .rd(RDB2),
        .RegDst(RegDstB2),
        .DataOut(WriteReg)
    );

    // ALU Control
    ALUCtrl AluControl (
        .AluOp(ALUOpB2),
        .Function(FunctionB2),
        .OpAlu(OpAlu)
    );

    // Multiplexor para segundo operando de la ALU
    Mux32b Mux3 (
        .Data0(DataReg2B2),
        .Data1(SignExtendedB2),
        .En(ALUSrcB2),
        .DataOut(B)
    );

    // ALU
    Alu Alu (
        .A(DataReg1B2),
        .B(B),
        .OP(OpAlu),
        .Res(ALURes),
        .zero(ZF)
    );

    // Shift left 2
    ShiftLeft2 ShiftLeft (
        .DataIn(SignExtendedB2),
        .DataOut(Extendedx4)
    );

    // Sumador para Branch
    ALUBranch AluB (
        .data1(PCNextB2),
        .data2(Extendedx4),
        .data_out(BranchRes)
    );

    // Buffer 3 (EX/MEM)
    assign BufferIn3 = {PCNextB2, WriteReg, ALURes, ZF, BranchRes, MemReadB2, MemWriteB2,
                        MemtoRegB2, RegWriteB2, DataReg2B2, BranchB2, JumpAddrB2, JumpB2};

    BufferParam #(172) Buffer3 (
        .DataIn(BufferIn3),
        .CLK(clk),
        .DataOut(BufferOut3)
    );

    assign PCNextB3     = BufferOut3[171:140];
    assign WriteRegB3   = BufferOut3[139:135];
    assign ALUResB3     = BufferOut3[134:103];
    assign ZFB3         = BufferOut3[102];
    assign BranchResB3  = BufferOut3[101:70];
    assign MemReadB3    = BufferOut3[69];
    assign MemWriteB3   = BufferOut3[68];
    assign MemtoRegB3   = BufferOut3[67];
    assign RegWriteB3   = BufferOut3[66];
    assign DataReg2B3   = BufferOut3[65:34];
    assign BranchB3     = BufferOut3[33];
    assign JumpAddrB3   = BufferOut3[31:0];
    assign JumpB3       = BufferOut3[32];

    // Señal de branch efectiva (and)
    assign BrAndZF = ZFB3 & BranchB3;

    // Mux para branch o PCNext
    wire [31:0] PCBranchOrNext;
    Mux32b MuxBranch (
        .Data0(PCNextB3),
        .Data1(BranchResB3),
        .En(BrAndZF),
        .DataOut(PCBranchOrNext)
    );

    // Mux para salto
    Mux32b MuxJump (
        .Data0(PCBranchOrNext),
        .Data1(JumpAddrB3),
        .En(JumpB3),
        .DataOut(PCIn)
    );

    // Memoria de datos
    MemDatos MemoriaDatos (
        .clk(clk),
        .Addr(ALUResB3),
        .Data(DataReg2B3),
        .MemWrite(MemWriteB3),
        .MemRead(MemReadB3),
        .ReadMemData(ReadMem)
    );

    // Buffer 4 (MEM/WB)
    assign BufferIn4 = {ReadMem, MemtoRegB3, RegWriteB3, WriteRegB3, ALUResB3};

    BufferParam #(71) Buffer4 (
        .DataIn(BufferIn4),
        .CLK(clk),
        .DataOut(BufferOut4)
    );

    assign ReadMemB4   = BufferOut4[70:39];
    assign MemtoRegB4  = BufferOut4[38];
    assign RegWriteB4  = BufferOut4[37];
    assign WriteRegB4  = BufferOut4[36:32];
    assign ALUResB4    = BufferOut4[31:0];

    // Multiplexor para WriteData al banco de registros
    Mux32b Mux4 (
        .Data0(ALUResB4),
        .Data1(ReadMemB4),
        .En(MemtoRegB4),
        .DataOut(WriteData)
    );

endmodule
