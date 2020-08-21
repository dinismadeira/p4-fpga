library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
   port
   (
      addr  : in natural range 0 to 32767;
      clock : in std_logic;
      q     : out std_logic_vector(15 downto 0)
   );
   
end entity;

architecture Architecture_1 of memory is

   -- Build a 2-D array type for the RAM
   subtype word_t is std_logic_vector(15 downto 0);
   type memory_t is array(64 downto 0) of word_t;
   
   -- Declare the RAM signal.
   signal ram     : memory_t;
   signal data    : std_logic_vector(15 downto 0);
	signal counter : unsigned(14 downto 0) := (others => '0');
   
   component program_memory
      port (
         address : in  std_logic_vector(14 downto 0);
         clock   : in  std_logic := '1';
         q       : out std_logic_vector(15 downto 0)
      );
   end component;

begin
   program_memory_i : program_memory
   port map(
      address => std_logic_vector(counter),
      clock   => clock,
      q       => data
   );

   process(clock)
   begin
      if rising_edge(clock) then
            ram(to_integer(counter)) <= data;
				counter <= counter + 1;
      end if;
   end process;
   
   q <= ram(addr);
   
end Architecture_1;
