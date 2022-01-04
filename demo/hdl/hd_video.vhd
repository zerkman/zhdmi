-- hd_video.vhd - Simple video image generator
--
-- Copyright (c) 2021,2022 Francois Galea <fgalea at free.fr>
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hd_video is
	generic (
		-- 1280x720p60
		-- VFREQ is CLKFREQ/(HRES*VRES)
		-- CLKFREQ : integer := 74250000;
		VRES : integer := 750;
		VSWIDTH : integer := 5;
		VBORDER : integer := 12;
		VLINES : integer := 720;
		HRES : integer := 1650;
		HSWIDTH : integer := 40;
		HBORDER : integer := 192;
		HCOLUMNS : integer := 1280;
		HSPOLARITY : std_logic := '1';
		VSPOLARITY : std_logic := '1'
	);
	port (
		pclk : in std_logic;
		resetn : in std_logic;
		cfg : in std_logic;		-- 0:colour gradient 1:checkerboard pattern
		rgb : out std_logic_vector(23 downto 0);
		vsync : out std_logic;
		hsync : out std_logic;
		de : out std_logic
	);
end hd_video;

architecture behavioral of hd_video is

	signal xcnt 	: unsigned(11 downto 0);
	signal ycnt 	: unsigned(11 downto 0);
	signal r		: unsigned(7 downto 0);
	signal g		: unsigned(7 downto 0);
	signal b		: unsigned(7 downto 0);
	signal xcc		: unsigned(7 downto 0);
	signal ycc		: unsigned(7 downto 0);
	signal sdata1	: std_logic_vector(23 downto 0);
	signal sdata2	: std_logic_vector(23 downto 0);
	signal checkop	: unsigned(11 downto 0);
	signal checker	: std_logic;
	signal sde		: std_logic;
	signal scfg		: std_logic;

begin
	sdata1 <= std_logic_vector(r) & std_logic_vector(g) & std_logic_vector(b);
	checkop <= (xcnt-HBORDER) xor (ycnt-VBORDER);
	sdata2 <= (others => checkop(4));
	DE <= sde;

	process(scfg,sdata1,sdata2)
	begin
		if scfg = '0' then
			rgb <= sdata1;
		else
			rgb <= sdata2;
		end if;
	end process;

	process(xcnt)
	begin
		if xcnt<HSWIDTH and resetn = '1' then
			hsync <= HSPOLARITY;
		else
			hsync <= not HSPOLARITY;
		end if;
	end process;

	process(ycnt)
	begin
		if ycnt<VSWIDTH and resetn = '1' then
			VSYNC <= VSPOLARITY;
		else
			VSYNC <= not VSPOLARITY;
		end if;
	end process;

	process(PCLK)
	begin
		if rising_edge(PCLK) then
			if resetn = '0' then
				xcnt <= (others => '0');
				ycnt <= (others => '0');
				r <= (others => '1');
				g <= (others => '0');
				b <= (others => '0');
				xcc <= (others => '0');
				ycc <= (others => '0');
				sde <= '0';
				scfg <= cfg;
			else
				if xcnt = HRES-1 then
					xcnt <= (others => '0');
					if ycnt = VRES-1 then
						ycnt <= (others => '0');
						ycc <= (others => '0');
						r <= (others => '1');
						g <= (others => '0');
						b <= (others => '0');
						scfg <= cfg;
					else
						ycnt <= ycnt + 1;
					end if;
				else
					xcnt <= xcnt + 1;
				end if;
				if ycnt >= VBORDER and ycnt < VBORDER+VLINES then
					if xcnt >= HBORDER-1 and xcnt < HBORDER+HCOLUMNS-1 then
						sde <= '1';
						if xcc+16 >= (HCOLUMNS*16/256) then
							xcc <= xcc + 16 - (HCOLUMNS*16/256);
							g <= g + 1;
						else
							xcc <= xcc + 16;
						end if;
					else
						sde <= '0';
						if xcnt = HRES-1 then
							xcc <= (others => '0');
							if ycc+32 >= (VLINES*32/256) then
								ycc <= ycc + 32 - (VLINES*32/256);
								r <= r - 1;
								b <= b + 1;
							else
								ycc <= ycc + 32;
							end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;


end behavioral;
