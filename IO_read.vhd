---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : IO_read.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Multiplexes IO readings. 
--
-- Outputs the corresponding input source based on the address.
-- The terminal_test output becomes 1 when a character is typed on the keyboard, 
-- and is set to 0 when this value is read.
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity IO_read is
   port (
      -- Inputs
      terminal_read     : in  std_logic_vector(15 downto 0); -- ASCII of last the character typed on keyboard
      terminal_new      : in  std_logic;                     -- Flag that indicates a new character was typed on keyboard
      int_mask          : in  std_logic_vector(15 downto 0); -- Interrupt Mask
      timer_state       : in  std_logic;                     -- Timer State
      timer_duration    : in  std_logic_vector(15 downto 0); -- Timer Duration
      g_sensor_z        : in  std_logic_vector(15 downto 0); -- G-sensor z-axis data
      g_sensor_y        : in  std_logic_vector(15 downto 0); -- G-sensor y-axis data
      g_sensor_x        : in  std_logic_vector(15 downto 0); -- G-sensor x-axis data
      SW                : in  std_logic_vector( 9 downto 0); -- Switches
      addr              : in  std_logic_vector(15 downto 0); -- Address
      RMEM              : in  std_logic_vector(15 downto 0); -- Memory data
      clock             : in  std_logic;                     -- System Clock
      reset             : in  std_logic;                     -- Reset
      -- Outputs
      data_out          : out std_logic_vector(15 downto 0)  -- Data output
   );
end IO_read;

architecture Architecture_1 of IO_read is
   -- Signals
   signal addr_d        : std_logic_vector(15 downto 0); -- Delayed address
   signal terminal_test : std_logic_vector(15 downto 0); -- Indicates a new character was typed on keyboard since it was last read
begin

	process (clock, reset) begin
		if reset = '1' then
         addr_d        <= (others => '0');
         terminal_test <= (others => '0');
		elsif rising_edge(clock) then
      
         -- Set delayed address
         addr_d <= addr;
      
         -- Reset terminal_test when terminal_read is read
         if addr_d = x"FFFF" then terminal_test <= (others => '0'); end if;
         
         -- Set terminal_test to 1 when a new character is typed on the keyboard
         if terminal_new = '1' then terminal_test <= (0 => '1', others => '0'); end if;

      end if;
   end process;

   process (addr_d, terminal_read, terminal_test, int_mask, RMEM, SW, timer_state, timer_duration, g_sensor_z, g_sensor_y, g_sensor_x) 
      variable addr_d_low  : std_logic_vector(7 downto 0);
      variable addr_d_high : std_logic_vector(7 downto 0);
   begin
   
      -- Default values
      data_out <= RMEM;
      
      -- Helper variables
      addr_d_high := '0' & addr_d(14 downto 8);
      addr_d_low  := addr_d(7 downto 0);
      
      -- IO addresses
      if addr_d_high = x"7F" then
         -- IO read mux
         case addr_d_low is
            when x"FF"  => data_out <= terminal_read;
            when x"FD"  => data_out <= terminal_test;
            when x"FA"  => data_out <= int_mask;
            when x"F9"  => data_out <= "000000" & SW;
            when x"F7"  => data_out <= (0 => timer_state, others => '0');
            when x"F6"  => data_out <= timer_duration;
            when x"ED"  => data_out <= g_sensor_z;
            when x"EC"  => data_out <= g_sensor_y;
            when x"EB"  => data_out <= g_sensor_x;
            when others => data_out <= (others => '1'); -- Other ports always return FFFFh
         end case;
      end if;
      
   end process;
   
end Architecture_1;