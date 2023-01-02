-- sinewave_generator.vhd - Simple sine wave generator
--
-- Copyright (c) 2021-2023 Francois Galea <fgalea at free.fr>
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

entity sinewave_generator is
	generic (
		SAMPLE_FREQ : integer := 48000;
		-- NUM and DIV are integers such that 2*SAMPLE_FREQ*NUM/DIV = clk frequency
		NUM : integer := 1125;
		DIV : integer := 4;		-- 2*48000*1125/4 = 27 MHz
		WAVE_FREQ : integer := 440
	);
	port (
		clk      : in std_logic;	-- pixel clock
		reset    : in std_logic;

		pcm      : out std_logic_vector(15 downto 0);
		pcm_clk  : out std_logic
	);
end sinewave_generator;

architecture rtl of sinewave_generator is
	constant LEN_SINTBL  : natural := 4096;
	constant BITS_SINTBL : natural := 13;
	type sintbl_t is array(0 to LEN_SINTBL-1) of signed(BITS_SINTBL downto 0);
	function gen_sintbl return sintbl_t is
		use ieee.math_real.all;
		variable mem : sintbl_t;
		variable s   : integer;
	begin
		for i in 0 to LEN_SINTBL-1 loop
			s := integer(sin(real(i) * (2.0*math_pi/real(LEN_SINTBL))) * real(2**BITS_SINTBL));
			if s >= 2**BITS_SINTBL then
				s := 2**BITS_SINTBL - 1;
			end if;
			mem(i) := to_signed(s,BITS_SINTBL+1);
		end loop;
		return mem;
	end function;
	constant sintbl : sintbl_t := gen_sintbl;

	signal aclk       : std_logic;

	signal aclk_cnt   : unsigned(15 downto 0);
	signal wave_cnt   : unsigned(23 downto 0);	-- 24 bit = 4096*4096
	constant wave_inc : integer := integer(real(WAVE_FREQ)*real(LEN_SINTBL)*4096.0/real(SAMPLE_FREQ));
begin
	pcm_clk <= aclk;

	-- generate audio signal
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				aclk <= '0';
				aclk_cnt <= (others => '0');
				pcm <= x"0000";
				wave_cnt <= (others => '0');
			else
				if aclk_cnt + DIV < NUM then
					aclk_cnt <= aclk_cnt + DIV;
				else
					aclk_cnt <= aclk_cnt + DIV - NUM;
					aclk <= not aclk;
					if aclk = '0' then
						wave_cnt <= wave_cnt + wave_inc;
						pcm <= std_logic_vector(resize(sintbl(to_integer(wave_cnt(23 downto 12))),16));
					end if;
				end if;
			end if;
		end if;
	end process;


end architecture;
