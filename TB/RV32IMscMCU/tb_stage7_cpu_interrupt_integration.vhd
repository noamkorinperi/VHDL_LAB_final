library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

use work.cond_compilation_package.all;

entity tb_stage7_cpu_interrupt_integration is
end entity;

architecture sim of tb_stage7_cpu_interrupt_integration is
    constant CLK_PERIOD : time := 40 ns;
    constant DIV_PERIOD : time := 20 ns;
    constant STATE_ADDR : std_logic_vector(31 downto 0) := x"00000020";

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
    signal irq_type : std_logic_vector(7 downto 0);
    signal interrupt_ie, interrupt_ifg : std_logic_vector(7 downto 0);
begin
    sys_clk <= not sys_clk after CLK_PERIOD/2;
    div_clk <= not div_clk after DIV_PERIOD/2;

    dut : entity work.mcu_interrupt_sim_harness
        generic map (
            ITCM_INIT_FILE => "../../Benchmark apps/Intrrupt-based IO/test2/bin/M9K-intel/ITCM.hex",
            DTCM_INIT_FILE => "../../Benchmark apps/Intrrupt-based IO/test2/bin/M9K-intel/DTCM.hex"
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
        procedure press_and_check(
            constant key_index : in natural;
            constant expected_state : in std_logic_vector(31 downto 0);
            constant expected_type : in std_logic_vector(7 downto 0)
        ) is
            variable saw_inta, saw_irq_type, saw_gie_clear, saw_state_write : boolean := false;
            variable resume_pc : std_logic_vector(G_PC_WIDTH-1 downto 0) := (others => '0');
        begin
            keys_n(key_index) <= '0';
            wait until rising_edge(sys_clk);
            wait until rising_edge(sys_clk);
            keys_n(key_index) <= '1';
            for cycle in 0 to 300 loop
                wait until rising_edge(sys_clk);
                if inta = '1' then
                    saw_inta := true;
                    resume_pc := pc;
                end if;
                if irq_active = '1' and irq_type = expected_type then
                    saw_irq_type := true;
                end if;
                if irq_active = '1' and gie = '0' then
                    saw_gie_clear := true;
                end if;
                if bus_write = '1' and bus_addr = STATE_ADDR and
                   bus_wdata = expected_state then
                    saw_state_write := true;
                    exit;
                end if;
            end loop;
            assert saw_state_write
                report "Stage 7: ISR did not update state for KEY" & integer'image(key_index + 1)
                severity failure;
            assert saw_inta report "Stage 7: INTA was not asserted" severity failure;
            assert saw_irq_type report "Stage 7: CPU did not capture the expected TYPE" severity failure;
            assert saw_gie_clear report "Stage 7: GIE was not cleared during interrupt entry" severity failure;

            for cycle in 0 to 100 loop
                wait until rising_edge(sys_clk);
                exit when gie = '1' and irq_active = '0' and
                          interrupt_ifg(key_index + 3) = '0';
            end loop;
            assert gie = '1' report "Stage 7: RETI did not restore GIE" severity failure;
            assert irq_active = '0' report "Stage 7: interrupt FSM did not return to idle" severity failure;
            assert interrupt_ifg(key_index + 3) = '0'
                report "Stage 7: ISR did not clear its KEY IFG bit" severity failure;
            assert pc = resume_pc
                report "Stage 7: RETI did not return through tp to the interrupted flow"
                severity failure;
        end procedure;
    begin
        reset <= '1';
        wait for 5*CLK_PERIOD;
        wait until rising_edge(sys_clk);
        reset <= '0';

        -- The supplied application initializes IE=0x3C and then sets gp[0].
        for cycle in 0 to 300 loop
            wait until rising_edge(sys_clk);
            exit when interrupt_ie = x"3C" and gie = '1';
        end loop;
        assert interrupt_ie = x"3C" report "Stage 7: benchmark did not program IE=0x3C" severity failure;
        assert gie = '1' report "Stage 7: benchmark did not enable GIE in gp[0]" severity failure;

        press_and_check(0, x"00000001", x"14");
        press_and_check(1, x"00000002", x"18");
        press_and_check(2, x"00000003", x"1C");

        report "STAGE 7 CPU INTERRUPT INTEGRATION PASS" severity note;
        stop;
        wait;
    end process;
end architecture;
