module interrupt_control (
   RI_in,
   int_en,
   int_val,
   clock,
   reset,
   RI_out,
   clock_en
);

input wire [15:0] RI_in;
input wire int_en;
input wire [3:0] int_val;
input wire clock;
input wire reset;
output wire [15:0] RI_out;
//output wire clock_en;
output reg clock_en;

reg [15:0] RI = 0;
reg [1:0] state = 0;

//assign clock_en = state == 0 ? 1'b1 : 1'b0;
assign RI_out = clock_en ? RI_in : RI;

always @(posedge clock or posedge reset) begin


   if (reset) begin
      //RI_out <= 0;
      clock_en <= 0;
      state <= 0;
   end

   else begin
      //RI_out <= RI_in;
      clock_en <= 1'b1;
      /*
      case (state)
         // execute current instruction
         0: if (int_en == 1) begin
               state <= 1;
            end
         1: begin
               state <= 2;
               clock_en <= 0;
            end
         2: begin
               state <= 3;
               RI_out <= {12'b010001110000, int_val}; // inject int instruction
            end
         3: begin
               state <= 0;
               RI_out <= 0; // inject nop
            end
      endcase
      */
   end
end

endmodule