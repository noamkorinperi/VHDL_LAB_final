library ieee;
use ieee.std_logic_1164.all;

use work.mcu_memory_map_pkg.all;

entity gpio_peripheral is
    port (
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;
        address_i   : in  std_logic_vector(31 downto 0);
        write_data_i: in  std_logic_vector(31 downto 0);
        read_i      : in  std_logic;
        write_i     : in  std_logic;
        read_data_o : out std_logic_vector(31 downto 0);
        hit_o       : out std_logic;
        switches_i  : in  std_logic_vector(7 downto 0);
        ledr_o      : out std_logic_vector(7 downto 0);
        hex0_o      : out std_logic_vector(6 downto 0);
        hex1_o      : out std_logic_vector(6 downto 0);
        hex2_o      : out std_logic_vector(6 downto 0);
        hex3_o      : out std_logic_vector(6 downto 0);
        hex4_o      : out std_logic_vector(6 downto 0);
        hex5_o      : out std_logic_vector(6 downto 0)
    );
end entity;

architecture rtl of gpio_peripheral is
    type hex_register_array_t is array (0 to 5) of std_logic_vector(7 downto 0);
    signal ledr_q : std_logic_vector(7 downto 0) := (others => '0');
    signal hex_q  : hex_register_array_t := (others => (others => '0'));

    function seven_segment(value : std_logic_vector(3 downto 0))
        return std_logic_vector is
    begin
        -- DE10-Standard HEX displays are active-low, ordered g..a.
        case value is
            when x"0" => return "1000000";
            when x"1" => return "1111001";
            when x"2" => return "0100100";
            when x"3" => return "0110000";
            when x"4" => return "0011001";
            when x"5" => return "0010010";
            when x"6" => return "0000010";
            when x"7" => return "1111000";
            when x"8" => return "0000000";
            when x"9" => return "0010000";
            when x"A" => return "0001000";
            when x"B" => return "0000011";
            when x"C" => return "1000110";
            when x"D" => return "0100001";
            when x"E" => return "0000110";
            when others => return "0001110";
        end case;
    end function;

    function is_gpio_address(address : std_logic_vector(31 downto 0))
        return boolean is
    begin
        return address = C_PORT_LEDR_ADDR or address = C_PORT_HEX0_ADDR or
               address = C_PORT_HEX1_ADDR or address = C_PORT_HEX2_ADDR or
               address = C_PORT_HEX3_ADDR or address = C_PORT_HEX4_ADDR or
               address = C_PORT_HEX5_ADDR or address = C_PORT_SW_ADDR;
    end function;
begin
    process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            ledr_q <= (others => '0');
            hex_q  <= (others => (others => '0'));
        elsif rising_edge(clk_i) then
            if write_i = '1' then
                case address_i is
                    when C_PORT_LEDR_ADDR => ledr_q   <= write_data_i(7 downto 0);
                    when C_PORT_HEX0_ADDR => hex_q(0) <= write_data_i(7 downto 0);
                    when C_PORT_HEX1_ADDR => hex_q(1) <= write_data_i(7 downto 0);
                    when C_PORT_HEX2_ADDR => hex_q(2) <= write_data_i(7 downto 0);
                    when C_PORT_HEX3_ADDR => hex_q(3) <= write_data_i(7 downto 0);
                    when C_PORT_HEX4_ADDR => hex_q(4) <= write_data_i(7 downto 0);
                    when C_PORT_HEX5_ADDR => hex_q(5) <= write_data_i(7 downto 0);
                    when others => null;
                end case;
            end if;
        end if;
    end process;

    process (all)
    begin
        read_data_o <= (others => '0');
        if read_i = '1' then
            case address_i is
                when C_PORT_LEDR_ADDR => read_data_o(7 downto 0) <= ledr_q;
                when C_PORT_HEX0_ADDR => read_data_o(7 downto 0) <= hex_q(0);
                when C_PORT_HEX1_ADDR => read_data_o(7 downto 0) <= hex_q(1);
                when C_PORT_HEX2_ADDR => read_data_o(7 downto 0) <= hex_q(2);
                when C_PORT_HEX3_ADDR => read_data_o(7 downto 0) <= hex_q(3);
                when C_PORT_HEX4_ADDR => read_data_o(7 downto 0) <= hex_q(4);
                when C_PORT_HEX5_ADDR => read_data_o(7 downto 0) <= hex_q(5);
                when C_PORT_SW_ADDR   => read_data_o(7 downto 0) <= switches_i;
                when others => null;
            end case;
        end if;
    end process;

    hit_o  <= '1' when is_gpio_address(address_i) else '0';
    ledr_o <= ledr_q;
    hex0_o <= seven_segment(hex_q(0)(3 downto 0));
    hex1_o <= seven_segment(hex_q(1)(3 downto 0));
    hex2_o <= seven_segment(hex_q(2)(3 downto 0));
    hex3_o <= seven_segment(hex_q(3)(3 downto 0));
    hex4_o <= seven_segment(hex_q(4)(3 downto 0));
    hex5_o <= seven_segment(hex_q(5)(3 downto 0));
end architecture;
