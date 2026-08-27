library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

use work.cond_compilation_package.all;

entity tb_stage5_5_smoke_firmware is
end entity;

architecture sim of tb_stage5_5_smoke_firmware is
    constant CLK_PERIOD : time := 50 ns;
    constant DIV_PERIOD : time := 20 ns;
    constant HEX_C      : std_logic_vector(6 downto 0) := "1000110";

    signal sys_clk, div_clk, reset : std_logic := '0';
    signal switches : std_logic_vector(7 downto 0) := (others => '0');
    signal keys_n : std_logic_vector(2 downto 0) := (others => '1');
    signal ledr : std_logic_vector(7 downto 0);
    signal hex0, hex1, hex2, hex3, hex4, hex5 : std_logic_vector(6 downto 0);
    signal pwm : std_logic;
    signal pc : std_logic_vector(G_PC_WIDTH-1 downto 0);
    signal instruction, bus_addr, bus_wdata : std_logic_vector(31 downto 0);
    signal bus_read, bus_write, div_busy, div_done : std_logic;
    signal intr, inta, gie, irq_active : std_logic;
    signal irq_type, interrupt_ie, interrupt_ifg : std_logic_vector(7 downto 0);
begin
    sys_clk <= not sys_clk after CLK_PERIOD/2;
    div_clk <= not div_clk after DIV_PERIOD/2;

    dut : entity work.mcu_interrupt_sim_harness
        generic map (
            ITCM_INIT_FILE => "../../Quartus/RV32IMscMCU/ITCM_stage5_5.hex",
            DTCM_INIT_FILE => "../../Quartus/RV32IMscMCU/DTCM.hex"
        )
        port map (
            sys_clk_i => sys_clk, div_clk_i => div_clk, reset_i => reset,
            switches_i => switches, keys_n_i => keys_n,
            capin1_i => '0', capin2_i => '0', ledr_o => ledr,
            hex0_o => hex0, hex1_o => hex1, hex2_o => hex2,
            hex3_o => hex3, hex4_o => hex4, hex5_o => hex5,
            pwm_o => pwm, pc_o => pc, instruction_o => instruction,
            bus_addr_o => bus_addr, bus_wdata_o => bus_wdata,
            bus_read_o => bus_read, bus_write_o => bus_write,
            div_busy_o => div_busy, div_done_o => div_done,
            intr_o => intr, inta_o => inta, gie_o => gie,
            irq_active_o => irq_active, irq_type_o => irq_type,
            interrupt_ie_o => interrupt_ie, interrupt_ifg_o => interrupt_ifg
        );

    stimulus : process
        variable saw_pwm_high, saw_pwm_low : boolean := false;
    begin
        reset <= '1';
        wait for 5*CLK_PERIOD;
        wait until rising_edge(sys_clk);
        reset <= '0';

        -- The firmware first writes C to HEX0 and starts the timer/PWM.
        for cycle in 0 to 100 loop
            wait until rising_edge(sys_clk);
            exit when hex0 = HEX_C;
        end loop;
        assert hex0 = HEX_C
            report "Stage 5.5: smoke firmware did not display C on HEX0"
            severity failure;

        -- SW=1 makes CMP1 occur after 128 timer counts. That is enough to
        -- prove the output transitions without simulating the full 32768-count
        -- hardware period (the physical procedure covers the 50% setting).
        switches <= x"01";
        for cycle in 0 to 5000 loop
            wait until rising_edge(sys_clk);
            if pwm = '1' then saw_pwm_high := true; end if;
            if pwm = '0' then saw_pwm_low := true; end if;
            exit when saw_pwm_high and saw_pwm_low;
        end loop;
        assert saw_pwm_high and saw_pwm_low
            report "Stage 5.5: PWM did not toggle after the CMP1 threshold"
            severity failure;

        -- Each physical KEY is active-low and must appear active-high on LEDR2:0.
        for key_index in 0 to 2 loop
            keys_n(key_index) <= '0';
            for cycle in 0 to 50 loop
                wait until rising_edge(sys_clk);
                exit when ledr(key_index) = '1';
            end loop;
            assert ledr(key_index) = '1'
                report "Stage 5.5: KEY did not reach its LEDR indicator"
                severity failure;

            keys_n(key_index) <= '1';
            for cycle in 0 to 50 loop
                wait until rising_edge(sys_clk);
                exit when ledr(key_index) = '0';
            end loop;
            assert ledr(key_index) = '0'
                report "Stage 5.5: LEDR indicator did not clear after KEY release"
                severity failure;
        end loop;

        report "STAGE 5.5 SMOKE FIRMWARE PASS" severity note;
        stop;
        wait;
    end process;
end architecture;
