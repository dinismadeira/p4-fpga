---------------------------------------------------------------------------------------------------
-- Project : P4 (Pequeno Processador Pedagógico com Pipeline)
-- File    : VGA_Interface.vhd
-- Author  : Dinis Madeira (dinismadeira@tecnico.ulisboa.pt)
-- Date    : 2018
---------------------------------------------------------------------------------------------------
-- Description: Text terminal for P4 with 45 lines by 80 columns.
--
-- The ASCII value of the character is retrieved from char_memory.
-- The color index is retrieved from color_memory.
-- The pixel value for the character is retrieved from font_memory.
-- The color value for the pixel is retrieved from palette_memory.
--
-- Based on P3's VGA_Interface.vhd, 07/12/2010, Vasco Brito
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity VGA_Interface is
   port (
      data                       : in std_logic_vector(15 downto 0); -- Character / Control Codes
      write                      : in std_logic;                     -- Write Character
      control                    : in std_logic;                     -- Control Commands
      color                      : in std_logic;                     -- Set Color
      clock_50MHz, clock, reset  : in std_logic;
      VGA_R                      : out std_logic_vector(3 downto 0); -- VGA Red Component
      VGA_G                      : out std_logic_vector(3 downto 0); -- VGA Green Component
      VGA_B                      : out std_logic_vector(3 downto 0); -- VGA Blue Component
      VGA_VS                     : out std_logic;                    -- VGA Vertical Sync Pulse
      VGA_HS                     : out std_logic                     -- VGA Horizontal Sync Pulse
   );
end VGA_Interface;

architecture Architecture_1 of VGA_Interface is
   -----------------------------------------------------------------------------------------------
   -- Constants
   -----------------------------------------------------------------------------------------------
   type vga_timing is record
      pixels_total : integer;  -- Total Pixels
      pixels_active : integer; -- Active Pixels
      front_porch : integer;   -- Front Porch
      sync_width : integer;    -- Sync Width
      polarity : std_logic;    -- Polarity
   end record vga_timing;
   
   type vga_timings is record
      horizontal : vga_timing;
      vertical   : vga_timing;
   end record vga_timings;
   
   type vga_resolutions is array (0 to 1) of vga_timings;
   
   constant VGA : vga_resolutions := (
      -- 1920 x 1080 @ 60Hz
      (
         horizontal => (
            pixels_total => 2200,
            pixels_active => 1920,
            front_porch => 88,
            sync_width => 44,
            polarity => '1'
         ),
         vertical => (
            pixels_total => 1125,
            pixels_active => 1080,
            front_porch => 4,
            sync_width => 5,
            polarity => '1'
         )
      ),
      -- 1280 x 960 @ 60Hz
      (
         horizontal => (
            pixels_total => 2568,
            pixels_active => 1920,
            front_porch => 120,
            sync_width => 204,
            polarity => '1'
         ),
         vertical => (
            pixels_total => 994,
            pixels_active => 960,
            front_porch => 1,
            sync_width => 3,
            polarity => '1'
         )
      )
         
   );
   
   -----------------------------------------------------------------------------------------------
   -- Component declarations
   -----------------------------------------------------------------------------------------------
   -- PLL to generate the required 148.75 Mhz clock
   component pll_vga
      port (
         areset      : in std_logic  := '0';
         inclk0      : in std_logic  := '0';
         c0          : out std_logic 
      );
   end component;
   
   -- Memory to store the characters being displayed.
   -- 28800 bits (8x80x45) (4 M9K)
   component char_memory
      port (
         address_a : in std_logic_vector (11 downto 0);
         address_b : in std_logic_vector (11 downto 0);
         clock_a   : in std_logic := '1';
         clock_b   : in std_logic;
         data_a    : in std_logic_vector (7 downto 0);
         data_b    : in std_logic_vector (7 downto 0);
         wren_a    : in std_logic := '0';
         wren_b    : in std_logic := '0';
         q_a       : out std_logic_vector (7 downto 0);
         q_b       : out std_logic_vector (7 downto 0)
      );
   end component;

   -- Memory to store the colour index for the characters being displayed.
   -- Most significative bits store the background color.
   -- 57600 bits (16x80x45) (8 M9K)
   component color_memory is
      port (
         wrclock, rdclock     : in std_logic;
         wren                 : in std_logic;
         data                 : in std_logic_vector(15 downto 0);
         wraddress, rdaddress : in std_logic_vector(11 downto 0);
         q                    : out std_logic_vector(15 downto 0)
      );
   end component;
   
   -- Memory where the character map is stored.
   -- 147456 bits (24x24x256)
   component font_memory is
      port (
         clock   : in std_logic;
         address : in std_logic_vector(17 downto 0);
         q       : out std_logic
      );
   end component;

   -- Memory where the colour palette is stored.
   -- 3071 bits (12x256)
   component palette_memory
      port (
         address  : in std_logic_vector (7 downto 0);
         clock    : in std_logic  := '1';
         q        : out std_logic_vector (11 downto 0)
      );
   end component;
   
   -----------------------------------------------------------------------------------------------
   -- Signal declarations
   -----------------------------------------------------------------------------------------------
   signal clock_VGA                                          : std_logic;
   signal HCounter, HCounter_1, HCounter_2, HCounter_3       : std_logic_vector(11 downto 0);
   signal VCounter, VCounter_1, VCounter_2, VCounter_3       : std_logic_vector(10 downto 0);
   signal HCounter_4, HCounter_5                             : std_logic_vector(11 downto 0);
   signal VCounter_4, VCounter_5                             : std_logic_vector(10 downto 0);
   signal ASCII                                              : std_logic_vector(7 downto 0);  -- Current ASCII value.
   signal font_address                                       : std_logic_vector(17 downto 0); -- Address to retrieve the pixel value for a given character.
   signal font_ASCII                                         : std_logic_vector(11 downto 0); -- ASCII component for font_address.
   signal font_position                                      : std_logic_vector(10 downto 0); -- Position component for font_address.
   signal pixel                                              : std_logic;                     -- Current pixel value.
   signal palette_address                                    : std_logic_vector(7 downto 0);  -- Current colour index.
   signal pixel_color                                        : std_logic_vector(11 downto 0); -- Current pixel colour.
   signal char_wrcolor                                       : std_logic_vector(15 downto 0) := x"00FF";
   signal char_rdcolor, char_rdcolor_1, char_rdcolor_2       : std_logic_vector(15 downto 0);
   signal char_rdcolor_3, char_rdcolor_4                     : std_logic_vector(15 downto 0);
   signal char_wraddress, char_rdaddress, clearing_start     : std_logic_vector(11 downto 0);
   signal clearing                                           : std_logic;
   signal char_reset                                         : std_logic;
   signal char_wrline, char_rdline                           : std_logic_vector(5 downto 0); -- 0-45
   signal char_wrcolumn, char_rdcolumn                       : std_logic_vector(6 downto 0); -- 0-80
   signal font_line, font_line_1, font_column, font_column_1 : std_logic_vector(4 downto 0); -- 0-24
   signal resolution                                         : integer range 0 to 1 := 0;    -- Resolution selection
begin

   -----------------------------------------------------------------------------------------------
   -- control
   -----------------------------------------------------------------------------------------------
   process (clock, reset) begin
      if reset = '1' then
         ---------------------------------------------------------------------------------------
         -- Reset
         ---------------------------------------------------------------------------------------
         char_reset    <= '1';
         char_wrline   <= (others => '0');
         char_wrcolumn <= (others => '0');
         char_wrcolor  <= x"00FF";
         resolution    <= 0;
      elsif rising_edge(clock) then
         ---------------------------------------------------------------------------------------
         -- Text Display
         ---------------------------------------------------------------------------------------
         --if control = '1' or write = '1' or color = '1' then
            char_reset <= '0';
         --end if;
         if control = '1' then
            if data(15 downto 8) = x"FF" then
               -- clear terminal
               if data(7 downto 0) = x"FF" then
                  --char_reset  <= '1';
                  char_wrline   <= (others => '0');
                  char_wrcolumn <= (others => '0');
               else
                  resolution <= conv_integer(data(0));
               end if;
            -- set position
            else
               char_wrline   <= data(13 downto 8);
               char_wrcolumn <= data(6 downto 0);
            end if;
         end if;
         -- write char
         if write = '1' then
            char_wrcolumn <= char_wrcolumn + 1;
            if char_wrcolumn = 79 then
               char_wrcolumn <= (others => '0');
               char_wrline   <= char_wrline + 1;
               if char_wrline = 44 then
                  char_wrline <= (others => '0');
               end if;
            end if;
         end if;
         -- set color
         if color = '1' then
            char_wrcolor <= data;
         end if;
      end if;
   end process;
   
   -----------------------------------------------------------------------------------------------
   -- reset controler
   -----------------------------------------------------------------------------------------------
-- process (clock_VGA) begin
--    if rising_edge(clock_VGA) then
--       if clearing = '1' and clearing_start = char_rdaddress then
--          clearing <= '0';
--       elsif char_reset = '1' then
--          clearing       <= '1';
--          clearing_start <= char_rdaddress;
--       end if;
--    end if;
-- end process;
   --StopP3 <= clearing;
   
   -----------------------------------------------------------------------------------------------
   -- Vertical and horizontal counters
   -----------------------------------------------------------------------------------------------
   -- PLL to Generate VGA Clock
   pll_vga_i : pll_vga
   port map(
      inclk0 => clock_50MHz,
      areset => reset,
      c0     => clock_VGA
   );

   process (reset, clock_VGA) begin
      if reset = '1' then
         HCounter    <= (others => '0');
         VCounter    <= (others => '0');
         font_line   <= (others => '0');
         char_rdline <= (others => '0');
      elsif rising_edge(clock_VGA) then

         -- NEW LINE -------------------------------------------------------
         if HCounter = VGA(resolution).horizontal.pixels_total - 1 then
            HCounter <= (others => '0');
            if font_line = 23 then
               font_line   <= (others => '0');
               char_rdline <= char_rdline + 1;
            else
               font_line <= font_line + 1;
            end if;

            -- NEW FRAME ---------------------------------------------------
            if VCounter = VGA(resolution).vertical.pixels_total - 1 then
               VCounter    <= (others => '0');
               font_line   <= (others => '0');
               char_rdline <= (others => '0');
            ----------------------------------------------------------------
            else
               VCounter <= VCounter + 1;
            end if;
            font_column   <= (others => '0');
            char_rdcolumn <= (others => '0');
         -------------------------------------------------------------------
         else
            -- COLUMN ---------------------------------------------------------
            HCounter <= HCounter + 1;
            if font_column = 23 then
               font_column   <= (others => '0');
               char_rdcolumn <= char_rdcolumn + 1;
            else
               font_column <= font_column + 1;
            end if;
         end if;

      end if;
   end process;
   
   -----------------------------------------------------------------------------------------------
   -- Retrieve ASCII and Colour from Char Memory and Colour Memory
   -----------------------------------------------------------------------------------------------
   char_memory_i : char_memory
   port map(
      clock_a   => clock,
      clock_b   => clock_VGA,
      wren_a    => write,
      wren_b    => '0',
      data_a    => data(7 downto 0),
      data_b    => (others => '0'),
      address_a => char_wraddress,
      address_b => char_rdaddress,
      q_b       => ASCII
   );

   color_memory_i : color_memory
   port map(
      wrclock   => clock,
      rdclock   => clock_VGA,
      wren      => write,
      data      => char_wrcolor,
      wraddress => char_wraddress,
      rdaddress => char_rdaddress,
      q         => char_rdcolor
   );

   -- char_line * 80 + char_column
   char_wraddress <= (char_wrline & "000000") + (char_wrline & "0000") + char_wrcolumn;
   char_rdaddress <= (char_rdline & "000000") + (char_rdline & "0000") + char_rdcolumn;


   -----------------------------------------------------------------------------------------------
   -- Retrieve Pixel From Font Memory
   -----------------------------------------------------------------------------------------------
   -- The pixel value for the ASCII character 
   
   font_memory_i : font_memory
   port map(
      clock   => clock_VGA,
      address => font_address,
      q       => pixel
   );
   
   process (reset, clock_VGA) begin
      if reset = '1' then
         font_ASCII     <= (others => '0');
         font_position  <= (others => '0');
      elsif rising_edge(clock_VGA) then
         font_ASCII <= '0' & (ASCII & "000") + ASCII;
         font_position <= ("00" & font_line_1 & "0000") + (font_line_1 & "000") + font_column_1;
      end if;
   end process;

   font_address <= (font_ASCII & "000000") + font_position;
   -----------------------------------------------------------------------------------------------
   -- Retrieve Pixel Colour from Palette Memory
   -----------------------------------------------------------------------------------------------
   palette_memory_i : palette_memory 
   port map(
		address   => palette_address,
		clock     => clock_VGA,
		q	       => pixel_color
	);
   
   palette_address <= char_rdcolor_4(7 downto 0) when pixel = '1' else char_rdcolor_4(15 downto 8);

   -----------------------------------------------------------------------------------------------
   -- Output VGA
   -----------------------------------------------------------------------------------------------
   process (reset, clock_VGA) 
      variable HS       : std_logic; -- Horizontal Sync Pulse
      variable HS_start : integer;   -- Horizontal Sync Pulse Start
      variable HS_end   : integer;   -- Horizontal Sync Pulse End
      variable VS       : std_logic; -- Vertical Sync Pulse
      variable VS_start : integer;   -- Vertical Sync Pulse Start
      variable VS_end   : integer;   -- Vertical Sync Pulse End
   begin
      if reset = '1' then
         VGA_HS <= '1';
         VGA_VS <= '1';
         VGA_R  <= (others => '0');
         VGA_G  <= (others => '0');
         VGA_B  <= (others => '0');
      elsif rising_edge(clock_VGA) then
         
         -- Horizontal Sync
         HS       := VGA(resolution).horizontal.polarity;
         HS_start := VGA(resolution).horizontal.pixels_active + VGA(resolution).horizontal.front_porch;
         HS_end   := HS_start + VGA(resolution).horizontal.sync_width;
         if HS_start < HCounter_5 and HCounter_5 < HS_end then
            VGA_HS <= not HS;
         else
            VGA_HS <= HS;
         end if;
         -- Vertical Sync
         VS       := VGA(resolution).vertical.polarity;
         VS_start := VGA(resolution).vertical.pixels_active + VGA(resolution).vertical.front_porch;
         VS_end   := VS_start + VGA(resolution).vertical.sync_width;
         if VS_start < VCounter_5 and VCounter_5 < VS_end then
            VGA_VS <= not VS;
         else
            VGA_VS <= VS;
         end if;
         -- Video Output
         if HCounter_5 < VGA(resolution).horizontal.pixels_active and VCounter_5 < VGA(resolution).vertical.pixels_active then
            VGA_R <= pixel_color(11 downto 8);
            VGA_G <= pixel_color(7 downto 4);
            VGA_B <= pixel_color(3 downto 0);
         else
            VGA_R <= (others => '0');
            VGA_G <= (others => '0');
            VGA_B <= (others => '0');
         end if;
      end if;
   end process;
   
   -----------------------------------------------------------------------------------------------
   -- Pipeline
   -----------------------------------------------------------------------------------------------
   process (reset, clock_VGA) begin
      if reset = '1' then
         HCounter_1     <= (others => '0');
         VCounter_1     <= (others => '0');
         HCounter_2     <= (others => '0');
         VCounter_2     <= (others => '0');
         HCounter_3     <= (others => '0');
         VCounter_3     <= (others => '0');
         HCounter_4     <= (others => '0');
         VCounter_4     <= (others => '0');
         HCounter_5     <= (others => '0');
         VCounter_5     <= (others => '0');
         font_line_1    <= (others => '0');
         font_column_1  <= (others => '0');
         char_rdcolor_1 <= (others => '0');
         char_rdcolor_2 <= (others => '0');
         char_rdcolor_3 <= (others => '0');
         char_rdcolor_4 <= (others => '0');
      elsif rising_edge(clock_VGA) then
         HCounter_1     <= HCounter;
         VCounter_1     <= VCounter;
         HCounter_2     <= HCounter_1;
         VCounter_2     <= VCounter_1;
         HCounter_3     <= HCounter_2;
         VCounter_3     <= VCounter_2;
         HCounter_4     <= HCounter_3;
         VCounter_4     <= VCounter_3;
         HCounter_5     <= HCounter_4;
         VCounter_5     <= VCounter_4;
         font_line_1    <= font_line;
         font_column_1  <= font_column;
         char_rdcolor_1 <= char_rdcolor;
         char_rdcolor_2 <= char_rdcolor_1;
         char_rdcolor_3 <= char_rdcolor_2;
         char_rdcolor_4 <= char_rdcolor_3;
      end if;
   end process;
   
end Architecture_1;