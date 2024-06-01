module risc_v (
    input clk,
    output led
);

reg [26:0] count = 0;
always @(posedge clk) begin
    count <= count + 1;
end

assign led = count[26];

endmodule