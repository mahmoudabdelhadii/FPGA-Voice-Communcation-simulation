module fast_to_slow_sync (fast_clk, slow_clk, d, q);
	parameter N = 12;
	input fast_clk, slow_clk;
	input [N-1:0] d;
	output logic [N-1:0] q;

	logic [N-1:0] q1, q2, q3, E;

	always_ff @ (posedge  fast_clk) begin
		q1 <= d;
	end
	
	always_ff @ (posedge fast_clk) begin
		if (E) q2 <= q1;
	end

	always_ff @ (posedge slow_clk) begin
		q <= q2;
	end

	always_ff @ (posedge ~fast_clk) begin
		q3 <= slow_clk;
		E <= q3;
	end
endmodule
	

