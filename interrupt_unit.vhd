---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : interrupt_unit.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Attends external and software interrupts.
--
-- When an interrupt must be attended, this unit will save current PC and load PC with the address
-- of the interrupt routine, the interrupt enable flag is saved and disabled, the state register is
-- saved and an interrupt acknowledgment signal is activated.
-- To return from an interrupt this unit will load PC, the interrupt enable flag, and the state
-- register with the previously saved values.
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity interrupt_unit is
   port (
      -- Inputs
      int         : in  std_logic;                     -- External interrupt flag
      intv        : in  std_logic_vector(3 downto 0);  -- Interrupt source
      Ld_in       : in  std_logic;                     -- Ld signal from branch unit (branch flag)
      RI_in       : in  std_logic_vector(15 downto 0); -- Instruction Register
      PC          : in  std_logic_vector(15 downto 0); -- Program Counter
      clock       : in  std_logic;                     -- System Clock
      reset       : in  std_logic;                     -- Reset
      -- Outputs
      IAK         : out std_logic;                     -- Interrupt Acknowledgment Signal
      store_state : out std_logic;                     -- Signal to backup the state register
      load_state  : out std_logic;                     -- Signal to restore the state register
      RI_out      : out std_logic_vector(15 downto 0); -- Instruction Register (updated)
      Ld          : out std_logic;                     -- Load signal sent to PC
      addr        : out std_logic_vector(15 downto 0)  -- New value for PC
   );
end interrupt_unit;

architecture Architecture_1 of interrupt_unit is
   -- Hard Interrupts States:
	type states is (
      idle_state, -- Wait for an interrupt
      int_state,  -- Load PC with the interrupt routine address
      delay_state -- Inject NOP as a delay slot
   );
   
	signal state : states := idle_state;
   signal EPC   : std_logic_vector(15 downto 0); -- Address to return from interrupt
   signal E     : std_logic;                     -- Interrupt enable flag
   signal EE    : std_logic;                     -- Interrupt enable flag value before interrupt
   signal int_d : std_logic;                     -- Flag activated after an int instruction
   signal rti_d : std_logic;                     -- Flag activated after an rti instruction

   -- Compute the routine address for a interrupt source
   function routine_addr (intv : in std_logic_vector) return std_logic_vector is
   begin return x"7F" & intv; 
   end function routine_addr;
begin

   -- Current instruction is replaced with a NOP while attending an external interrupt
   RI_out <= RI_in when state = idle_state else (others => '0');
   
   process (intv, RI_in, state, EPC) begin
      -- Default Values
      IAK <= '0';
      store_state <= '0';
      Ld <= '0';
      addr <= (others => '0');
      
      -- External Interrupt
      if state = int_state then
         Ld <= '1';
         addr <= routine_addr(intv & x"0");
         store_state <= '1';
         IAK <= '1';
         
      -- Instructions
      elsif RI_in(15 downto 14) = "01" then
         case RI_in(10 downto 8) is
         
            -- RTI
            when "110" =>
               Ld <= '1';
               addr <= EPC;
               
            -- INT
            when "111" =>
               Ld <= '1';
               addr <= routine_addr(RI_in(7 downto 0));
               store_state <= '1';
               
            when others => null;
         end case;
      end if;
   end process;
   
   process (clock, reset) begin
      if reset = '1' then
         load_state <= '0';
         EPC <= (others => '0');
         E <= '0';
         EE <= '0';
         int_d <= '0';
         rti_d <= '0';
      elsif rising_edge(clock) then
         -- Default Values
         load_state <= '0';
         int_d <= '0';
         rti_d <= '0';
         
         -- State transitions
         if state = int_state then 
            EPC <= PC; -- Set EPC with PC's value when the interrupt was attended
            state <= delay_state;
         elsif state = delay_state then state <= idle_state;
         
         -- External Interrupt
         -- Int signal indicates a pending interrupt
         -- Interrupt enable flag must be activated
         -- Interrupts can't be attended following a jump because it will be a delay slot and the jump would be lost
         elsif int = '1' and E = '1' and Ld_in = '0' then
            state <= int_state; -- Set state
            EE <= E;            -- Save interrupt enable flag
            E <= '0';           -- Disable interrupts

         else 
            if RI_in(15 downto 14) = "01" then
               case RI_in(10 downto 8) is
                  -- ENI
                  when "100" => E <= '1'; -- Enable interrupts
                  -- DSI
                  when "101" => E <= '0'; -- Disable interrupts
                  -- RTI
                  when "110" => 
                     E <= EE;      -- Restore interrupt enable flag
                     rti_d <= '1';
                  -- INT
                  when "111" =>
                     EE <= E;      -- Save interrupt enable flag
                     E <= '0';     -- Disable interrupts
                     int_d <= '1';
                  when others => null;
               end case;
            end if;
            
            -- Set EPC to the address of the instruction following the delay slot instruction
            if int_d = '1' then EPC <= PC + 1; end if;
            
            -- Restore the state register after the RTI's delay slot
            if rti_d = '1' then load_state <= '1'; end if;
         end if;
      end if;
   end process;
end Architecture_1;