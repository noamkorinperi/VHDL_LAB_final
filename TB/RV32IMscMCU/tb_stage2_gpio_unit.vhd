library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use work.mcu_memory_map_pkg.all;

entity tb_stage2_gpio_unit is end entity;

architecture sim of tb_stage2_gpio_unit is
    constant CLK_PERIOD : time := 40 ns;
    signal clk, reset, read_enable, write_enable, hit : std_logic := '0';
    signal address, write_data, read_data : std_logic_vector(31 downto 0) := (others => '0');
    signal switches, ledr : std_logic_vector(7 downto 0) := (others => '0');
    signal hex0, hex1, hex2, hex3, hex4, hex5 : std_logic_vector(6 downto 0);
begin
    clk <= not clk after CLK_PERIOD/2;
    dut : entity work.gpio_peripheral
        port map (
            clk_i => clk, reset_i => reset, address_i => address,
            write_data_i => write_data, read_i => read_enable, write_i => write_enable,
            read_data_o => read_data, hit_o => hit, switches_i => switches,
            ledr_o => ledr, hex0_o => hex0, hex1_o => hex1, hex2_o => hex2,
            hex3_o => hex3, hex4_o => hex4, hex5_o => hex5
        );

    stimulus : process
        procedure write_register(constant addr : std_logic_vector(31 downto 0);
                                 constant data : std_logic_vector(31 downto 0)) is
        begin
            address <= addr; write_data <= data; write_enable <= '1';
            wait until rising_edge(clk); wait for 1 ns; write_enable <= '0';
        end procedure;
    begin
        reset <= '1'; wait for 2*CLK_PERIOD; reset <= '0';
        assert ledr = x"00" report "Stage 2: reset did not clear LEDR" severity failure;

        write_register(C_PORT_LEDR_ADDR, x"123456A5");
        assert ledr = x"A5" report "Stage 2: LEDR low-byte write failed" severity failure;

        write_register(C_PORT_HEX0_ADDR, x"0000000A");
        write_register(C_PORT_HEX1_ADDR, x"00000005");
        write_register(C_PORT_HEX5_ADDR, x"0000000F");
        assert hex0 = "0001000" report "Stage 2: HEX0 encoding for A failed" severity failure;
        assert hex1 = "0010010" report "Stage 2: HEX1 unaligned address/encoding failed" severity failure;
        assert hex5 = "0001110" report "Stage 2: HEX5 encoding for F failed" severity failure;

        switches <= x"3C"; address <= C_PORT_SW_ADDR; read_enable <= '1'; wait for 1 ns;
        assert hit = '1' and read_data = x"0000003C"
            report "Stage 2: switch read or zero extension failed" severity failure;

        address <= x"00002030"; wait for 1 ns;
        assert hit = '0' report "Stage 2: unmapped address falsely claimed" severity failure;
        report "STAGE 2 GPIO UNIT PASS" severity note;
        stop;
    end process;
end architecture;
