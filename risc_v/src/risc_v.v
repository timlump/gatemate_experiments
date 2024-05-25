module risc_v (
    input CLK,
    input RESET,
    output LED,
    input RXD,
    output TXD
);

reg [4:0] count = 0;
always @(posedge CLK) begin
    count <= count + 1;
end

assign LED = ~count[4];  // ~ to invert the data
assign TXD = 1'b0;      // not used for now

endmodule