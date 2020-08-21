---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : p4_control.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Control P4 by writing values to a memory instance.
--
-- Every clock cycle the memory is written with:
-- 0000 PPPP PPPP PPPP PPPP IIII IIII IIII IIII - P = Program Counter, I - Current Instruction
--
-- The values that can be written are:
-- 1000 0000 0000 0000 0000 0000 0000 0000 0000 - Start
-- 1000 0000 0000 0000 0000 0000 0000 0000 0001 - Stop
-- 1000 0000 0000 0000 0000 0000 0000 0000 0010 - Step
-- 0100 0000 0000 0000 0000 IIII IIII IIII IIII - Step with instruction I
-- 0010 0000 0000 0000 0000 0000 0000 0000 0000 - Reset
--
-- TODO: breakpoints
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity p4_control is
   port (
      -- Inputs
      PC_in     : in  std_logic_vector(15 downto 0); -- Program Counter
      RI_in     : in  std_logic_vector(15 downto 0); -- Instruction Register
      clock     : in  std_logic;                     -- System Clock
      reset     : in  std_logic;                     -- Reset
      -- Outputs
      clock_en  : out std_logic;                     -- Signal to restore the state register
      reset_out : out std_logic;                     -- Reset Out
      PC_out    : out std_logic_vector(15 downto 0); -- Program Counter (delayed)
      RI_out    : out std_logic_vector(15 downto 0)  -- Instruction Register (updated)
   );
end p4_control;

architecture Architecture_1 of p4_control is
   signal data       : std_logic_vector(35 downto 0); -- Control Memory Data Input
   signal q          : std_logic_vector(35 downto 0); -- Control Memory Data Output
   signal stop       : std_logic;                     -- Stop
   signal step       : std_logic;                     -- Step
   signal step_RI    : std_logic;                     -- Step width instruction
   signal RI         : std_logic_vector(15 downto 0); -- RI Bypass
   signal reset_flag : std_logic;
   
   
   component control_memory
      port
      (
         address : in std_logic_vector(0 downto 0);
         clock   : in std_logic;
         data    : in std_logic_vector(35 downto 0);
         wren    : in std_logic;
         q       : out std_logic_vector(35 downto 0)
      );
   end component;
   
begin
   control_memory_i : control_memory
   port map(
      address => "0",
      clock   => clock,
      data    => data,
      wren    => '1',
      q       => q
   );
   
   data(35 downto 32) <= (others => '0');
   data(31 downto 16) <= PC_in;
   data(15 downto 0)  <= RI_in;
   clock_en  <= (not stop or step) and not step_RI;
   RI_out    <= RI_in when clock_en = '1' else RI;
   reset_out <= reset or reset_flag;
   
   process (clock) begin
		if rising_edge(clock) then
         -- Default Values
         step       <= '0';
         step_RI    <= '0';
         reset_flag <= '0';
         RI         <= (others => '0');
			PC_out     <= PC_in;
         -- Reset
         if q(33) = '1' then reset_flag <= '1'; end if; 
         -- Step with Instruction
         if q(34) = '1' then
            RI <= q(15 downto 0);
            step_RI <= '1';
         elsif q(35) = '1' then
            -- Step
            if q(1) = '1' then step <= '1';
            -- Start/Stop
            else stop <= q(0); end if;
         end if;
      end if;
   end process;

end Architecture_1;