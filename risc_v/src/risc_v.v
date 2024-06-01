module risc_v (
    input CLK,
    output LED
);

    reg [4:0] PC = 0;
    reg [4:0] MEM[0:4095]; // memory size is so large to trigger allocation of 40K embedded blocks
    initial begin
        MEM[0]  = 5'b00000;
        MEM[1]  = 5'b00001;
        MEM[2]  = 5'b00010;
        MEM[3]  = 5'b00100;
        MEM[4]  = 5'b01000;
        MEM[5]  = 5'b10000;
        MEM[6]  = 5'b10001;
        MEM[7]  = 5'b10010;
        MEM[8]  = 5'b10100;
        MEM[9]  = 5'b11000;
        MEM[10] = 5'b11001;
        MEM[11] = 5'b11010;
        MEM[12] = 5'b11100;
        MEM[13] = 5'b11101;
        MEM[14] = 5'b11110;
        MEM[15] = 5'b11111;
        MEM[16] = 5'b11110;
        MEM[17] = 5'b11100;
        MEM[18] = 5'b11000;
        MEM[19] = 5'b10000;
        MEM[20] = 5'b00000;
    end

    wire clk;    // internal clock

    always @(posedge clk) begin
        LED <= MEM[PC][4];
        PC <= (PC == 20) ? 0 : (PC+1);
    end

    assign LED = count;

    Clockworks #(
        .SLOW(21) // divide clock frequency by 2^21
    )CW(
        .CLK(CLK),
        .clk(clk)
    );

endmodule