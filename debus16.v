module debus16(
	A15,
	A14,
	A13,
	A12,
	A11,
	A10,
	A9,
	A8,
	A7,
	A6,
	A5,
	A4,
	A3,
	A2,
	A1,
	A0,
	B
);


input wire A15;
input wire A14;
input wire A13;
input wire A12;
input wire A11;
input wire A10;
input wire A9;
input wire A8;
input wire A7;
input wire A6;
input wire A5;
input wire A4;
input wire A3;
input wire A2;
input wire A1;
input wire A0;
output wire	[15:0] B;

assign	B[15] = A15;
assign	B[14] = A14;
assign	B[13] = A13;
assign	B[12] = A12;
assign	B[11] = A11;
assign	B[10] = A10;
assign	B[9] = A9;
assign	B[8] = A8;
assign	B[7] = A7;
assign	B[6] = A6;
assign	B[5] = A5;
assign	B[4] = A4;
assign	B[3] = A3;
assign	B[2] = A2;
assign	B[1] = A1;
assign	B[0] = A0;

endmodule
