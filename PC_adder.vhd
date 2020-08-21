---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : PC_addder.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Adds the 8 least significant bits of RI to PC.
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC_adder is
   port (
      -- Inputs
      PC   : in  std_logic_vector(15 downto 0); -- Program Counter
      RI   : in  std_logic_vector(15 downto 0); -- Instruction Register
      -- Outputs
      addr : out std_logic_vector(15 downto 0)  -- New value for PC
   );
end PC_adder;

architecture Architecture_1 of PC_adder is
begin
   addr <= std_logic_vector(signed(PC) + signed(RI(7 downto 0)));
end Architecture_1;