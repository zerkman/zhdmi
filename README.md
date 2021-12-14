# zhdmi - A complete HDMI transmitter implementation in VHDL

This is a VHDL implementation of a HDMI transmitter with complete features:
- Auxiliary Video Information (AVI) Infoframe.
- Source Product Description (SPD) Infoframe.
- Audio: 24-bit, only stereo for now, but can easily be improved. Can be deactivated.

This transmitter takes a typical VGA-like group of signals as input (pixel clock,
vsync, hsync, display enable, RGB data), as well as stereo digital audio at any
standard sample rate.
It produces a stream of HDMI data to be redirected to a HDMI output connector.

zhdmi is distributed under the GNU General Public License v3 licence.
See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for more details.

## Usage

See the `demo` directory for sample projects making use of this HDMI transmitter.
