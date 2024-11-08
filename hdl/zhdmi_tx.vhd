-- zhdmi_tx.vhd - HDMI transmitter
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
use ieee.numeric_std.all;

library zhdmi;

entity hdmi_tx is
	generic (
		SAMPLE_FREQ : integer := 48000;
		-- Invert flags for the different TMDS channels.
		-- Set a channel bit to 1 if the p and n outputs for that channel are swapped.
		INVERTED_TX : std_logic_vector(3 downto 0) := "0000"
	);
	port (
		clk      : in std_logic;	-- pixel clock
		sclk     : in std_logic;	-- serial clock = 5x clk frequency
		reset    : in std_logic;
		rgb      : in std_logic_vector(23 downto 0);	-- pixel data
		vsync    : in std_logic;
		hsync    : in std_logic;
		de       : in std_logic;

		audio_en     : in std_logic;		-- audio enable
		audio_l      : in std_logic_vector(23 downto 0);	-- left channel
		audio_r      : in std_logic_vector(23 downto 0);	-- right channel
		audio_clk    : in std_logic;		-- audio sample clock (coherent with clk)

		tx_clk_n : out std_logic;	-- TMDS clock channel
		tx_clk_p : out std_logic;
		tx_d_n   : out std_logic_vector(2 downto 0);	-- TMDS data channels
		tx_d_p   : out std_logic_vector(2 downto 0)		-- 0:blue, 1:green, 2:red
	);
end hdmi_tx;


architecture rtl of hdmi_tx is
	type tmds_d_t is array(0 to 2) of std_logic_vector(9 downto 0);
	signal tmds_d : tmds_d_t;
	signal enc_d  : tmds_d_t;
	signal clk_d  : std_logic_vector(9 downto 0);

	signal data : std_logic_vector(23 downto 0);
	signal sde  : std_logic;
	signal sae  : std_logic;
	signal vgb  : std_logic;
	signal dgb  : std_logic;

begin
	tmds_d(0) <= enc_d(0) when INVERTED_TX(0) = '0' else not enc_d(0);
	tmds_d(1) <= enc_d(1) when INVERTED_TX(1) = '0' else not enc_d(1);
	tmds_d(2) <= enc_d(2) when INVERTED_TX(2) = '0' else not enc_d(2);
	clk_d <= "1111100000" when INVERTED_TX(3) = '0' else "0000011111";

	signaler: entity zhdmi.signaling generic map (
			SAMPLE_FREQ => SAMPLE_FREQ
		)
		port map (
			clk => clk,
			reset => reset,
			rgb => rgb,
			vsync => vsync,
			hsync => hsync,
			ide => de,
			audio_en => audio_en,
			audio_l => audio_l,
			audio_r => audio_r,
			audio_clk => audio_clk,
			data => data,
			de => sde,
			ae => sae,
			vgb => vgb,
			dgb => dgb
		);

	-- send the clock through a serializer to keep in sync with the channels
	serial_clk: entity zhdmi.tmds_serializer port map (
		clk => clk,
		sclk => sclk,
		reset => reset,
		tmds_d => clk_d,
		tx_d_n => tx_clk_n,
		tx_d_p => tx_clk_p
	);

	chn: for i in 0 to 2 generate
		encoder: entity zhdmi.tmds_encoder generic map (
			CHN => i
		) port map (
			clk => clk,
			reset => reset,
			data => data(i*8+7 downto i*8),
			de => sde,
			ae => sae,
			vgb => vgb,
			dgb => dgb,
			tmds_d => enc_d(i)
		);

		serial: entity zhdmi.tmds_serializer port map (
			clk => clk,
			sclk => sclk,
			reset => reset,
			tmds_d => tmds_d(i),
			tx_d_n => tx_d_n(i),
			tx_d_p => tx_d_p(i)
		);
	end generate chn;

end architecture;
