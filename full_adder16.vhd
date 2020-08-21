---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : full_adder16.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Add two 16 bit inputs with carry in, carry out and overflow flag.
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity full_adder16 is
   port (
      -- Inputs
      A    : in  std_logic_vector(15 downto 0); -- Operand
      B    : in  std_logic_vector(15 downto 0); -- Operand
      Cin  : in  std_logic;                     -- Carry In
      -- Outputs
      S    : out std_logic_vector(15 downto 0); -- Sum
      Cout : out std_logic;                     -- Carry out
      O    : out std_logic                      -- Overflow
   );
end full_adder16;

architecture Architecture_1 of full_adder16 is
begin

   process(A, B, Cin)
      variable SL : std_logic_vector(15 downto 0);
      variable SH : std_logic_vector(1 downto 0);
   begin
      SL := ("0" & A(14 downto 0)) + B(14 downto 0) + Cin;
      SH(0) := A(15) xor B(15) xor SL(15);
      SH(1) := (A(15) and B(15)) or (SL(15) and (A(15) xor B(15)));
      
      Cout <= SH(1);
      O    <= SH(1) xor SL(15);
      S    <= SH(0) & SL(14 downto 0);
   end process;

end Architecture_1;