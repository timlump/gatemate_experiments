module risc_v (
    input CLK,
    output LED
);

    wire clk;    // internal clock

    reg count = 0;
    always @(posedge clk) begin
        count <= count + 1;
    end

    assign LED = count;

    Clockworks #(
        .SLOW(21) // divide clock frequency by 2^21
    )CW(
        .CLK(CLK),
        .clk(clk)
    );

endmodule