library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mcu_memory_map_pkg is
    subtype word_t is std_logic_vector(31 downto 0);
    subtype address_t is std_logic_vector(31 downto 0);

    -- The document names the final word base at 0x1FFC/0x3FFC.  The
    -- corresponding decoder regions include the four bytes occupied by it.
    constant C_DTCM_BASE_ADDR       : address_t := x"00000000";
    constant C_DTCM_LAST_WORD_ADDR  : address_t := x"00001FFC";
    constant C_DTCM_DECODE_END_ADDR : address_t := x"00001FFF";
    constant C_MMIO_BASE_ADDR       : address_t := x"00002000";
    constant C_MMIO_LAST_WORD_ADDR  : address_t := x"00003FFC";
    constant C_MMIO_DECODE_END_ADDR : address_t := x"00003FFF";

    constant C_PORT_LEDR_ADDR : address_t := x"00002000";
    constant C_PORT_HEX0_ADDR : address_t := x"00002004";
    constant C_PORT_HEX1_ADDR : address_t := x"00002005";
    constant C_PORT_HEX2_ADDR : address_t := x"00002008";
    constant C_PORT_HEX3_ADDR : address_t := x"00002009";
    constant C_PORT_HEX4_ADDR : address_t := x"0000200C";
    constant C_PORT_HEX5_ADDR : address_t := x"0000200D";
    constant C_PORT_SW_ADDR   : address_t := x"00002010";
    constant C_PORT_PB_ADDR   : address_t := x"00002014";

    -- Reserved for the optional UART peripheral.
    constant C_UART_CTL_ADDR  : address_t := x"00002018";
    constant C_UART_RXBF_ADDR : address_t := x"00002019";
    constant C_UART_TXBF_ADDR : address_t := x"0000201A";

    constant C_BTCTL1_ADDR  : address_t := x"0000201C";
    constant C_BTCTL2_ADDR  : address_t := x"0000201D";
    constant C_BTCMPR0_ADDR : address_t := x"00002020";
    constant C_BTCMPR1_ADDR : address_t := x"00002024";
    constant C_BTCAPR_ADDR  : address_t := x"00002028";

    constant C_IE_ADDR   : address_t := x"0000202C";
    constant C_IFG_ADDR  : address_t := x"0000202D";
    constant C_TYPE_ADDR : address_t := x"0000202E";

    constant C_IRQ_TYPE_RESET : std_logic_vector(7 downto 0) := x"00";
    constant C_IRQ_TYPE_TIMER : std_logic_vector(7 downto 0) := x"10";
    constant C_IRQ_TYPE_KEY1  : std_logic_vector(7 downto 0) := x"14";
    constant C_IRQ_TYPE_KEY2  : std_logic_vector(7 downto 0) := x"18";
    constant C_IRQ_TYPE_KEY3  : std_logic_vector(7 downto 0) := x"1C";

    constant C_IRQ_RX_BIT     : natural := 0;
    constant C_IRQ_TX_BIT     : natural := 1;
    constant C_IRQ_TIMER_BIT  : natural := 2;
    constant C_IRQ_KEY1_BIT   : natural := 3;
    constant C_IRQ_KEY2_BIT   : natural := 4;
    constant C_IRQ_KEY3_BIT   : natural := 5;

    function is_dtcm_address(address : address_t) return boolean;
    function is_mmio_address(address : address_t) return boolean;
end package;

package body mcu_memory_map_pkg is
    function is_dtcm_address(address : address_t) return boolean is
    begin
        return unsigned(address) >= unsigned(C_DTCM_BASE_ADDR) and
               unsigned(address) <= unsigned(C_DTCM_DECODE_END_ADDR);
    end function;

    function is_mmio_address(address : address_t) return boolean is
    begin
        return unsigned(address) >= unsigned(C_MMIO_BASE_ADDR) and
               unsigned(address) <= unsigned(C_MMIO_DECODE_END_ADDR);
    end function;
end package body;
