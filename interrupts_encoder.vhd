---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : interrupt_encoder.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Monitors inputs and generates an interrupt signal and the interrupt source value.
--
-- Push buttons are debounced.
-- Analog buttons are disabled after powering up until all readings become zero.
-- All inputs are registered and when an input changes from deactivated to activated,
-- the corresponding bit is enabled in the pending interrupts vector.
-- The pending interrupts vector is anded with the interrupt mask, if the result it's not zero,
--  the interrupt flag will be activated, and the interrupt value will be the interrupt
-- corresponding to the lowest bit of this result.
-- When the interrupt acknowledgment flag is activated, the active interrupt is removed from the
-- pending interrupts vector.
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity interrupts_encoder is
   port (
      -- Inputs
      terminal_new : in  std_logic;                     -- Terminal Interrupt (Keyboard)
      KEY          : in  std_logic_vector(1 downto 0);  -- Push Buttons: KEY0 and KEY1 
      IAK          : in  std_logic;                     -- Interrupt Acknowledgment
      int_mask     : in  std_logic_vector(15 downto 0); -- Interrupt Mask
      timer        : in  std_logic;                     -- Timer Interrupt
      btn_right    : in  std_logic;                     -- Push Button: RIGHT 
      btn_up       : in  std_logic;                     -- Push Button: UP 
      btn_down     : in  std_logic;                     -- Push Button: DOWN
      btn_left     : in  std_logic;                     -- Push Button: LEFT
      btn_select   : in  std_logic;                     -- Push Button: SELECT
      clock_50MHz  : in  std_logic;                     -- 50 MHz Clock
      clock        : in  std_logic;                     -- System Clock
      reset        : in  std_logic;                     -- Reset
      -- Outputs
      int          : out std_logic;                     -- Interrupt Flag
      intv         : out std_logic_vector(3 downto 0)   -- Interrupt Source Value
   );
end interrupts_encoder;

architecture Architecture_1 of interrupts_encoder is
   -- Components
   component debouncer
      port
      (
         button      :  in std_logic;
         clock_50MHz :  in std_logic;
         button_d    : out std_logic
      );
   end component;
   
   -- Signals
   signal ints       : std_logic_vector(8 downto 0) := (others => '0'); -- Pending Interrupts
   signal inputs     : std_logic_vector(8 downto 0) := (others => '0'); -- Inputs
   signal inputs_d   : std_logic_vector(8 downto 0) := (others => '0'); -- Inputs (Delayed)
   signal valid      : std_logic := '0';                                -- Flag to indicate analog buttons readings are valid
begin

   -- Push Buttons Debouncing
   
   -- Debounced KEY(0) button goes to inputs(0)
	debouncer_i0 : debouncer
	port map(
		button => not KEY(0),
		clock_50MHz => clock_50MHz,
		button_d => inputs(0)
	);

   -- Debounced KEY(1) button goes to inputs(1)
	debouncer_i1 : debouncer
	port map(
		button => not KEY(1),
		clock_50MHz => clock_50MHz,
		button_d => inputs(1)
	);
   
   -- Debounced RIGHT button goes to inputs(2)
	debouncer_i2 : debouncer
	port map(
		button => btn_right and valid,
		clock_50MHz => clock_50MHz,
		button_d => inputs(2)
	);
   
   -- Debounced UP button goes to inputs(3)
	debouncer_i3 : debouncer
	port map(
		button => btn_up and valid,
		clock_50MHz => clock_50MHz,
		button_d => inputs(3)
	);
   
   -- Debounced DOWN button goes to inputs(4)
	debouncer_i4 : debouncer
	port map(
		button => btn_down and valid,
		clock_50MHz => clock_50MHz,
		button_d => inputs(4)
	);
   
   -- Debounced LEFT button goes to inputs(5)
	debouncer_i5 : debouncer
	port map(
		button => btn_left and valid,
		clock_50MHz => clock_50MHz,
		button_d => inputs(5)
	);
   
   -- Debounced SELECT button goes to inputs(6)
	debouncer_i6 : debouncer
	port map(
		button => btn_select and valid,
		clock_50MHz => clock_50MHz,
		button_d => inputs(6)
	);
   
   -- Keyboard goes to inputs(7)
   inputs(7) <= terminal_new;
   
   -- Timer goes to inputs(8)
   inputs(8) <= timer;

   -- Priority Encoder (interrupts with lower value are attended first)
   intv <= "0000" when ints(0) = '1' and int_mask(0)  = '1' else -- KEY(0)
           "0001" when ints(1) = '1' and int_mask(1)  = '1' else -- KEY(1)
           "0010" when ints(2) = '1' and int_mask(2)  = '1' else -- Button RIGHT
           "0011" when ints(3) = '1' and int_mask(3)  = '1' else -- Button UP
           "0100" when ints(4) = '1' and int_mask(4)  = '1' else -- Button DOWN
           "0101" when ints(5) = '1' and int_mask(5)  = '1' else -- Button LEFT
           "0110" when ints(6) = '1' and int_mask(6)  = '1' else -- Button SELECT
           "0111" when ints(7) = '1' and int_mask(7)  = '1' else -- Keyboard
           "1111" when ints(8) = '1' and int_mask(15) = '1' else -- Timer
           "0000";
           
   -- Interrupt Flag
   int <= '0' when (ints and (int_mask(15) & int_mask(7 downto 0))) = 0 else '1';     

   process (clock, reset) begin
      if reset = '1' then
         ints     <= (others => '0');
         inputs_d <= (others => '0');
         valid    <= '0';
      elsif rising_edge(clock) then
      
         -- Register New Interrupts
         if inputs(0) = '1' and inputs_d(0) = '0' then ints <= ints or "000000001"; end if; -- KEY(0)
         if inputs(1) = '1' and inputs_d(1) = '0' then ints <= ints or "000000010"; end if; -- KEY(1)
         if inputs(2) = '1' and inputs_d(2) = '0' then ints <= ints or "000000100"; end if; -- Button RIGHT
         if inputs(3) = '1' and inputs_d(3) = '0' then ints <= ints or "000001000"; end if; -- Button UP
         if inputs(4) = '1' and inputs_d(4) = '0' then ints <= ints or "000010000"; end if; -- Button DOWN
         if inputs(5) = '1' and inputs_d(5) = '0' then ints <= ints or "000100000"; end if; -- Button LEFT
         if inputs(6) = '1' and inputs_d(6) = '0' then ints <= ints or "001000000"; end if; -- Button SELECT
         if inputs(7) = '1' and inputs_d(7) = '0' then ints <= ints or "010000000"; end if; -- Keyboard
         if inputs(8) = '1' and inputs_d(8) = '0' then ints <= ints or "100000000"; end if; -- Timer
         
         -- Remove current interrupt from pending interrupts when Interrupt Acknowledgment flag is ativated
         if IAK = '1' then
            case intv is
               when x"0" => ints <= ints and "111111110"; -- KEY(0)
               when x"1" => ints <= ints and "111111101"; -- KEY(1)
               when x"2" => ints <= ints and "111111011"; -- Button RIGHT
               when x"3" => ints <= ints and "111110111"; -- Button UP
               when x"4" => ints <= ints and "111101111"; -- Button DOWN
               when x"5" => ints <= ints and "111011111"; -- Button LEFT
               when x"6" => ints <= ints and "110111111"; -- Button SELECT
               when x"7" => ints <= ints and "101111111"; -- Keyboard
               when x"F" => ints <= ints and "011111111"; -- Timer
               when others => null;
            end case;
         end if;
         
         -- Set delayed inputs
         inputs_d <= inputs;
         
         -- Analog buttons readings are only valid after all readings become zero
         if (inputs(2) or inputs(3) or inputs(4) or inputs(5) or inputs(6)) = '0' then
            valid <= '1';
         end if;
         
      end if;
   end process;

end Architecture_1;