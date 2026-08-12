library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

use work.cond_compilation_package.all;
use work.const_package.all;

entity tb_stage0_baseline is end entity;

architecture sim of tb_stage0_baseline is
    constant SYS_PERIOD : time := 40 ns;
    constant DIV_PERIOD : time := 20 ns;
    signal sysclk, divclk, reset : std_logic := '0';
    signal pc : std_logic_vector(G_PC_WIDTH-1 downto 0);
    signal instruction, r1, r2, alu : std_logic_vector(31 downto 0);
    signal regwrite, memwrite : std_logic;
begin
    sysclk <= not sysclk after SYS_PERIOD/2;
    divclk <= not divclk after DIV_PERIOD/2;

    dut : entity work.mcu_sim_harness
        generic map (ITCM_INIT_FILE => "stage0/ITCM.hex", DTCM_INIT_FILE => "stage0/DTCM.hex")
        port map (
            sys_clk_i => sysclk, div_clk_i => divclk, reset_i => reset,
            switches_i => (others => '0'), ledr_o => open,
            hex0_o => open, hex1_o => open, hex2_o => open,
            hex3_o => open, hex4_o => open, hex5_o => open,
            pc_o => pc, instruction_o => instruction,
            regwrite_o => regwrite, memwrite_o => memwrite,
            read_data1_o => r1, read_data2_o => r2, alu_result_o => alu,
            bus_addr_o => open, bus_wdata_o => open, bus_read_o => open,
            bus_write_o => open, div_busy_o => open, div_done_o => open,
            div_result_o => open
        );

    stimulus : process
        variable cycles, mul_count, store_count, stable_halt : integer := 0;
        variable last_pc : std_logic_vector(G_PC_WIDTH-1 downto 0) := (others => '1');
        variable expected : unsigned(31 downto 0);
    begin
        reset <= '1'; wait for 4*SYS_PERIOD; reset <= '0';
        while cycles < 10000 loop
            wait until rising_edge(sysclk); wait for 2 ns;
            cycles := cycles + 1;
            if (instruction and INST_MUL_MASK) = INST_MUL then
                expected := resize(unsigned(r1(15 downto 0)) * unsigned(r2(15 downto 0)), 32);
                assert alu = std_logic_vector(expected) report "Stage 0: MUL result mismatch" severity failure;
                assert regwrite = '1' report "Stage 0: MUL must write rd" severity failure;
                mul_count := mul_count + 1;
            end if;
            if memwrite = '1' then store_count := store_count + 1; end if;
            if instruction = x"00000063" and pc = last_pc then
                stable_halt := stable_halt + 1;
            else
                stable_halt := 0;
            end if;
            last_pc := pc;
            exit when stable_halt = 8;
        end loop;
        assert cycles < 10000 report "Stage 0: timeout before halt" severity failure;
        assert mul_count > 0 report "Stage 0: no MUL observed" severity failure;
        assert store_count > 0 report "Stage 0: no DTCM store observed" severity failure;
        report "STAGE 0 PASS: RV32I/MUL baseline and DTCM regression" severity note;
        stop;
    end process;
end architecture;
