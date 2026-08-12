library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;
use work.cond_compilation_package.all;
use work.const_package.all;

entity tb_stage3_divider_integration is end entity;

architecture sim of tb_stage3_divider_integration is
    signal sysclk, divclk, reset : std_logic := '0';
    signal pc : std_logic_vector(G_PC_WIDTH-1 downto 0);
    signal instruction, r1, r2, result : std_logic_vector(31 downto 0);
    signal div_busy, div_done, regwrite : std_logic;
begin
    sysclk <= not sysclk after 20 ns;
    divclk <= not divclk after 10 ns;
    dut : entity work.mcu_sim_harness
        generic map (ITCM_INIT_FILE => "stage3/ITCM.hex", DTCM_INIT_FILE => "stage3/DTCM.hex")
        port map (
            sys_clk_i => sysclk, div_clk_i => divclk, reset_i => reset,
            switches_i => (others => '0'), ledr_o => open,
            hex0_o => open, hex1_o => open, hex2_o => open,
            hex3_o => open, hex4_o => open, hex5_o => open,
            pc_o => pc, instruction_o => instruction, regwrite_o => regwrite,
            memwrite_o => open, read_data1_o => r1, read_data2_o => r2,
            alu_result_o => result, bus_addr_o => open, bus_wdata_o => open,
            bus_read_o => open, bus_write_o => open,
            div_busy_o => div_busy, div_done_o => div_done, div_result_o => open
        );

    stimulus : process
        variable div_count, rem_count, stall_cycles, stable_halt : integer := 0;
        variable held_pc, last_pc : std_logic_vector(G_PC_WIDTH-1 downto 0) := (others => '1');
        variable was_busy : boolean := false;
        variable expected : signed(31 downto 0);
    begin
        reset <= '1'; wait for 160 ns; reset <= '0';
        for cycle in 0 to 10000 loop
            wait until rising_edge(sysclk); wait for 2 ns;
            if div_busy = '1' then
                if not was_busy then held_pc := pc; was_busy := true; end if;
                assert pc = held_pc report "Stage 3 integration: PC changed while divider busy" severity failure;
                assert regwrite = '0' report "Stage 3 integration: rd written before divider done" severity failure;
                stall_cycles := stall_cycles + 1;
            elsif was_busy and div_done = '0' then
                was_busy := false;
            end if;
            if div_done = '1' then
                assert regwrite = '1' report "Stage 3 integration: divider completion did not write rd" severity failure;
                if (instruction and INST_DIV_MASK) = INST_DIV then
                    expected := resize(signed(r1) / signed(r2), 32);
                    assert result = std_logic_vector(expected)
                        report "Stage 3 integration: DIV benchmark result mismatch" severity failure;
                    div_count := div_count + 1;
                elsif (instruction and INST_REM_MASK) = INST_REM then
                    expected := resize(signed(r1) rem signed(r2), 32);
                    assert result = std_logic_vector(expected)
                        report "Stage 3 integration: REM benchmark result mismatch" severity failure;
                    rem_count := rem_count + 1;
                end if;
            end if;
            if instruction = x"00000063" and pc = last_pc then stable_halt := stable_halt + 1;
            else stable_halt := 0; end if;
            last_pc := pc;
            exit when stable_halt = 8;
        end loop;
        assert div_count = 8 report "Stage 3 integration: expected 8 DIV completions" severity failure;
        assert rem_count = 8 report "Stage 3 integration: expected 8 REM completions" severity failure;
        assert stall_cycles >= 16 report "Stage 3 integration: divider did not stall core" severity failure;
        assert stable_halt = 8 report "Stage 3 integration: benchmark did not reach halt" severity failure;
        report "STAGE 3 CPU/DIVIDER INTEGRATION PASS" severity note;
        stop;
    end process;
end architecture;
