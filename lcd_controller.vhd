---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : lcd_controller.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Low level controller for the LCD display.
--
-- Performs the initialization of the LCD display.
-- Outputs a busy flag that is active during the display's initialization and after a command
-- is issued in order to comply with the display's execution times.
--
-- Based on lcd_controller.vhd, version 2.0 6/13/2012, Scott Larson
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lcd_controller is
   generic (CLOCK_FREQUENCY_HZ: integer);
   port (
      write  : in  std_logic;                    -- Flag to indicate it's a write char command (otherwise it's a control command)
      data   : in  std_logic_vector(7 downto 0); -- The command data
      clock  : in  std_logic;                    -- System Clock
      enable : in  std_logic;                    -- Enable Flag (this flag must be activated to send a command)
      reset  : in  std_logic;                    -- Reset
      E      : out std_logic;                    -- LCD Enable Signal
      RS     : out std_logic;                    -- LCD RS Signal
      D      : out std_logic_vector(3 downto 0); -- LCD Data Signals
      busy   : out std_logic := '1');            -- Busy Flag Feedback
end lcd_controller;

architecture controller of lcd_controller is
   type states is (power_up, initialize, ready, send);
   signal state       : states  := power_up;
   constant freq      : integer := CLOCK_FREQUENCY_HZ / 1000000; -- System Clock frequency in MHz
   signal lcd_sending : std_logic_vector(7 downto 0);
begin
   process (clock, reset)
      variable clock_count : integer := 0; -- Increments every clock period
      variable delay_count : integer := 0; -- Increments after waiting a delay

      -- Increments delay_counter after a delay
      procedure wait_delay (
         constant delay : in integer
      ) is
      begin
         if ((delay * freq) = clock_count) then
            delay_count := delay_count + 1;
            clock_count := 0;
         else
            clock_count := clock_count + 1;
         end if;
      end wait_delay;

   begin
   
      if (reset = '1') then
         E           <= '0';
         RS          <= '0';
         D           <= (others => '0');
         busy        <= '1';
         state       <= power_up;
         lcd_sending <= (others => '0');
         clock_count := 0;
         delay_count := 0;
         
      elsif rising_edge(clock) then

         case state is
               --wait 50 ms to ensure Vdd has risen and required LCD wait is met
            when power_up =>
               busy <= '1';
               if (delay_count = 0) then
                  wait_delay(50000);
               else --power-up complete
                  state <= initialize;
                  clock_count := 0;
                  delay_count := 0;
               end if;

            when initialize =>
               busy <= '1';
               RS   <= '0';
               case delay_count is
                  -- Set 8-bit mode (1st)
                  when 0 =>
                     D <= "0011";
                     E <= '0';
                     wait_delay(1);
                  when 1 =>
                     E <= '1';
                     wait_delay(1);
                  when 2 =>
                     E <= '0';
                     wait_delay(4500);
                  -- Set 8-bit mode (2nd)
                  when 3 =>
                     D <= "0011";
                     E <= '0';
                     wait_delay(1);
                  when 4 =>
                     E <= '1';
                     wait_delay(1);
                  when 5 =>
                     E <= '0';
                     wait_delay(4500);
                  -- Set 8-bit mode (3rd)
                  when 6 =>
                     D <= "0011";
                     E <= '0';
                     wait_delay(1);
                  when 7 =>
                     E <= '1';
                     wait_delay(1);
                  when 8 =>
                     E <= '0';
                     wait_delay(150);
                  -- Now we can be sure it is in the 8-bit mode
                  -- Set 4-bit mode
                  when 9 =>
                     D <= "0010";
                     E <= '0';
                     wait_delay(1);
                  when 10 =>
                     E <= '1';
                     wait_delay(1);
                  when 11 =>
                     E <= '0';
                     wait_delay(100);
                  -- Set 4-bit mode, 2 lines, 5x8 font
                  when 12 =>
                     D <= "0010";
                     E <= '0';
                     wait_delay(1);
                  when 13 =>
                     E <= '1';
                     wait_delay(1);
                  when 14 =>
                     E <= '0';
                     wait_delay(100);
                  when 15 =>
                     D <= "1000";
                     E <= '0';
                     wait_delay(1);
                  when 16 =>
                     E <= '1';
                     wait_delay(1);
                  when 17 =>
                     E <= '0';
                     wait_delay(100);
                  -- Set display on, cursor off, blink off
                  when 18 =>
                     D <= "0000";
                     E <= '0';
                     wait_delay(1);
                  when 19 =>
                     E <= '1';
                     wait_delay(1);
                  when 20 =>
                     E <= '0';
                     wait_delay(100);
                  when 21 =>
                     D <= "1100";
                     E <= '0';
                     wait_delay(1);
                  when 22 =>
                     E <= '1';
                     wait_delay(1);
                  when 23 =>
                     E <= '0';
                     wait_delay(100);
                  -- Clear display
                  when 24 =>
                     D <= "0000";
                     E <= '0';
                     wait_delay(1);
                  when 25 =>
                     E <= '1';
                     wait_delay(1);
                  when 26 =>
                     E <= '0';
                     wait_delay(100);
                  when 27 =>
                     D <= "0001";
                     E <= '0';
                     wait_delay(1);
                  when 28 =>
                     E <= '1';
                     wait_delay(100);
                  when 29 =>
                     E <= '0';
                     wait_delay(2000);
                  -- Set entry mode
                  when 30 =>
                     D <= "0000";
                     E <= '0';
                     wait_delay(1);
                  when 31 =>
                     E <= '1';
                     wait_delay(1);
                  when 32 =>
                     E <= '0';
                     wait_delay(100);
                  when 33 =>
                     D <= "0110";
                     E <= '0';
                     wait_delay(1);
                  when 34 =>
                     E <= '1';
                     wait_delay(1);
                  when 35 =>
                     E <= '0';
                     wait_delay(100);
                  when others =>
                     busy  <= '0';
                     state <= ready;
                     clock_count := 0;
                     delay_count := 0;
               end case;

            when ready =>
               if (enable = '1') then
                  lcd_sending <= data;
                  busy        <= '1';
                  RS          <= write;
                  state       <= send;
                  clock_count := 0;
                  delay_count := 0;
               else
                  busy  <= '0';
                  RS    <= '0';
                  D     <= "0000";
                  state <= ready;
               end if;

            -- Send command to the display       
            when send =>
               busy <= '1';

               case delay_count is
                  when 0 =>
                     D <= lcd_sending(7 downto 4);
                     E <= '0';
                     wait_delay(1);
                  when 1 =>
                     E <= '1';
                     wait_delay(1);
                  when 2 =>
                     E <= '0';
                     wait_delay(100);
                  when 3 =>
                     D <= lcd_sending(3 downto 0);
                     E <= '0';
                     wait_delay(1);
                  when 4 =>
                     E <= '1';
                     wait_delay(1);
                  when 5 =>
                     E <= '0';
                     if (lcd_sending = x"01") then -- clearing the display takes 1.52 ms
                        wait_delay(2000);
                     else
                        wait_delay(100);
                     end if;
                  when others =>
                     state <= ready;
                     clock_count := 0;
                     delay_count := 0;
               end case;
         end case;

      end if;
   end process;
end controller;