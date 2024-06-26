module risc_v (
    input CLK,
    output LED
);

    reg [31:0] PC = 0;
    reg [31:0] MEM[0:4095]; // memory size is large to trigger allocation of 40K embedded blocks
    reg [31:0] instr;

    // pg 130 of RISC-V ISA Manual
    wire isALUreg = (instr[6:0] == 7'b0110011);
    wire isALUimm = (instr[6:0] == 7'b0010011);

    wire isBranch = (instr[6:0] == 7'b1100011);
    wire isJALR   = (instr[6:0] == 7'b1100111);
    wire isJAL    = (instr[6:0] == 7'b1101111);

    wire isAUIPC  = (instr[6:0] == 7'b0010111);
    wire isLUI    = (instr[6:0] == 7'b0110111);
    
    wire isLoad   = (instr[6:0] == 7'b0000011);
    wire isStore  = (instr[6:0] == 7'b0100011);

    wire isSYSTEM = (instr[6:0] == 7'b1110011);

    // R-type format
    // 31      25     20    15      12    6        0
    // | funct7 | rs2 | rs1 | funct3 | rd | opcode |
    wire [4:0] rs1Id = instr[19:15];
    wire [4:0] rs2Id = instr[24:20];
    wire [4:0] rdId  = instr[11:7]; 

    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    // I-type format
    // 31          20   15        12   6        0 
    // | imm[11:0] | rs1 | funct3 | rd | opcode |
    wire [31:0] Iimm = {{21{instr[31]}}, instr[30:20]}; // the first part is performing sign expansion

    // S-type format
    // 31          25   20    15        12         6        0
    // | imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode |
    wire [31:0] Simm = {{21{instr[31]}}, instr[30:25], instr[11:7]};

    // B-type format
    // 31             25    20   15       12             6        0
    // | imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode |
    wire [31:0] Bimm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

    // U-type format
    // 31           12   6        0
    // | imm[31:12] | rd | opcode |
    wire [31:0] Uimm = {instr[31], instr[30:12], {12{1'b0}}};

    // J-type format
    // 31                      12   6        0
    // | imm[20|10:1|11|19:12] | rd | opcode |
    wire [31:0] Jimm={{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
    
    wire clk;    // internal clock

    `include "../riscv_assembly.v"
    integer L0_=8;
    initial begin
            ADD(x1,x0,x0);
            ADDI(x2,x0,32);
        Label(L0_); 
            ADDI(x1,x1,1); 
            BNE(x1, x2, LabelRef(L0_));
            EBREAK();
            endASM();
    end

    reg [31:0] RegisterBank [0:31];
    `ifdef BENCH   
        integer     i;
        initial begin
            for(i=0; i<32; ++i) begin
            RegisterBank[i] = 0;
            end
        end
    `endif  

    wire [31:0] writeBackData;
    wire writeBackEn;
    reg [31:0] rs1;
    reg [31:0] rs2;

    // state machine to control the cpu pipeline
    localparam FETCH_INSTR = 0;
    localparam FETCH_REGS  = 1;
    localparam EXECUTE     = 2;
    reg [1:0] state = FETCH_INSTR;

    assign writeBackData = (isJAL || isJALR) ? (PC+4) :
                           (isLUI) ? Uimm :
                           (isAUIPC) ? (PC + Uimm) :
                           aluOut;
    assign writeBackEn = (state == EXECUTE && 
        (isALUreg ||
         isALUimm ||
         isJAL    ||
         isJALR   ||
         isLUI    ||
         isAUIPC)
        );

    // ALU code
    wire [31:0] aluIn1 = rs1;
    wire [31:0] aluIn2 = isALUreg ? rs2 : Iimm;
    reg [31:0] aluOut;
    wire [4:0] shamt = isALUreg ? rs2[4:0] : instr[24:20]; // shift amount
    always @(*) begin
        case (funct3)
            3'b000: aluOut = (funct7[5] & instr[5]) ? (aluIn1-aluIn2) : (aluIn1+aluIn2);
            3'b001: aluOut = aluIn1 << shamt;
            3'b010: aluOut = ($signed(aluIn1) < $signed(aluIn2));
            3'b011: aluOut = (aluIn1 < aluIn2);
            3'b100: aluOut = (aluIn1 ^ aluIn2);
            3'b101: aluOut = funct7[5]? ($signed(aluIn1) >>> shamt) : (aluIn1 >> shamt);
            3'b110: aluOut = (aluIn1 | aluIn2);
            3'b111: aluOut = (aluIn1 & aluIn2);
        endcase
    end

    // brancing code
    reg takeBranch;
    always @(*) begin
        case(funct3)
            3'b000: takeBranch = (rs1 == rs2);
            3'b001: takeBranch = (rs1 != rs2);
            3'b100: takeBranch = ($signed(rs1) < $signed(rs2));
            3'b101: takeBranch = ($signed(rs1) >= $signed(rs2));
            3'b110: takeBranch = (rs1 < rs2);
            3'b110: takeBranch = (rs1 >= rs2);
            default: takeBranch = 1'b0;
        endcase
    end

    wire[31:0] nextPC = (isBranch && takeBranch) ? PC+Bimm :
                        isJAL ? PC+Jimm :
                        isJALR ? rs1+Iimm : 
                        PC + 4;

    always @(posedge clk) begin
        if (writeBackEn && rdId != 0) begin // register 0 can never be written to in risc-v
            `ifdef BENCH
                $display("Write Back");
            `endif
            RegisterBank[rdId] <= writeBackData;
        end

        case(state)
            FETCH_INSTR: begin
                // ignore the 2 least significant bits as instructions are word aligned
                instr <= MEM[PC[31:2]];
                state <= FETCH_REGS;
            end
            FETCH_REGS: begin
                rs1 <= RegisterBank[rs1Id];
                rs2 <= RegisterBank[rs2Id];
                state <= EXECUTE;
            end
            EXECUTE: begin
                PC <= nextPC;
                state <= FETCH_INSTR;
            end
        endcase
    end

    `ifdef BENCH   
        always @(posedge clk) begin
            $display("PC=%0d",PC);
             $display("x1=%0d",RegisterBank[1]);
            case (1'b1)
                isALUreg: $display("ALUreg rd=%d rs1=%d rs2=%d funct3=%b",rdId, rs1Id, rs2Id, funct3);
                isALUimm: $display("ALUimm rd=%d rs1=%d imm=%0d funct3=%b",rdId, rs1Id, Iimm, funct3);
                isBranch: $display("BRANCH");
                isJAL:    $display("JAL");
                isJALR:   $display("JALR");
                isAUIPC:  $display("AUIPC");
                isLUI:    $display("LUI");	
                isLoad:   $display("LOAD");
                isStore:  $display("STORE");
                isSYSTEM: $display("SYSTEM");
            endcase 
        end
    `endif

    assign LED = state[0];

    Clockworks #(
        .SLOW(21) // divide clock frequency by 2^21
    )CW(
        .CLK(CLK),
        .clk(clk)
    );

endmodule