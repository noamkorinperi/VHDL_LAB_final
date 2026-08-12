library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use work.cond_compilation_package.all;
use work.mcu_memory_map_pkg.all;

entity tb_stage2_gpio_integration is end entity;

architecture sim of tb_stage2_gpio_integration is
    constant SYS_PERIOD : time := 40 ns;
    signal sysclk, divclk, reset : std_logic := '0';
    signal ledr : std_logic_vector(7 downto 0);
    signal bus_addr, bus_wdata : std_logic_vector(31 downto 0);
    signal bus_write : std_logic;
begin
    sysclk <= not sysclk after SYS_PERIOD/2;
    divclk <= not divclk after SYS_PERIOD/4;
    dut : entity work.mcu_sim_harness
        generic map (ITCM_INIT_FILE => "stage2/ITCM.hex", DTCM_INIT_FILE => "stage2/DTCM.hex")
        port map (
            sys_clk_i => sysclk, div_clk_i => divclk, reset_i => reset,
            switches_i => x"00", ledr_o => ledr,
            hex0_o => open, hex1_o => open, hex2_o => open,
            hex3_o => open, hex4_o => open, hex5_o => open,
            pc_o => open, instruction_o => open, regwrite_o => open, memwrite_o => open,
            read_data1_o => open, read_data2_o => open, alu_result_o => open,
            bus_addr_o => bus_addr, bus_wdata_o => bus_wdata, bus_read_o => open,
            bus_write_o => bus_write, div_busy_o => open, div_done_o => open,
            div_result_o => open
        );

    stimulus : process
        variable led_writes, hex_writes : integer := 0;
    begin
        reset <= '1'; wait for 4*SYS_PERIOD; reset <= '0';
        for cycle in 0 to 500 loop
            wait until rising_edge(sysclk); wait for 2 ns;
            if bus_write = '1' then
                if bus_addr = C_PORT_LEDR_ADDR then led_writes := led_writes + 1; end if;
                if bus_addr = C_PORT_HEX0_ADDR or bus_addr = C_PORT_HEX1_ADDR or
                   bus_addr = C_PORT_HEX2_ADDR or bus_addr = C_PORT_HEX3_ADDR or
                   bus_addr = C_PORT_HEX4_ADDR or bus_addr = C_PORT_HEX5_ADDR then
                    hex_writes := hex_writes + 1;
                end if;
            end if;
            exit when led_writes >= 2 and hex_writes >= 12;
        end loop;
        assert led_writes >= 2 report "Stage 2 integration: GPIO benchmark did not write LEDR twice" severity failure;
        assert hex_writes >= 12 report "Stage 2 integration: expected two writes to all HEX ports" severity failure;
        assert ledr = x"01" report "Stage 2 integration: second loop should leave LEDR=1" severity failure;
        report "STAGE 2 GPIO INTEGRATION PASS" severity note;
        stop;
    end process;
end architecture;
