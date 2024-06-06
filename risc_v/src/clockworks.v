module Clockworks
(
    input CLK,    // clock pin of the board
    output clk
);

    parameter SLOW = 0;

    reg [SLOW:0] slow_CLK = 0;
    always @(posedge CLK) begin
        slow_CLK <= slow_CLK + 1;
    end
    assign clk = slow_CLK[SLOW];

endmodule