---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : PC.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2019.03.14
---------------------------------------------------------------------------------------------------
-- Description: Up counter.
--
-- The counter starts at 1 and increments by 1 every clock cycle when cnt_en is active.
-- When reset is active, output is 0.
-- When Ld is active, output is data.
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC is
   port (
      -- Inputs
      Ld     : in  std_logic;                     -- Load
      data   : in  std_logic_vector(15 downto 0); -- Value to load
      clock  : in  std_logic;                     -- System Clock
      reset  : in  std_logic;                     -- Reset
      cnt_en : in  std_logic;                     -- Count Enable
      -- Outputs
      PC     : out std_logic_vector(15 downto 0)  -- Program Counter
   );
end PC;

architecture Architecture_1 of PC is
   signal count : std_logic_vector(15 downto 0); -- Counter
begin

   PC <= (others => '0') when reset = '1' else data when Ld = '1' else std_logic_vector(unsigned(count) + 1);
   
   process (clock) begin
      if rising_edge(clock) then
         if cnt_en = '1' then count <= PC; end if;
      end if;
   end process;

end Architecture_1;