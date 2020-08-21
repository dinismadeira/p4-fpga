module bus16_bus4(
	A,
	B,
	C,
	D,
	E
);


input wire	[15:0] A;
output wire	[3:0] B;
output wire	[3:0] C;
output wire	[3:0] D;
output wire	[3:0] E;

assign	B[3:0] = A[15:12];
assign	C[3:0] = A[11:8];
assign	D[3:0] = A[7:4];
assign	E[3:0] = A[3:0];

endmodule
