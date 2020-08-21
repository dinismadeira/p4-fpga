---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : instruction_decoder_base.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Decodes an instruction and generates control signals.
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity instruction_decoder_base is
   port (
      -- Inputs
      RI          : in  std_logic_vector(15 downto 0); -- Instruction Register
      -- Outputs
      WRC         : out std_logic;                     -- Write Register C
      SelC        : out std_logic_vector(2 downto 0);  -- Select Register C
      RM          : out std_logic;                     -- Write Memory
      ALUC        : out std_logic_vector(4 downto 0);  -- ALU Control
      M2          : out std_logic;                     -- MUX2
      M3          : out std_logic_vector(1 downto 0);  -- MUX3
      SelA        : out std_logic_vector(2 downto 0);  -- Select Register A
      SelB        : out std_logic_vector(2 downto 0)   -- Select Register B
   );
end instruction_decoder_base;

architecture Architecture_1 of instruction_decoder_base is begin
   process (RI)
      variable format : std_logic_vector(1 downto 0) := RI(15 downto 14);
      variable op     : std_logic_vector(2 downto 0) := RI(10 downto 8);
   begin

      WRC <= '0';
      if format = "10" then WRC <= '1'; end if;                                -- Arithmetic Operations
      if format = "00" and RI(13 downto 12) = "11" then WRC <= '1'; end if;    -- JAL
      if format = "01" and (op = "000" or op = "010") then WRC <= '1'; end if; -- Transfer Operations
      if format = "11" and op(2) = '0' then WRC <= '1'; end if;                -- Transfer Operations
      
      SelC <= RI(13 downto 11);
      if format = "00" and RI(13 downto 12) = "11" then SelC <= "111"; end if; -- JAL
      
      RM <= '0';
      if format = "01" and op = "011" then RM <= '1'; end if; -- STOR
      
      ALUC <= "11000";
      if format = "10" then ALUC <= RI(10 downto 6); end if;                        -- Arithmetic Operations
      if format = "01" and op = "000" then ALUC <= "11001"; end if;                 -- MOV
      if format = "11" and op(2) = '0' then ALUC <= "110" & op(1 downto 0); end if; -- MVI, MVIH, MVIL
      if format = "11" and op(2) = '1' then ALUC <= "111" & op(1 downto 0); end if; -- CLC, STC, CMC
      
      M2 <= '0';
      if format = "11" and op(2) = '0' then M2 <= '1'; end if; -- MVI, MVIH, MVIL
      
      M3 <= "01";
      if format = "00" and RI(13 downto 12) = "11" then M3 <= "00"; end if; -- JAL
      if format = "01" and op = "010" then M3 <= "10"; end if;              -- LOAD
      
      SelA <= RI(5 downto 3);
      if format = "11" and (op = "010" or op = "011") then SelA <= RI(13 downto 11); end if; -- MVIH, MVIL
      
      SelB <= RI(2 downto 0);

   end process;
end Architecture_1;