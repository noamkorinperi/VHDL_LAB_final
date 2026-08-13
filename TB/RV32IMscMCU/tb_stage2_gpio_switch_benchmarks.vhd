library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use work.mcu_memory_map_pkg.all;

entity tb_stage2_gpio_switch_benchmarks is end entity;

architecture sim of tb_stage2_gpio_switch_benchmarks is
    signal sysclk, divclk, reset : std_logic := '0';
    signal switches : std_logic_vector(7 downto 0) := (others => '0');
    signal ledr1, ledr2 : std_logic_vector(7 downto 0);
    signal addr1, data1, addr2, data2 : std_logic_vector(31 downto 0);
    signal write1, write2 : std_logic;
begin
    sysclk <= not sysclk after 20 ns;
    divclk <= not divclk after 10 ns;

    gpio_test1 : entity work.mcu_sim_harness
        generic map (
            ITCM_INIT_FILE => "stage2/test1/ITCM.hex",
            DTCM_INIT_FILE => "stage2/test1/DTCM.hex"
        )
        port map (
            sys_clk_i => sysclk, div_clk_i => divclk, reset_i => reset,
            switches_i => switches, ledr_o => ledr1,
            hex0_o => open, hex1_o => open, hex2_o => open,
            hex3_o => open, hex4_o => open, hex5_o => open,
            pc_o => open, instruction_o => open, regwrite_o => open, memwrite_o => open,
            read_data1_o => open, read_data2_o => open, alu_result_o => open,
            bus_addr_o => addr1, bus_wdata_o => data1, bus_read_o => open,
            bus_write_o => write1, div_busy_o => open, div_done_o => open,
            div_result_o => open
        );

    gpio_test2 : entity work.mcu_sim_harness
        generic map (
            ITCM_INIT_FILE => "stage2/test2/ITCM.hex",
            DTCM_INIT_FILE => "stage2/test2/DTCM.hex"
        )
        port map (
            sys_clk_i => sysclk, div_clk_i => divclk, reset_i => reset,
            switches_i => switches, ledr_o => ledr2,
            hex0_o => open, hex1_o => open, hex2_o => open,
            hex3_o => open, hex4_o => open, hex5_o => open,
            pc_o => open, instruction_o => open, regwrite_o => open, memwrite_o => open,
            read_data1_o => open, read_data2_o => open, alu_result_o => open,
            bus_addr_o => addr2, bus_wdata_o => data2, bus_read_o => open,
            bus_write_o => write2, div_busy_o => open, div_done_o => open,
            div_result_o => open
        );

    stimulus : process
        variable test1_led, test1_hex, test2_led, test2_hex : integer := 0;
    begin
        reset <= '1'; wait for 160 ns; reset <= '0';
        -- SW0 requests increment+print in both supplied benchmarks.
        switches <= x"01";
        for cycle in 0 to 1000 loop
            -- Sample the bus values that the GPIO registers consume on this
            -- edge.  A post-edge delay would observe the next instruction.
            wait until rising_edge(sysclk);
            if write1 = '1' then
                if addr1 = C_PORT_LEDR_ADDR and data1(7 downto 0) = x"01" then
                    test1_led := test1_led + 1;
                elsif addr1 = C_PORT_HEX0_ADDR or addr1 = C_PORT_HEX1_ADDR or
                      addr1 = C_PORT_HEX2_ADDR or addr1 = C_PORT_HEX3_ADDR or
                      addr1 = C_PORT_HEX4_ADDR or addr1 = C_PORT_HEX5_ADDR then
                    test1_hex := test1_hex + 1;
                end if;
            end if;
            if write2 = '1' then
                if addr2 = C_PORT_LEDR_ADDR and data2(7 downto 0) = x"01" then
                    test2_led := test2_led + 1;
                elsif addr2 = C_PORT_HEX0_ADDR or addr2 = C_PORT_HEX1_ADDR or
                      addr2 = C_PORT_HEX2_ADDR or addr2 = C_PORT_HEX3_ADDR or
                      addr2 = C_PORT_HEX4_ADDR or addr2 = C_PORT_HEX5_ADDR then
                    test2_hex := test2_hex + 1;
                end if;
            end if;
            exit when test1_led > 0 and test1_hex >= 6 and test2_led > 0 and test2_hex >= 6;
        end loop;
        wait for 2 ns; -- allow the committed LEDR writes to become observable
        assert test1_led > 0 and test1_hex >= 6 and ledr1 = x"01"
            report "Stage 2: GPIO/test1 did not react correctly to SW0" severity failure;
        assert test2_led > 0 and test2_hex >= 6 and ledr2 = x"01"
            report "Stage 2: GPIO/test2 did not react correctly to SW0" severity failure;
        report "STAGE 2 GPIO TEST1/TEST2 INTEGRATION PASS" severity note;
        stop;
    end process;
end architecture;
