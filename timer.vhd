---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : timer.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Generates a flag after a certain period.
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity timer is
   generic (CLOCK_FREQUENCY_HZ: integer := 50000000);
   port (
      -- Inputs
      data         : in  std_logic_vector(15 downto 0); -- Duration/State Value to be set
      state_set    : in  std_logic;                     -- Set state
      duration_set : in  std_logic;                     -- Set duration
      clock        : in  std_logic;                     -- System Clock
      reset        : in  std_logic;                     -- Reset
      -- Outputs
      int          : out std_logic := '0';              -- Flag activated when the timer ends
      state        : out std_logic := '0';              -- Current timer state
      count        : out std_logic_vector(15 downto 0)  -- Current timer count
   );
end timer;

architecture Architecture_1 of timer is
	signal clock_count : std_logic_vector(27 downto 0);
begin

	process (clock, reset) begin
		if reset = '1' then
         int         <= '0';
         state       <= '0';
         count       <= (others => '0');
         clock_count <= (others => '0');
		elsif rising_edge(clock) then
      
         -- Default values
         int <= '0';
         
         -- Start or stop the timer
         if state_set = '1' then 
            state       <= data(0);
            clock_count <= (others => '0');
         end if;
         
         -- Set timer duration
         if duration_set = '1' then
            count <= data; 
         end if;
         
         -- Enable interrupt
         if state = '1' and count = 0 then
            int   <= '1'; 
            state <= '0';
         end if;
         
         -- Count 100 ms
         if clock_count = CLOCK_FREQUENCY_HZ / 10 - 1 then
            count       <= count - 1;
            clock_count <= (others => '0');
         else
            clock_count <= clock_count + 1;
         end if;
         
      end if;
   end process;

end Architecture_1;