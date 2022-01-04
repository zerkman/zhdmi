-- zhdmi_demo_top.vhd - Simple video image generator
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

library zhdmi;

entity zhdmi_demo_top is
	port (
		sys_clk : in std_logic;

		key : in std_logic_vector(1 downto 0);
		led : out std_logic_vector(1 downto 0);

		hdmi_tx_clk_n : out std_logic;
		hdmi_tx_clk_p : out std_logic;
		hdmi_tx_d_n : out std_logic_vector(2 downto 0);
		hdmi_tx_d_p : out std_logic_vector(2 downto 0)
	);
end zhdmi_demo_top;

architecture structure of zhdmi_demo_top is
	constant SAMPLE_FREQ : integer := 48000;

	-- NUM and DIV are integers such that 2*SAMPLE_FREQ*NUM/DIV = clk frequency
	constant NUM         : integer := 12375;
	constant DIV         : integer := 16;		-- 2*48000*12375/16 = 74.25 MHz
	constant WAVE_FREQ   : integer := 440;

	component clk_wiz_0 is
		port (
		clk_in1		: in std_logic;
		resetn		: in std_logic;
		clk_out1	: out std_logic;
		clk_out2	: out std_logic;
		locked		: out std_logic
		);
	end component;

	signal sys_rstn : std_logic;
	signal locked : std_logic;
	signal reset : std_logic;
	signal clk : std_logic;
	signal sclk : std_logic;
	signal vid_cfg : std_logic;
	signal vid_key_ff : std_logic;

	signal rgb : std_logic_vector(23 downto 0);
	signal vsync : std_logic;
	signal hsync : std_logic;
	signal de : std_logic;

	signal pcm : std_logic_vector(15 downto 0);
	signal pcm_clk : std_logic;
	signal audio_l : std_logic_vector(23 downto 0);
	signal audio_r : std_logic_vector(23 downto 0);
begin
	reset <= not locked;
	led <= '1' & not vid_cfg;
	sys_rstn <= key(0);
	audio_l <= pcm(13 downto 0) & "0000000000";
	audio_r <= pcm(13 downto 0) & "0000000000";

	process(clk)
	begin
		if rising_edge(clk) then
			if locked = '0' then
				vid_cfg <= '0';
				vid_key_ff <= '0';
			else
				vid_key_ff <= key(1);
				if key(1) = '0' and vid_key_ff = '1' then
					vid_cfg <= not vid_cfg;
				end if;
			end if;
		end if;
	end process;

	clkwiz:clk_wiz_0 port map(
		clk_in1		=> sys_clk,
		resetn		=> sys_rstn,
		clk_out1	=> clk,
		clk_out2	=> sclk,
		locked		=> locked
	);

	hdv:entity work.hd_video port map(
		pclk => clk,
		resetn => locked,
		cfg => vid_cfg,
		rgb => rgb,
		vsync => vsync,
		hsync => hsync,
		de => de
	);

	hdmi:entity zhdmi.hdmi_tx generic map (
		SAMPLE_FREQ => SAMPLE_FREQ
	) port map (
		clk => clk,
		sclk => sclk,
		reset => reset,
		rgb => rgb,
		vsync => vsync,
		hsync => hsync,
		de => de,
		audio_en => '1',
		audio_l => audio_l,
		audio_r => audio_r,
		audio_clk => pcm_clk,
		tx_clk_n => hdmi_tx_clk_n,
		tx_clk_p => hdmi_tx_clk_p,
		tx_d_n => hdmi_tx_d_n,
		tx_d_p => hdmi_tx_d_p
	);

	wave:entity work.sinewave_generator generic map (
			SAMPLE_FREQ => SAMPLE_FREQ,
			NUM => NUM,
			DIV => DIV,
			WAVE_FREQ => WAVE_FREQ
		)
		port map (
			clk => clk,
			reset => reset,

			pcm => pcm,
			pcm_clk => pcm_clk
		);

end structure;
