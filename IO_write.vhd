---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : IO_write.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Decodes the address and enables writing to the corresponding port. 
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity IO_write is
   port (
      -- inputs
      RM                : in  std_logic;                     -- Write flag
      data_in           : in  std_logic_vector(15 downto 0); -- Data to write
      addr              : in  std_logic_vector(15 downto 0); -- Address
      clock             : in  std_logic;                     -- System Clock
      reset             : in  std_logic;                     -- Reset
      -- outputs
      data_in_d         : out std_logic_vector(15 downto 0); -- Registered data for inputs
      terminal_write    : out std_logic;                     -- Terminal Write Port
      terminal_control  : out std_logic;                     -- Terminal Control Port
      terminal_color    : out std_logic;                     -- Terminal Colour Port
      int_mask          : out std_logic;                     -- Interrupt Mask
      leds_write        : out std_logic;                     -- LEDs Write Port
      timer_state       : out std_logic;                     -- Timer State Port
      timer_duration    : out std_logic;                     -- Timer Duration Port
      lcd_write         : out std_logic;                     -- LCD Write Port
      lcd_control       : out std_logic;                     -- LCD Control Port
      hex3_write        : out std_logic;                     -- 7-Segment Display 3 Port
      hex2_write        : out std_logic;                     -- 7-Segment Display 2 Port
      hex1_write        : out std_logic;                     -- 7-Segment Display 1 Port
      hex0_write        : out std_logic;                     -- 7-Segment Display 0 Port
      hex5_write        : out std_logic;                     -- 7-Segment Display 5 Port
      hex4_write        : out std_logic;                     -- 7-Segment Display 4 Port
      mem_write         : out std_logic                      -- Data Memory Write Enable
   );
end IO_write;

architecture Architecture_1 of IO_write is
   -- Signals
   signal RM_d   : std_logic;                     -- Registered RM
   signal addr_d : std_logic_vector(15 downto 0); -- Delayed address
begin

	process (clock, reset) begin
		if reset = '1' then
         RM_d      <= '0';
         data_in_d <= (others => '0');
         addr_d    <= (others => '0');
		elsif rising_edge(clock) then
         RM_d      <= RM;
         data_in_d <= data_in;
         addr_d    <= addr;
      end if;
   end process;

   process (RM_d, data_in_d, addr_d) 
      variable addr_d_low  : std_logic_vector(7 downto 0);
      variable addr_d_high : std_logic_vector(7 downto 0);
   begin
   
      -- Default values
      terminal_write   <= '0';
      terminal_control <= '0';
      terminal_color   <= '0';
      int_mask         <= '0';
      leds_write       <= '0';
      timer_state      <= '0';
      timer_duration   <= '0';
      lcd_write        <= '0';
      lcd_control      <= '0';
      hex3_write       <= '0';
      hex2_write       <= '0';
      hex1_write       <= '0';
      hex0_write       <= '0';
      hex5_write       <= '0';
      hex4_write       <= '0';
      
      -- Helper variables
      addr_d_high := '0' & addr_d(14 downto 8);
      addr_d_low  := addr_d(7 downto 0);
      
      -- IO addresses
      if addr_d_high = x"7F" then
      
         -- IO write decoder
         case addr_d_low is
            when x"FE"  => terminal_write   <= RM_d;
            when x"FC"  => terminal_control <= RM_d;
            when x"FB"  => terminal_color   <= RM_d;
            when x"FA"  => int_mask         <= RM_d;
            when x"F8"  => leds_write       <= RM_d;
            when x"F7"  => timer_state      <= RM_d;
            when x"F6"  => timer_duration   <= RM_d;
            when x"F5"  => lcd_write        <= RM_d;
            when x"F4"  => lcd_control      <= RM_d;
            when x"F3"  => hex3_write       <= RM_d;
            when x"F2"  => hex2_write       <= RM_d;
            when x"F1"  => hex1_write       <= RM_d;
            when x"F0"  => hex0_write       <= RM_d;
            when x"EF"  => hex5_write       <= RM_d;
            when x"EE"  => hex4_write       <= RM_d;
            when others => null;
         end case;
         
      end if;
      
   end process;
   
	mem_write <= RM;
   
end Architecture_1;