module Digitalclock(
    input clkin,
    input rst,
    input lock,
    input blink,
    input inc,
    input dec,
	 output reg [2:0] led,
    output reg [6:0] H1,
    output reg [6:0] H0,
    output reg [6:0] M1,
    output reg [6:0] M0,
    output reg [6:0] S1,
    output reg [6:0] S0,
	 //To off the unused 7-seg displays
	 output reg [6:0]  u1,
	 output reg [6:0]  u2
);

    reg clk;
    reg [5:0] hrs;
    reg [5:0] min;
    reg [5:0] sec;

    wire [5:0] secnext;
    wire [5:0] minnext;
    wire [5:0] hrsnext;
    parameter [5:0] FN = 59;
    parameter [5:0] TT = 23;

    parameter [1:0] NO = 2'b00;
    parameter [1:0] SB = 2'b01;
    parameter [1:0] MB = 2'b10;
    parameter [1:0] HB = 2'b11;
    reg [1:0] state;
	 
	 
	 //   STATE
    always @(posedge clk or posedge rst) begin
        if (rst) state <= NO;
        else case (state)
            NO: state <= lock ? SB : NO;
            HB: if (blink) state <= SB;
                else state <= lock ? NO : HB;
            MB: case (blink)
                    1: state <= HB;
                    0: state <= lock ? NO : MB;
                endcase
            SB: case (1)
                    blink: state <= MB;
                    lock: state <= NO;
                    default: state <= SB;
                endcase
        endcase
    end

	 
	 // Increment the value with CAUTION
	 assign secnext = (sec == FN) ? 0 : sec + 1;
    assign minnext = (min == FN) ? 0 : min + 1;
    assign hrsnext = (hrs == TT) ? 0 : hrs + 1;
	 
	 
	 //   SECOUNDS
    always @(posedge clk or posedge rst) begin
        if (rst) sec <= 0;
        else case (state)
            NO: if (lock) sec <= sec;
                else sec <= secnext;
            HB: if (lock) sec <= secnext;
                else sec <= sec;
            MB: if (lock) sec <= secnext;
                else sec <= sec;
            SB: if (lock) sec <= secnext;
                else
					 begin
					 case ({inc, dec})
                    2'b10: sec <= secnext;
                    2'b01: sec <= (sec == 0) ? FN : (sec - 1);
                    2'b00, 2'b11: sec <= sec;
                endcase
					 end
        endcase
    end

	 //   MINUTES
    always @(posedge clk or posedge rst) begin
        if (rst) min <= 0;
        else case (state)
            MB: if (lock) min <= sec == FN ? minnext : min;
                else
					 begin
					 case ({inc, dec})
                    2'b10: min <= minnext;
                    2'b01: min <= (min == 0) ? FN : (min - 1);
                    2'b00, 2'b11: min <= min;
                endcase
					 end
            NO: if (sec == FN) min <= minnext;
                else min <= min;
            HB: if (lock) min <= sec == FN ? minnext : min;
                else min <= min;
            SB: if (lock) begin
                    if (sec == FN) min <= minnext;
                    else min <= min;
                end
                else min <= min;
        endcase
    end

	 
	 //    HOURS
    always @(posedge clk or posedge rst) begin
        if (rst) hrs <= 0;
        else case (state)
            NO: if ({sec, min} == {FN, FN}) hrs <= hrs == TT ? 0 : hrs + 1;
                else hrs <= hrs;
            MB: if (lock) hrs <= ({sec, min} == {FN, FN}) ? hrsnext : hrs;
                else hrs <= hrs;
            SB: if (lock) begin
                    if ({min, sec} == {FN, FN}) hrs <= hrsnext;
                    else hrs <= hrs;
                end
                else hrs <= hrs;
            HB: if (lock) hrs <= {sec, min} == {FN, FN} ? hrsnext : hrs;
                else 
					 begin
					 case ({inc, dec})
                    2'b10: hrs <= hrsnext;
                    2'b01: hrs <= (hrs == 0) ? TT : (hrs - 1);
                    2'b00, 2'b11: hrs <= hrs;
                endcase
					 end
        endcase
    end
	 
	 
	 
	 //LED to know which segment is getting edit(hrs,min or sec)
	 
	 always@(posedge clk or posedge rst)
	 begin
		if (rst)  led<=3'b000;
		else case (state)
		NO:led<=3'b000;
		SB:if(lock)
		   led<=3'b000;
			else
			led<=3'b001;
		MB:if(lock)
		   led<=3'b000;
			else
			led<=3'b010;
		HB:if(lock)
		   led<=3'b000;
			else
			led<=3'b100;
		endcase
	 end
	 
	 
	 
	 
	 // 7-segment display 
	 
    wire [6:0] H1_wire;
    wire [6:0] H0_wire;
    wire [6:0] M1_wire;
    wire [6:0] M0_wire;
    wire [6:0] S1_wire;
    wire [6:0] S0_wire;

    hex_7seg h(hrs, H1_wire, H0_wire);
    hex_7seg m(min, M1_wire, M0_wire);
    hex_7seg s(sec, S1_wire, S0_wire);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            H1 <= 7'b1111111;
            H0 <= 7'b1111111;
            M1 <= 7'b1111111;
            M0 <= 7'b1111111;
            S1 <= 7'b1111111;
            S0 <= 7'b1111111;
				u1 <= 7'b1111111;
            u2 <= 7'b1111111;
        end else begin
            H1 <= H1_wire;
            H0 <= H0_wire;
            M1 <= M1_wire;
            M0 <= M0_wire;
            S1 <= S1_wire;
            S0 <= S0_wire;
				u1 <= 7'b1111111;
            u2 <= 7'b1111111;
        end
    end
	 
	 
	 
	 
	 // clock converstion (from 50MHz to 1Hz)
	 
	 reg [24:0] counter;
    initial begin
    counter = 0;
    clk = 0;
     end
    always @(posedge clkin) begin
    if (counter == 0) begin
        counter <= 24999999;
        clk <= ~clk;
    end else begin
        counter <= counter -1;
    end
end



endmodule
