module bench();
    reg CLK;
    wire LED;

    risc_v uut (
        .CLK(CLK),
        .LED(LED)
    );

    reg prev_LED = 0;
    initial begin
        CLK = 0;
        forever begin
            #1 CLK = ~CLK;
            if (LED != prev_LED) begin
                //$display("LED = %b", LED);
            end
            prev_LED <= LED;
        end
    end

endmodule