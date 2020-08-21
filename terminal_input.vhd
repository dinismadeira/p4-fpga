---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : terminal_input.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Decodes PS/2 signals and generates inputs on terminal.
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity terminal_input is
   port (
      -- Inputs
      ps2_clk       : in  std_logic;                     -- Clock signal from PS/2 keyboard
      ps2_data      : in  std_logic;                     -- Data signal from PS/2 keyboard
      clock_50MHz   : in  std_logic;                     -- 50 MHz Clock (for keyboard timing)
      clock         : in  std_logic;                     -- System Clock (for system interface)
      reset         : in  std_logic;                     -- Reset
      -- Outputs
      terminal_read : out std_logic_vector(15 downto 0); -- ASCII of the last character typed on keyboard
      terminal_new  : out std_logic                      -- Flag to indicate a new character was typed on keyboard
   );
end terminal_input;

architecture Architecture_1 of terminal_input is
   -- Signals
   signal ps2_code_new   : std_logic;                     -- PS/2 Code Available
   signal ps2_code_new_d : std_logic_vector(1 downto 0);  -- PS/2 Code Available Delayed
   signal ps2_code       : std_logic_vector(7 downto 0);  -- PS/2 Code Value
   signal dead_key_alt   : boolean;                       -- Pending dead key alt status 
   signal dead_key_ctrl  : boolean;                       -- Pending dead key ctrl status
   signal dead_key_shift : boolean;                       -- Pending dead key shift status
   signal dead_key_value : std_logic_vector(7 downto 0);  -- Pending dead key scan code
   signal e0_code        : boolean;                       -- Decoding an E0 multi-code scan code (code after E0)
   signal e1_code        : boolean;                       -- Decoding an E1 multi-code scan code (second code after E1)
   signal e1_code_set    : boolean;                       -- Decoding an E1 multi-code scan code (first code after E1)
   signal e1_code_value  : std_logic_vector(7 downto 0);  -- Value of the first code after E1
   signal break          : boolean;                       -- Decoding a breaking scan code
   signal alt            : boolean;                       -- Flag to indicate an alt key is pressed
   signal caps           : boolean;                       -- Flag to indicate caps lock is active
   signal ctrl           : boolean;                       -- Flag to indicate an ctrl key is pressed
   signal shift          : boolean;                       -- Flag to indicate an shift key is pressed
   signal output_read    : std_logic_vector(15 downto 0); -- ASCII of the last character typed on keyboard
   signal output_new     : std_logic;                     -- Flag to indicate a new character was typed on keyboard
   signal output_read_s  : std_logic_vector(15 downto 0); -- ASCII of the last character typed on keyboard (Sync)
   signal output_new_s   : std_logic;                     -- Flag to indicate a new character was typed on keyboard (Sync)
   
   -- Components
   component ps2_keyboard
      generic (clk_freq : integer := 50000000; debounce_counter_size : integer := 8);
      port (
         ps2_clk      : in  std_logic;
         ps2_data     : in  std_logic;
         clk          : in  std_logic;
         reset        : in  std_logic;
         ps2_code_new : out std_logic;
         ps2_code     : out std_logic_vector(7 downto 0)
      );
   end component;
   
begin
   -- PS/2 Keyboard Instance
   ps2_keyboard_i : ps2_keyboard
   port map(
      ps2_clk      => ps2_clk,
      ps2_data     => ps2_data,
      clk          => clock_50MHz,
      reset        => reset,
      ps2_code_new => ps2_code_new,
      ps2_code     => ps2_code
   );
   
   -- Main Process
   process (clock_50MHz, reset) 
      variable ascii    : std_logic_vector(7 downto 0); -- ASCII of the pressed key
      variable dead_key : boolean;                      -- Flag to indicate the pressed key is a dead key 
   begin
      if reset = '1' then
         ps2_code_new_d <= (others => '0');
         dead_key_alt   <= false;
         dead_key_ctrl  <= false;
         dead_key_shift <= false;
         dead_key_value <= (others => '0');
         e0_code        <= false;
         e1_code        <= false;
         e1_code_set    <= false;
         e1_code_value  <= (others => '0');
         break          <= false;
         alt            <= false;
         ctrl           <= false;
         shift          <= false;
         caps           <= false;
      elsif rising_edge(clock_50MHz) then
      
         -- Default values
         output_new   <= '0';
         ascii        := (others => '0');
         dead_key     := false;
         
         -- A new code has been made available
         if ps2_code_new_d(0) = '1' and ps2_code_new_d(1) = '0' then
         
            -- Values updated for every code
            break       <= false;       -- Reset break flag 
            e1_code     <= e1_code_set; -- Moving to second code of an E1 multi-code scan code
            e1_code_set <= false;       -- Reset E1 multi-code scan code flag
            
            -- Special codes (more codes must be received)
            if    ps2_code = x"F0" then break         <= true;     -- Breaking scan code
            elsif ps2_code = x"E1" then e1_code_set   <= true;     -- E1 multi-code scan code
            elsif ps2_code = x"E0" then e0_code       <= true;     -- E0 multi-code scan code
            elsif e1_code_set      then e1_code_value <= ps2_code; -- First code in an E1 multi-code scan code
            
            -- Decode scan code (received all codes)
            else
               -- E0 multi-code scan code
               if e0_code then
                  case ps2_code is
                     when x"14" => ctrl <= not break; -- Right Control
                     when x"11" => alt  <= not break; -- Alt Gr
                                   ctrl <= not break;
                     when others => null;
                  end case;
               -- Single-code scan code
               elsif not e1_code then
                  case ps2_code is
                     when x"12" => shift <= not break; -- Left Shift
                     when x"59" => shift <= not break; -- Right Shift
                     when x"14" => ctrl  <= not break; -- Left Control
                     when x"11" => alt   <= not break; -- Left Alt
                     when x"58" => if not break then caps <= not caps; end if; -- Caps
                     when others => null;
                  end case;
               end if;
                  
               -- Key Pressed Down (generate an ASCII value)
               if not break then
               
                  -- E1 commands
                  if e1_code then
                     if e1_code_value = x"14" and ps2_code = x"77" then
                        ascii := x"0F"; -- ☼ Pause
                     end if;
                     
                  -- E0 commands
                  elsif e0_code then
                     case ps2_code is
                        when x"7C" => ascii := x"0D"; -- ♪ Print Screen
                        when x"4A" => ascii := x"2F"; -- /
                        when x"5A" => ascii := x"14"; -- ¶ Enter
                        when x"70" => ascii := x"12"; -- ↕ Insert
                        when x"6C" => ascii := x"11"; -- ◄ Home
                        when x"7D" => ascii := x"1E"; -- ▲ Page Up
                        when x"71" => ascii := x"1D"; -- ↔ Delete
                        when x"69" => ascii := x"10"; -- ► End
                        when x"7A" => ascii := x"1F"; -- ▼ Page Down
                        when x"75" => ascii := x"18"; -- ↑ Up Arrow
                        when x"6B" => ascii := x"1B"; -- ← Left Arrow
                        when x"72" => ascii := x"19"; -- ↓ Down Arrow
                        when x"74" => ascii := x"1A"; -- → Right Arrow
                        when x"1F" => ascii := x"A9"; -- ⌐ Windows Left
                        when x"27" => ascii := x"AA"; -- ¬ Windows Right
                        when x"2F" => ascii := x"7F"; -- ⌂ Menu
                        when others => null;
                     end case;
                     
                  -- Single Code Commands
                  else
                     -- Upper Case
                     if shift xor caps then
                        case ps2_code is
                           when x"1C" => ascii := x"41"; -- A
                           when x"32" => ascii := x"42"; -- B
                           when x"21" => ascii := x"43"; -- C
                           when x"23" => ascii := x"44"; -- D
                           when x"24" => ascii := x"45"; -- E
                           when x"2B" => ascii := x"46"; -- F
                           when x"34" => ascii := x"47"; -- G
                           when x"33" => ascii := x"48"; -- H
                           when x"43" => ascii := x"49"; -- I
                           when x"3B" => ascii := x"4A"; -- J
                           when x"42" => ascii := x"4B"; -- K
                           when x"4B" => ascii := x"4C"; -- L
                           when x"3A" => ascii := x"4D"; -- M
                           when x"31" => ascii := x"4E"; -- N
                           when x"44" => ascii := x"4F"; -- O
                           when x"4D" => ascii := x"50"; -- P
                           when x"15" => ascii := x"51"; -- Q
                           when x"2D" => ascii := x"52"; -- R
                           when x"1B" => ascii := x"53"; -- S
                           when x"2C" => ascii := x"54"; -- T
                           when x"3C" => ascii := x"55"; -- U
                           when x"2A" => ascii := x"56"; -- V
                           when x"1D" => ascii := x"57"; -- W
                           when x"22" => ascii := x"58"; -- X
                           when x"35" => ascii := x"59"; -- Y
                           when x"1A" => ascii := x"5A"; -- Z
                           when x"4C" => ascii := x"80"; -- Ç
                           when others => null;
                        end case;
                     -- Lower Case
                     else
                        case ps2_code is
                           when x"1C" => ascii := x"61"; -- a
                           when x"32" => ascii := x"62"; -- b
                           when x"21" => ascii := x"63"; -- c
                           when x"23" => ascii := x"64"; -- d
                           when x"24" => ascii := x"65"; -- e
                           when x"2B" => ascii := x"66"; -- f
                           when x"34" => ascii := x"67"; -- g
                           when x"33" => ascii := x"68"; -- h
                           when x"43" => ascii := x"69"; -- i
                           when x"3B" => ascii := x"6A"; -- j
                           when x"42" => ascii := x"6B"; -- k
                           when x"4B" => ascii := x"6C"; -- l
                           when x"3A" => ascii := x"6D"; -- m
                           when x"31" => ascii := x"6E"; -- n
                           when x"44" => ascii := x"6F"; -- o
                           when x"4D" => ascii := x"70"; -- p
                           when x"15" => ascii := x"71"; -- q
                           when x"2D" => ascii := x"72"; -- r
                           when x"1B" => ascii := x"73"; -- s
                           when x"2C" => ascii := x"74"; -- t
                           when x"3C" => ascii := x"75"; -- u
                           when x"2A" => ascii := x"76"; -- v
                           when x"1D" => ascii := x"77"; -- w
                           when x"22" => ascii := x"78"; -- x
                           when x"35" => ascii := x"79"; -- y
                           when x"1A" => ascii := x"7A"; -- z
                           when x"4C" => ascii := x"87"; -- ç
                           when others => null;
                        end case;
                     end if;
                     
                     -- Shift Keys
                     if shift then
                        case ps2_code is
                           -- Numbers Row
                           when x"0E" => ascii := x"7C"; -- |
                           when x"16" => ascii := x"21"; -- !
                           when x"1E" => ascii := x"22"; -- "
                           when x"26" => ascii := x"23"; -- #
                           when x"25" => ascii := x"24"; -- $
                           when x"2E" => ascii := x"25"; -- %
                           when x"36" => ascii := x"26"; -- &
                           when x"3D" => ascii := x"2F"; -- /
                           when x"3E" => ascii := x"28"; -- (
                           when x"46" => ascii := x"29"; -- )
                           when x"45" => ascii := x"3D"; -- =
                           when x"4E" => ascii := x"3F"; -- ?
                           when x"55" => ascii := x"AF"; -- »
                           -- Tab Row
                           when x"54" => ascii := x"2A"; -- *
                           when x"5B" => dead_key := true; -- `
                           -- Caps Row
                           when x"52" => ascii := x"A6"; -- ª
                           when x"5D" => dead_key := true; -- ^
                           -- Shifts Row
                           when x"61" => ascii := x"3E"; -- >
                           when x"41" => ascii := x"3B"; -- ;
                           when x"49" => ascii := x"3A"; -- :
                           when x"4A" => ascii := x"5F"; -- _
                           when others => null;
                        end case;
                     -- Base Keys
                     else
                        case ps2_code is
                           -- Numbers Row
                           when x"0E" => ascii := x"5C"; -- \
                           when x"16" => ascii := x"31"; -- 1
                           when x"1E" => ascii := x"32"; -- 2
                           when x"26" => ascii := x"33"; -- 3
                           when x"25" => ascii := x"34"; -- 4
                           when x"2E" => ascii := x"35"; -- 5
                           when x"36" => ascii := x"36"; -- 6
                           when x"3D" => ascii := x"37"; -- 7
                           when x"3E" => ascii := x"38"; -- 8
                           when x"46" => ascii := x"39"; -- 9
                           when x"45" => ascii := x"30"; -- 0
                           when x"4E" => ascii := x"27"; -- '
                           when x"55" => ascii := x"AE"; -- «
                           -- Tab Row
                           when x"54" => ascii := x"2B"; -- +
                           when x"5B" => dead_key := true; -- ´
                           -- Caps Row
                           when x"52" => ascii := x"A7"; -- º
                           when x"5D" => dead_key := true; -- ~
                           -- Shifts Row
                           when x"61" => ascii := x"3C"; -- <
                           when x"41" => ascii := x"2C"; -- ,
                           when x"49" => ascii := x"2E"; -- .
                           when x"4A" => ascii := x"2D"; -- -
                           when others => null;
                        end case;
                     end if;
               
                     -- Other Keys
                     case ps2_code is
                        -- F Keys Row
                        when x"76" => ascii := x"17"; -- ↨ Escape
                        when x"05" => ascii := x"01"; -- ☺ F1
                        when x"06" => ascii := x"02"; -- ☻ F2
                        when x"04" => ascii := x"03"; -- ♥ F3
                        when x"0C" => ascii := x"04"; -- ♦ F4
                        when x"03" => ascii := x"05"; -- ♣ F5
                        when x"0B" => ascii := x"06"; -- ♠ F6
                        when x"83" => ascii := x"07"; -- • F7
                        when x"0A" => ascii := x"08"; -- ◘ F8
                        when x"01" => ascii := x"09"; -- ○ F9
                        when x"09" => ascii := x"0A"; -- ◙ F10
                        when x"78" => ascii := x"0B"; -- ♂ F11
                        when x"07" => ascii := x"0C"; -- ♀ F12
                        when x"7E" => ascii := x"0E"; -- ♫ Scroll
                        
                        when x"66" => ascii := x"13"; -- ‼ BackSpace
                        when x"5A" => ascii := x"14"; -- ¶ Enter
                        when x"0D" => ascii := x"16"; -- ▬ Tab
                        when x"29" => ascii := x"20"; --   Space

                        -- Keypad
                        when x"77" => ascii := x"1C"; -- ∟ Num
                        when x"7C" => ascii := x"2A"; -- *
                        when x"79" => ascii := x"2B"; -- +
                        when x"7B" => ascii := x"2D"; -- -
                        when x"71" => ascii := x"2E"; -- .
                        when x"70" => ascii := x"30"; -- 0
                        when x"69" => ascii := x"31"; -- 1
                        when x"72" => ascii := x"32"; -- 2
                        when x"7A" => ascii := x"33"; -- 3
                        when x"6B" => ascii := x"34"; -- 4
                        when x"73" => ascii := x"35"; -- 5
                        when x"74" => ascii := x"36"; -- 6
                        when x"6C" => ascii := x"37"; -- 7
                        when x"75" => ascii := x"38"; -- 8
                        when x"7D" => ascii := x"39"; -- 9
                        when others => null;
                     end case;
                     
                     -- Alt GR (replaces ASCII value already set for these keys)
                     if alt and ctrl then
                        case ps2_code is
                           when x"1E" => ascii := x"40"; -- @
                           when x"26" => ascii := x"9C"; -- £
                           when x"25" => ascii := x"15"; -- §
                           when x"3D" => ascii := x"7B"; -- {
                           when x"3E" => ascii := x"5B"; -- [
                           when x"46" => ascii := x"5D"; -- ]
                           when x"45" => ascii := x"7D"; -- }
                           when x"24" => ascii := x"EE"; -- €
                           when x"54" => dead_key := true; -- ¨
                           when others => null;
                        end case;
                     end if;
                        
                     -- Dead Keys
                     -- Upper Case
                     if shift xor caps then
                        if dead_key_value = x"5B" then
                           if dead_key_shift then
                              if ps2_code = x"29" then ascii := x"60"; end if; -- `
                           else
                              case ps2_code is
                                 when x"29" => ascii := x"00"; -- ´
                                 when x"24" => ascii := x"90"; -- É
                                 when others => null;
                              end case;
                           end if;
                        elsif dead_key_value = x"5D" then
                           if dead_key_shift then
                              if ps2_code = x"29" then ascii := x"5E"; end if; -- ^
                           else
                              case ps2_code is
                                 when x"29" => ascii := x"7E"; -- ~
                                 when x"31" => ascii := x"A5"; -- Ñ
                                 when others => null;
                              end case;
                           end if;
                        elsif dead_key_value = x"54" and dead_key_alt and dead_key_ctrl then
                           case ps2_code is
                              when x"29" => ascii := x"00"; -- ¨
                              when x"1C" => ascii := x"8E"; -- Ä
                              when x"44" => ascii := x"99"; -- Ö
                              when x"3C" => ascii := x"9A"; -- Ü
                              when others => null;
                           end case;
                        end if;
                     -- Lower Case
                     else   
                        if dead_key_value = x"5B" then
                           if dead_key_shift then
                              case ps2_code is
                                 when x"29" => ascii := x"60"; -- `
                                 when x"1C" => ascii := x"85"; -- à
                                 when x"24" => ascii := x"8A"; -- è
                                 when x"43" => ascii := x"8D"; -- ì
                                 when x"44" => ascii := x"95"; -- ò
                                 when x"3C" => ascii := x"97"; -- ù
                                 when others => null;
                              end case;
                           else
                              case ps2_code is 
                                 when x"29" => ascii := x"00"; -- ´
                                 when x"1C" => ascii := x"A0"; -- á
                                 when x"24" => ascii := x"82"; -- é
                                 when x"43" => ascii := x"A1"; -- í
                                 when x"44" => ascii := x"A2"; -- ó
                                 when x"3C" => ascii := x"A3"; -- ú
                                 when others => null;
                              end case;
                           end if;
                        elsif dead_key_value = x"5D" then
                           if dead_key_shift then
                              case ps2_code is
                                 when x"29" => ascii := x"5E"; -- ^
                                 when x"1C" => ascii := x"83"; -- â
                                 when x"24" => ascii := x"88"; -- ê
                                 when x"43" => ascii := x"8C"; -- î
                                 when x"44" => ascii := x"93"; -- ô
                                 when x"3C" => ascii := x"96"; -- û
                                 when others => null;
                              end case;
                           else
                              case ps2_code is 
                                 when x"29" => ascii := x"7E"; -- ~
                                 when x"31" => ascii := x"A4"; -- ñ
                                 when others => null;
                              end case;
                           end if;
                        elsif dead_key_value = x"54" and dead_key_alt and dead_key_ctrl then
                           case ps2_code is
                              when x"29" => ascii := x"00"; -- ¨
                              when x"1C" => ascii := x"84"; -- ä
                              when x"24" => ascii := x"89"; -- ë
                              when x"43" => ascii := x"8B"; -- ï
                              when x"44" => ascii := x"94"; -- ö
                              when x"3C" => ascii := x"81"; -- ü
                              when x"35" => ascii := x"98"; -- ÿ
                              when others => null;
                           end case;
                        end if;
                     end if;
                  end if;
                  
                  -- Save Dead Key
                  if dead_key then
                     dead_key_alt   <= alt;
                     dead_key_ctrl  <= ctrl;
                     dead_key_shift <= shift;
                     dead_key_value <= ps2_code;
                     
                  -- Output ASCII
                  elsif ascii /= x"00" then
                     -- Reset Any Pending Dead Key
                     dead_key_alt   <= false;
                     dead_key_ctrl  <= false;
                     dead_key_shift <= false;
                     dead_key_value <= (others => '0');
                     -- Update Output
                     output_new  <= '1';                             -- Set flag to indicate a new character was typed on keyboard
                     output_read <= x"00" & ascii;                   -- Extended ASCII of the pressed key goes to the lower byte
                     if alt   then output_read(10) <= '1'; end if; -- Bit 10 (LSB 0) is set to 1 when alt key is pressed, 0 otherwise
                     if ctrl  then output_read(9)  <= '1'; end if; -- Bit 9 (LSB 0) is set to 1 when ctrl key is pressed, 0 otherwise
                     if shift then output_read(8)  <= '1'; end if; -- Bit 8 (LSB 0) is set to 1 when shift key is pressed, 0 otherwise
                  end if;

               end if; -- Key Down
               
               e0_code <= false;
               
            end if; -- Translate Code
         end if; -- New Code
         
         -- Set Delayed PS/2 Code Available flag
         ps2_code_new_d(0) <= ps2_code_new;
         ps2_code_new_d(1) <= ps2_code_new_d(0);
      end if;
   end process;
	
   -- Output Process
   process (clock, reset) begin
      if reset = '1' then
         terminal_read <= (others => '0');
         terminal_new  <= '0';
      elsif rising_edge(clock) then
			terminal_new  <= output_new_s;
			terminal_read <= output_read_s;
			output_new_s  <= output_new;
			output_read_s <= output_read;
      end if;
   end process;
	
end Architecture_1;