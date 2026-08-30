library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.cond_compilation_package.all;
use work.mcu_memory_map_pkg.all;

-- Stage-8 central, self-checking benchmark testbench. BENCHMARK_ID selects one
-- instructor image while the unified ModelSim script iterates over the suite.
entity tb_RV32IMscMCU is
    generic (
        BENCHMARK_ID : natural := 0
    );
end entity;

architecture sim of tb_RV32IMscMCU is
    constant CLK_PERIOD : time := 40 ns;
    constant DIV_PERIOD : time := 20 ns;
    constant STATE_ADDR : std_logic_vector(31 downto 0) := x"00000020";

    function benchmark_itcm(id : natural) return string is
    begin
        case id is
            when 0 => return "../../Benchmark apps/RV32IM/test1/man_compiled/bin/M9K-intel/ITCM.hex";
            when 1 => return "../../Benchmark apps/RV32IM/test1/gcc_compiled/bin/M9K-intel/ITCM.hex";
            when 2 => return "../../Benchmark apps/GPIO/test0/bin/M9K-intel/ITCM.hex";
            when 3 => return "../../Benchmark apps/GPIO/test1/bin/M9K-intel/ITCM.hex";
            when 4 => return "../../Benchmark apps/GPIO/test2/bin/M9K-intel/ITCM.hex";
            -- The supplied test1 image jumps over EINT for SW0=0.  Keep the
            -- instructor folder untouched and use the one-word corrected copy.
            when 5 => return "firmware/interrupt_test1_ITCM_fixed.hex";
            when 6 => return "../../Benchmark apps/Intrrupt-based IO/test2/bin/M9K-intel/ITCM.hex";
            when 7 => return "../../Benchmark apps/Intrrupt-based IO/test3/bin/M9K-intel/ITCM.hex";
            -- Board-specific test4 copy clears BTCNT when entering PWM mode.
            -- The instructor image is kept untouched under Benchmark apps.
            when 8 => return "../../Quartus/RV32IMscMCU/ITCM_stage9_interrupt_test4.hex";
            when others => return "INVALID_ITCM.hex";
        end case;
    end function;

    function benchmark_dtcm(id : natural) return string is
    begin
        case id is
            when 0 => return "../../Benchmark apps/RV32IM/test1/man_compiled/bin/M9K-intel/DTCM.hex";
            when 1 => return "../../Benchmark apps/RV32IM/test1/gcc_compiled/bin/M9K-intel/DTCM.hex";
            when 2 => return "../../Benchmark apps/GPIO/test0/bin/M9K-intel/DTCM.hex";
            when 3 => return "../../Benchmark apps/GPIO/test1/bin/M9K-intel/DTCM.hex";
            when 4 => return "../../Benchmark apps/GPIO/test2/bin/M9K-intel/DTCM.hex";
            when 5 => return "../../Benchmark apps/Intrrupt-based IO/test1/bin/M9K-intel/DTCM.hex";
            when 6 => return "../../Benchmark apps/Intrrupt-based IO/test2/bin/M9K-intel/DTCM.hex";
            when 7 => return "../../Benchmark apps/Intrrupt-based IO/test3/bin/M9K-intel/DTCM.hex";
            when 8 => return "../../Benchmark apps/Intrrupt-based IO/test4/bin/M9K-intel/DTCM.hex";
            when others => return "INVALID_DTCM.hex";
        end case;
    end function;

    function is_binary(value : std_logic_vector) return boolean is
    begin
        for i in value'range loop
            if value(i) /= '0' and value(i) /= '1' then
                return false;
            end if;
        end loop;
        return true;
    end function;

    type result_array_t is array (0 to 23) of std_logic_vector(31 downto 0);
    constant C_RARS_RESULTS : result_array_t := (
        x"00000000", x"00000000", x"00000000", x"00000000",
        x"00000001", x"00000002", x"00000003", x"00000008",
        x"00000008", x"0000000E", x"00000012", x"00000014",
        x"00000014", x"00000012", x"0000000E", x"00000008",
        x"00000001", x"00000002", x"00000003", x"00000004",
        x"00000001", x"00000000", x"00000001", x"00000000"
    );

    signal sys_clk, div_clk, reset : std_logic := '0';
    signal done : std_logic := '0';
    signal switches : std_logic_vector(7 downto 0) := (others => '0');
    signal keys_n : std_logic_vector(2 downto 0) := (others => '1');
    signal capin1, capin2 : std_logic := '0';
    signal ledr : std_logic_vector(7 downto 0);
    signal hex0, hex1, hex2, hex3, hex4, hex5 : std_logic_vector(6 downto 0);
    signal pwm : std_logic;
    signal pc : std_logic_vector(G_PC_WIDTH-1 downto 0);
    signal instruction, bus_addr, bus_wdata : std_logic_vector(31 downto 0);
    signal bus_read, bus_write, div_busy, div_done : std_logic;
    signal intr, inta, gie, irq_active : std_logic;
    signal irq_type, interrupt_ie, interrupt_ifg : std_logic_vector(7 downto 0);
begin
    assert BENCHMARK_ID <= 8
        report "Stage 8: unsupported BENCHMARK_ID" severity failure;

    sys_clock : process
    begin
        while done = '0' loop
            wait for CLK_PERIOD/2;
            sys_clk <= not sys_clk;
        end loop;
        wait;
    end process;

    div_clock : process
    begin
        while done = '0' loop
            wait for DIV_PERIOD/2;
            div_clk <= not div_clk;
        end loop;
        wait;
    end process;

    dut : entity work.mcu_interrupt_sim_harness
        generic map (
            ITCM_INIT_FILE => benchmark_itcm(BENCHMARK_ID),
            DTCM_INIT_FILE => benchmark_dtcm(BENCHMARK_ID)
        )
        port map (
            sys_clk_i => sys_clk, div_clk_i => div_clk, reset_i => reset,
            switches_i => switches, keys_n_i => keys_n,
            capin1_i => capin1, capin2_i => capin2,
            ledr_o => ledr, hex0_o => hex0, hex1_o => hex1,
            hex2_o => hex2, hex3_o => hex3, hex4_o => hex4,
            hex5_o => hex5, pwm_o => pwm, pc_o => pc,
            instruction_o => instruction, bus_addr_o => bus_addr,
            bus_wdata_o => bus_wdata, bus_read_o => bus_read,
            bus_write_o => bus_write, div_busy_o => div_busy,
            div_done_o => div_done, intr_o => intr, inta_o => inta,
            gie_o => gie, irq_active_o => irq_active,
            irq_type_o => irq_type, interrupt_ie_o => interrupt_ie,
            interrupt_ifg_o => interrupt_ifg
        );

    protocol_monitor : process
        variable dtcm_hit, mmio_hit : boolean;
    begin
        wait until rising_edge(sys_clk);
        if reset = '0' and done = '0' then
            assert is_binary(pc) and is_binary(instruction) and
                   is_binary(bus_addr) and is_binary(bus_wdata)
                report "Stage 8: X/U detected on CPU-visible signals" severity failure;
            assert not (bus_read = '1' and bus_write = '1')
                report "Stage 8: simultaneous bus read and write" severity failure;
            dtcm_hit := unsigned(bus_addr) <= unsigned(C_DTCM_DECODE_END_ADDR);
            mmio_hit := unsigned(bus_addr) >= unsigned(C_MMIO_BASE_ADDR) and
                        unsigned(bus_addr) <= unsigned(C_MMIO_DECODE_END_ADDR);
            assert not (dtcm_hit and mmio_hit)
                report "Stage 8: illegal DTCM/MMIO decode overlap" severity failure;
            if div_busy = '1' then
                assert bus_write = '0'
                    report "Stage 8: memory write occurred during divider wait" severity failure;
            end if;
        end if;
    end process;

    stimulus : process
        type seen_array_t is array (0 to 23) of boolean;

        procedure wait_cycles(constant count : natural) is
        begin
            for i in 1 to count loop
                wait until rising_edge(sys_clk);
            end loop;
        end procedure;

        procedure reset_dut is
        begin
            reset <= '1';
            wait_cycles(5);
            reset <= '0';
            wait until rising_edge(sys_clk);
        end procedure;

        procedure wait_for_write(
            constant expected_addr : std_logic_vector(31 downto 0);
            constant expected_data : std_logic_vector(31 downto 0);
            constant max_cycles : natural;
            constant description : string
        ) is
            variable found : boolean := false;
        begin
            for cycle in 0 to max_cycles loop
                wait until rising_edge(sys_clk);
                if bus_write = '1' and bus_addr = expected_addr and
                   bus_wdata = expected_data then
                    found := true;
                    exit;
                end if;
            end loop;
            assert found report "Stage 8 timeout/mismatch: " & description severity failure;
        end procedure;

        procedure wait_for_nonzero_write(
            constant expected_addr : std_logic_vector(31 downto 0);
            constant max_cycles : natural;
            constant description : string
        ) is
            variable found : boolean := false;
        begin
            for cycle in 0 to max_cycles loop
                wait until rising_edge(sys_clk);
                if bus_write = '1' and bus_addr = expected_addr and
                   bus_wdata /= x"00000000" then
                    found := true;
                    exit;
                end if;
            end loop;
            assert found report "Stage 8 timeout/mismatch: " & description severity failure;
        end procedure;

        procedure wait_for_interrupt_ready(constant expected_ie : std_logic_vector(7 downto 0)) is
            variable found : boolean := false;
        begin
            for cycle in 0 to 500 loop
                wait until rising_edge(sys_clk);
                if interrupt_ie = expected_ie and gie = '1' then
                    found := true;
                    exit;
                end if;
            end loop;
            assert found report "Stage 8: interrupt firmware did not initialize" severity failure;
        end procedure;

        procedure press_and_expect_state(
            constant key_index : natural;
            constant expected_state : std_logic_vector(31 downto 0);
            constant check_side_write : boolean;
            constant side_addr : std_logic_vector(31 downto 0);
            constant side_data : std_logic_vector(31 downto 0)
        ) is
            variable saw_state, saw_side, returned : boolean := false;
        begin
            keys_n(key_index) <= '0';
            wait until rising_edge(sys_clk);
            wait until rising_edge(sys_clk);
            keys_n(key_index) <= '1';
            for cycle in 0 to 600 loop
                wait until rising_edge(sys_clk);
                if bus_write = '1' and bus_addr = STATE_ADDR and
                   bus_wdata = expected_state then
                    saw_state := true;
                end if;
                if check_side_write and bus_write = '1' and
                   bus_addr = side_addr and bus_wdata = side_data then
                    saw_side := true;
                end if;
                exit when saw_state;
            end loop;
            assert saw_state report "Stage 8: key ISR did not update state" severity failure;
            for cycle in 0 to 600 loop
                wait until rising_edge(sys_clk);
                if check_side_write and bus_write = '1' and
                   bus_addr = side_addr and bus_wdata = side_data then
                    saw_side := true;
                end if;
                if gie = '1' and irq_active = '0' and
                   interrupt_ifg(key_index + 3) = '0' then
                    returned := true;
                    exit;
                end if;
            end loop;
            assert returned report "Stage 8: ISR did not return/clear IFG" severity failure;
            assert (not check_side_write) or saw_side
                report "Stage 8: expected ISR peripheral write was not observed" severity failure;
        end procedure;

        variable seen : seen_array_t := (others => false);
        variable cycles, retired, stable_pc, result_index : natural := 0;
        variable last_pc : std_logic_vector(G_PC_WIDTH-1 downto 0) := (others => '1');
        variable found, pwm_high : boolean := false;
    begin
        case BENCHMARK_ID is
            when 0 | 1 =>
                reset_dut;
                while cycles < 20000 loop
                    wait until rising_edge(sys_clk);
                    cycles := cycles + 1;
                    if div_busy = '0' and irq_active = '0' then
                        retired := retired + 1;
                    end if;
                    if bus_write = '1' and unsigned(bus_addr) >= 16#40# and
                       unsigned(bus_addr) <= 16#9C# and bus_addr(1 downto 0) = "00" then
                        result_index := (to_integer(unsigned(bus_addr)) - 16#40#) / 4;
                        assert bus_wdata = C_RARS_RESULTS(result_index)
                            report "Stage 8: DTCM differs from supplied RARS golden output"
                            severity failure;
                        seen(result_index) := true;
                    end if;
                    if pc = last_pc and div_busy = '0' and
                       (instruction = x"00000063" or instruction = x"0000006F") then
                        stable_pc := stable_pc + 1;
                    else stable_pc := 0;
                    end if;
                    last_pc := pc;
                    exit when stable_pc = 8;
                end loop;
                assert cycles < 20000 report "Stage 8: RV32IM timeout" severity failure;
                for i in seen'range loop
                    assert seen(i) report "Stage 8: missing RARS result word" severity failure;
                end loop;
                report "Stage 8 metrics: cycles=" & integer'image(cycles) &
                       " effective-retire-cycles=" & integer'image(retired) &
                       " IPCx1000=" & integer'image((retired * 1000) / cycles)
                    severity note;

            when 2 =>
                reset_dut;
                wait_for_write(C_PORT_LEDR_ADDR, x"00000001", 800, "GPIO/test0 LED increment");
                wait_for_write(C_PORT_HEX5_ADDR, x"00000001", 100, "GPIO/test0 HEX writes");

            when 3 | 4 =>
                switches <= x"01";
                reset_dut;
                wait_for_write(C_PORT_LEDR_ADDR, x"00000001", 1000, "GPIO switch increment");
                switches <= x"02";
                wait_for_write(C_PORT_LEDR_ADDR, x"00000000", 1000, "GPIO switch decrement");

            when 5 =>
                switches <= x"00";
                reset_dut;
                wait_for_interrupt_ready(x"38");
                press_and_expect_state(0, x"00000001", false, x"00000000", x"00000000");
                wait_for_write(C_PORT_HEX4_ADDR, x"00000004", 300, "interrupt/test1 arr1 low digit");
                wait_for_write(C_PORT_HEX5_ADDR, x"00000006", 100, "interrupt/test1 arr1 high digit");
                wait_cycles(10); -- allow the foreground FSM to return to its idle state
                press_and_expect_state(1, x"00000002", false, x"00000000", x"00000000");
                wait_for_write(C_PORT_HEX2_ADDR, x"00000008", 300, "interrupt/test1 arr2 low digit");
                wait_cycles(10);
                press_and_expect_state(2, x"00000003", false, x"00000000", x"00000000");
                wait_for_write(C_PORT_LEDR_ADDR, x"00000004", 1500, "interrupt/test1 remainder");

            when 6 =>
                reset_dut;
                wait_for_interrupt_ready(x"3C");
                press_and_expect_state(0, x"00000001", false, x"00000000", x"00000000");
                wait_for_write(C_PORT_HEX0_ADDR, x"00000000", 300, "interrupt/test2 KEY1 output");
                wait_cycles(10);
                press_and_expect_state(1, x"00000002", false, x"00000000", x"00000000");
                wait_for_write(C_PORT_HEX2_ADDR, x"00000000", 300, "interrupt/test2 KEY2 output");
                wait_cycles(10);
                press_and_expect_state(2, x"00000003", false, x"00000000", x"00000000");
                wait_for_write(C_PORT_HEX4_ADDR, x"00000000", 300, "interrupt/test2 KEY3 output");

            when 7 =>
                reset_dut;
                wait_for_interrupt_ready(x"3C");
                press_and_expect_state(0, x"00000001", true, C_BTCMPR0_ADDR, x"001312D0");
                wait_for_write(C_PORT_LEDR_ADDR, x"00000000", 300, "interrupt/test3 KEY1 output");
                press_and_expect_state(1, x"00000002", true, C_BTCMPR0_ADDR, x"00098968");
                wait_for_write(C_PORT_LEDR_ADDR, x"00000000", 300, "interrupt/test3 KEY2 output");
                press_and_expect_state(2, x"00000003", true, C_BTCMPR0_ADDR, x"0004C4B4");
                wait_for_write(C_PORT_LEDR_ADDR, x"00000000", 300, "interrupt/test3 KEY3 output");

            when 8 =>
                reset_dut;
                wait_for_interrupt_ready(x"38");
                press_and_expect_state(0, x"00000001", true, C_BTCMPR0_ADDR, x"01312D00");
                -- Reproduce the physical KEY1 -> KEY2 sequence.  Waiting past
                -- the new PWM top value proves that KEY2 clears the old,
                -- much larger compare-mode counter before PWM starts.
                wait_cycles(5000);
                press_and_expect_state(1, x"00000002", true, C_BTCMPR1_ADDR, x"000003E8");
                for cycle in 0 to 1500 loop
                    wait until rising_edge(sys_clk);
                    if pwm = '1' then pwm_high := true; exit; end if;
                end loop;
                assert pwm_high report "Stage 8: interrupt/test4 PWM never went high" severity failure;
                -- CMP0 is deliberately an FPGA-scale period (20,000,000 clocks),
                -- so a full falling edge would make this ModelSim regression
                -- unnecessarily long.  The programmed CMP0/CMP1 writes plus a
                -- sustained high interval verify the benchmark PWM setup.
                wait_cycles(64);
                assert pwm = '1' report "Stage 8: interrupt/test4 PWM pulse was not sustained" severity failure;
                press_and_expect_state(2, x"00000003", true, C_BTCTL2_ADDR, x"00000007");
                wait_for_write(x"0000009C", x"00000004", 4000, "interrupt/test4 REM array");
                wait_for_nonzero_write(x"000000C8", 1000, "interrupt/test4 REM runtime capture");
                press_and_expect_state(2, x"00000003", true, C_BTCTL2_ADDR, x"00000007");
                wait_for_write(x"00000074", x"00000007", 4000, "interrupt/test4 DIV array");
                wait_for_nonzero_write(x"000000C4", 1000, "interrupt/test4 DIV runtime capture");
                -- Physical stage-9 recovery check: after both capture-mode
                -- workloads, KEY1 must still be serviced and re-enter timer
                -- compare mode instead of leaving the CPU/IRQ path stuck.
                press_and_expect_state(0, x"00000001", true, C_BTCMPR0_ADDR, x"01312D00");

                -- Also match the board test from a clean reset, without first
                -- putting the timer through compare and PWM modes.
                reset_dut;
                wait_for_interrupt_ready(x"38");
                press_and_expect_state(2, x"00000003", true, C_BTCTL2_ADDR, x"00000007");
                wait_for_write(x"0000009C", x"00000004", 4000, "interrupt/test4 clean REM array");
                wait_for_nonzero_write(x"000000C8", 1000, "interrupt/test4 clean REM runtime capture");
                press_and_expect_state(2, x"00000003", true, C_BTCTL2_ADDR, x"00000007");
                wait_for_write(x"00000074", x"00000007", 4000, "interrupt/test4 clean DIV array");
                wait_for_nonzero_write(x"000000C4", 1000, "interrupt/test4 clean DIV runtime capture");
                press_and_expect_state(0, x"00000001", true, C_BTCMPR0_ADDR, x"01312D00");

            when others =>
                assert false report "Stage 8: unreachable benchmark selection" severity failure;
        end case;

        report "STAGE 8 BENCHMARK " & integer'image(BENCHMARK_ID) & " PASS" severity note;
        done <= '1';
        wait;
    end process;
end architecture;
