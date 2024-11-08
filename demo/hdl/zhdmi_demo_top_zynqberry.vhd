-- zhdmi_demo_top.vhd - Simple video image generator
--
-- Copyright (c) 2021-2024 Francois Galea <fgalea at free.fr>
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
		FIXED_IO_mio : inout std_logic_vector(31 downto 0);
		FIXED_IO_ps_clk : inout std_logic;
		FIXED_IO_ps_porb : inout std_logic;
		FIXED_IO_ps_srstb : inout std_logic;

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

	component ps_zynqberry is
		port (
			FCLK_CLK0		: out std_logic;
			FCLK_RESET0_N	: out std_logic;
			MIO				: inout std_logic_vector(31 downto 0);
			PS_SRSTB		: inout std_logic;
			PS_CLK			: inout std_logic;
			PS_PORB			: inout std_logic
		);
	end component;

	signal sys_clk : std_logic;
	signal sys_rstn : std_logic;
	signal locked : std_logic;
	signal reset : std_logic;
	signal clk : std_logic;
	signal sclk : std_logic;
	signal vid_cfg : std_logic;

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
	audio_l <= pcm(13 downto 0) & "0000000000";
	audio_r <= pcm(13 downto 0) & "0000000000";
	vid_cfg <= '0';

	ps:ps_zynqberry port map (
		FCLK_CLK0 => sys_clk,
		FCLK_RESET0_N => sys_rstn,
		MIO => FIXED_IO_mio,
		PS_SRSTB => FIXED_IO_ps_srstb,
		PS_CLK => FIXED_IO_ps_clk,
		PS_PORB => FIXED_IO_ps_porb
	);

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
		SAMPLE_FREQ => SAMPLE_FREQ,
		INVERTED_TX => "1001"
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
