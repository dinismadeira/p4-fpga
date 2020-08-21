---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : lcd_control.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Translates P4 LCD write and control commands to the LCD controller.
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity lcd_control is
   generic (CLOCK_FREQUENCY_HZ: integer := 50000000);
   port (
      write     : in std_logic;                     -- Flag to indicate it's a write char command (otherwise it's a control command)
      data      : in std_logic_vector(15 downto 0); -- The command data
      clock     : in std_logic;                     -- System Clock
      enable    : in std_logic;                     -- Enable Flag (this flag must be activated to send a command)
      reset     : in std_logic;                     -- Reset
      backlight : out std_logic;                    -- Signal to control display's backlight
      E         : out std_logic;                    -- LCD Enable Signal
      RS        : out std_logic;                    -- LCD RS Signal
      D         : out std_logic_vector(3 downto 0); -- LCD Data Signals
      busy      : out std_logic := '1'              -- Busy Flag Feedback
   );
end lcd_control;

architecture Architecture_1 of lcd_control is
   -- Components
   component lcd_controller
		generic (CLOCK_FREQUENCY_HZ : integer);
      port (
         write  : in std_logic;
         data   : in std_logic_vector(7 downto 0);
         clock  : in std_logic;
         enable : in std_logic;
         reset  : in std_logic;
         E      : out std_logic;
         RS     : out std_logic;
         D      : out std_logic_vector(3 downto 0);
         busy   : out std_logic := '1'
      );
   end component;
   
   -- Signals
   
   -- States
   type states is (ready, set_position_state, display_toggle_state);
   signal state        : states := ready;

   signal position     : std_logic_vector(4 downto 0); -- Position where next char must be written
   
   signal lcd_inited   : std_logic := '0';             -- Backlight will stay off until some command is received
   signal lcd_display  : std_logic := '1';             -- Whether the display is currently on or off
   signal lcd_position : std_logic_vector(5 downto 0); -- Display's internal cursor position (it has 64 collumns)

   -- Controller Inputs
   signal lcd_write    : std_logic;
   signal lcd_data     : std_logic_vector(7 downto 0);
   signal lcd_enable   : std_logic;
   
   -- Controller Outputs
   signal lcd_busy     : std_logic;
   
begin
   -- Controller Instance
   lcd_controller_i : lcd_controller
	generic map (CLOCK_FREQUENCY_HZ => CLOCK_FREQUENCY_HZ)
   port map(
      write  => lcd_write,
      data   => lcd_data,
      clock  => clock,
      enable => lcd_enable,
      reset  => reset,
      E      => E,
      RS     => RS,
      D      => D,
      busy   => lcd_busy
   );
   
   process (clock, reset)
   
      -- Variables
      variable write_char : std_logic_vector(7 downto 0) := (others => '0'); -- Which char to write
      variable display    : std_logic := '1'; -- Whether the display should be on or off
      variable clear      : std_logic := '0'; -- Whether the clear command must be issued
               
      -- Procedures
      -- Write a character to the display
      procedure p_write_char is
      begin
         lcd_enable   <= '1'; -- Send command
         lcd_write    <= '1'; -- Write command
         lcd_data     <= write_char;       -- Data is set with the character to write
         lcd_position <= lcd_position + 1; -- New display internal cursor position
         position     <= position + 1;     -- Automatically move the cursor after writing a char
      end p_write_char;
      
      -- Set the cursor position
      procedure p_set_position is
      begin
         state        <= set_position_state;
         lcd_enable   <= '1'; -- Send command
         lcd_write    <= '0'; -- Control command
         lcd_data     <= '1' & position(4) & "00" & position(3 downto 0); -- Command to set the cursor position
         lcd_position <= position(4) & '0' & position(3 downto 0);        -- New display internal cursor position
      end p_set_position;

      -- Clear display if clear flag is active
      procedure p_clear is
      begin
         if clear = '1' then
            lcd_enable   <= '1'; -- Send command
            lcd_write    <= '0'; -- Control command
            lcd_data     <= x"01";           -- Command to clear the display
            lcd_position <= (others => '0'); -- New display internal cursor position
            clear        := '0';
         end if;
      end p_clear;
      
      -- Toggle the display on or off
      procedure p_display_toggle is
      begin
         state       <= display_toggle_state;
         lcd_enable  <= '1'; -- Send command
         lcd_write   <= '0'; -- Control command
         lcd_data    <= "00001" & display & "00"; -- Command to toggle the display
         lcd_display <= display;                  -- New display state
      end p_display_toggle;

   begin
   
      if reset = '1' then
         state        <= ready;
         position     <= (others => '0');
         lcd_display  <= '1';
         lcd_position <= (others => '0');
         lcd_write    <= '0';
         lcd_data     <= (others => '0');
         lcd_inited   <= '0';
         lcd_enable   <= '0';
         busy         <= '1';
         write_char   := (others => '0');
         display      := '1';
         clear        := '0';
         
      elsif rising_edge(clock) then

         -- Default values
         lcd_enable <= '0';
         
         if state = ready then
            lcd_inited <= lcd_inited or enable;
            busy <= '0';
            -- if a command was sent or lcd is busy, set busy flag
            if lcd_enable = '1' or lcd_busy = '1' then
               busy <= '1';
            elsif enable = '1' then
               busy <= '1';
               if write = '1' then
                  write_char := data(7 downto 0);
                  if position(4) /= lcd_position(5) or position(3 downto 0) /= lcd_position(4 downto 0) then
                     p_set_position;
                  else
                     p_write_char;
                  end if;
               else
                  display := data(15);
                  clear := data(5);
                  position <= data(4 downto 0);
                  if lcd_display /= display then
                     p_display_toggle;
                  else
                     p_clear;
                  end if;
               end if;
            end if;
            
         elsif state = set_position_state then
            if lcd_enable = '0' and lcd_busy = '0' then -- Command sent
               state <= ready;
               p_write_char; -- After updating the internal cursor's position we can write the char
            end if;
            
         elsif state = display_toggle_state then
            if lcd_enable = '0' and lcd_busy = '0' then -- Command sent
               state <= ready;
               p_clear;
            end if;
            
         end if;
      end if;
   end process;
   
   -- Backlight is on when the display is turned on and the display has been inited
   backlight <= lcd_display and lcd_inited;
   
end Architecture_1;