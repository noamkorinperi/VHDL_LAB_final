library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu_memory_map_pkg.all;

entity tb_stage4_basic_timer is
end entity;

architecture sim of tb_stage4_basic_timer is
    constant C_CLK_PERIOD : time := 20 ns;

    signal clk, reset, read_en, write_en : std_logic := '0';
    signal address, write_data, read_data : std_logic_vector(31 downto 0) :=
        (others => '0');
    signal hit, capin1, capin2, pwm, timer_event : std_logic := '0';
    signal compare0_event, compare1_event, capture_event : std_logic;
    signal counter, capture_value : std_logic_vector(31 downto 0);
begin
    clk <= not clk after C_CLK_PERIOD / 2;

    dut : entity work.basic_timer
        port map (
            clk_i => clk, reset_i => reset,
            address_i => address, write_data_i => write_data,
            read_i => read_en, write_i => write_en,
            read_data_o => read_data, hit_o => hit,
            capin1_i => capin1, capin2_i => capin2,
            pwm_o => pwm, btifg_event_o => timer_event,
            compare0_event_o => compare0_event,
            compare1_event_o => compare1_event,
            capture_event_o => capture_event,
            counter_o => counter, capture_o => capture_value
        );

    stimulus : process
        procedure bus_write(
            constant target_address : std_logic_vector(31 downto 0);
            constant value          : std_logic_vector(31 downto 0)) is
        begin
            address <= target_address;
            write_data <= value;
            write_en <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;
            write_en <= '0';
            address <= (others => '0');
            write_data <= (others => '0');
        end procedure;

        procedure check_read(
            constant target_address : std_logic_vector(31 downto 0);
            constant expected       : std_logic_vector(31 downto 0);
            constant label_text     : string) is
        begin
            address <= target_address;
            read_en <= '1';
            wait for 1 ns;
            assert hit = '1' report label_text & ": address was not decoded"
                severity failure;
            assert read_data = expected report label_text & ": readback mismatch"
                severity failure;
            read_en <= '0';
            address <= (others => '0');
            wait for 1 ns;
        end procedure;

        procedure wait_for_pulse(signal pulse : in std_logic;
                                 constant label_text : string) is
        begin
            for cycle in 1 to 40 loop
                wait until rising_edge(clk);
                wait for 1 ns;
                if pulse = '1' then
                    return;
                end if;
            end loop;
            assert false report label_text & ": timed out" severity failure;
        end procedure;

        procedure check_divider(
            constant selector : std_logic_vector(1 downto 0);
            constant expected_cycles : positive) is
            variable control_byte : std_logic_vector(7 downto 0);
            variable previous_count : std_logic_vector(31 downto 0);
            variable elapsed_cycles : natural;
        begin
            control_byte := (others => '0');
            control_byte(5) := '1';
            control_byte(4 downto 3) := selector;
            control_byte(2) := '1';
            bus_write(C_BTCTL1_ADDR, x"000000" & control_byte);

            control_byte(5) := '0';
            control_byte(2) := '0';
            bus_write(C_BTCTL1_ADDR, x"000000" & control_byte);

            previous_count := counter;
            loop
                wait until rising_edge(clk);
                wait for 1 ns;
                exit when counter /= previous_count;
            end loop;

            previous_count := counter;
            elapsed_cycles := 0;
            loop
                wait until rising_edge(clk);
                wait for 1 ns;
                elapsed_cycles := elapsed_cycles + 1;
                exit when counter /= previous_count;
            end loop;

            assert elapsed_cycles = expected_cycles
                report "BTSSEL divider spacing mismatch" severity failure;
        end procedure;
    begin
        reset <= '1';
        wait for 3 * C_CLK_PERIOD;
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);

        address <= x"00002030";
        read_en <= '1';
        wait for 1 ns;
        assert hit = '0' and read_data = x"00000000"
            report "Timer decoded an unmapped address" severity failure;
        read_en <= '0';
        address <= (others => '0');

        check_read(C_BTCTL1_ADDR, x"00000000", "BTCTL1 reset");
        check_read(C_BTCTL2_ADDR, x"00000000", "BTCTL2 reset");
        check_read(C_BTCMPR0_ADDR, x"00000000", "BTCMPR0 reset");
        check_read(C_BTCMPR1_ADDR, x"00000000", "BTCMPR1 reset");
        check_read(C_BTCAPR_ADDR, x"00000000", "BTCAPR reset");

        -- All interface registers are R/W. BTCTL2[7:4] alone is protected.
        bus_write(C_BTCTL2_ADDR, x"000000F9");
        check_read(C_BTCTL2_ADDR, x"00000009", "BTCTL2 protected bits");
        bus_write(C_BTCAPR_ADDR, x"A5A55A5A");
        check_read(C_BTCAPR_ADDR, x"A5A55A5A", "BTCAPR write/read");

        bus_write(C_BTCMPR0_ADDR, x"FFFFFFFF");
        bus_write(C_BTCMPR1_ADDR, x"12345678");
        check_read(C_BTCMPR0_ADDR, x"FFFFFFFF", "BTCMPR0");
        check_read(C_BTCMPR1_ADDR, x"12345678", "BTCMPR1");

        check_divider("00", 1);
        check_divider("01", 2);
        check_divider("10", 4);
        check_divider("11", 8);

        -- Mode 0: low until CMP1, high until CMP0.
        bus_write(C_BTCMPR0_ADDR, x"00000007");
        bus_write(C_BTCMPR1_ADDR, x"00000003");
        bus_write(C_BTCTL1_ADDR, x"00000064"); -- enable, hold, clear
        check_read(C_BTCTL1_ADDR, x"00000060", "BTCTL1/BTCLR");
        assert pwm = '0' report "PWM Mode0 did not start low" severity failure;
        bus_write(C_BTCTL1_ADDR, x"00000040");
        wait_for_pulse(compare1_event, "PWM Mode0 compare1");
        assert pwm = '1' report "PWM Mode0 did not go high at CMP1" severity failure;
        wait_for_pulse(compare0_event, "PWM Mode0 compare0");
        assert pwm = '0' report "PWM Mode0 did not go low at CMP0" severity failure;
        assert timer_event = '1'
            report "BTINT=00 did not select compare0" severity failure;

        -- Mode 1 has the inverse output polarity.
        bus_write(C_BTCTL1_ADDR, x"000000E4"); -- mode1, enable, hold, clear
        assert pwm = '1' report "PWM Mode1 did not start high" severity failure;
        bus_write(C_BTCTL1_ADDR, x"000000C0");
        wait_for_pulse(compare1_event, "PWM Mode1 compare1");
        assert pwm = '0' report "PWM Mode1 did not go low at CMP1" severity failure;
        wait_for_pulse(compare0_event, "PWM Mode1 compare0");
        assert pwm = '1' report "PWM Mode1 did not go high at CMP0" severity failure;

        -- BTOUTEN=0 freezes the output even though the counter is running.
        bus_write(C_BTCTL1_ADDR, x"00000024");
        bus_write(C_BTCTL1_ADDR, x"00000000");
        wait_for_pulse(compare0_event, "PWM output hold compare0");
        assert pwm = '1' report "BTOUTEN=0 did not preserve PWM" severity failure;

        -- Rising-edge capture from CAPIN1; BTINT=10 selects capture as BTIFG.
        capin1 <= '0';
        bus_write(C_BTCMPR0_ADDR, x"FFFFFFFF");
        bus_write(C_BTCTL2_ADDR, x"00000004"); -- rising, CAPIN1
        bus_write(C_BTCTL1_ADDR, x"00000026"); -- hold, clear, capture IRQ
        bus_write(C_BTCTL1_ADDR, x"00000002");
        for cycle in 1 to 5 loop
            wait until rising_edge(clk);
        end loop;
        capin1 <= '1';
        wait_for_pulse(capture_event, "CAPIN1 rising capture");
        assert timer_event = '1'
            report "BTINT=10 did not select capture" severity failure;
        assert unsigned(capture_value) > 0
            report "CAPIN1 capture value was not stored" severity failure;

        -- Falling-edge capture from CAPIN2.
        capin2 <= '1';
        for cycle in 1 to 4 loop
            wait until rising_edge(clk);
        end loop;
        bus_write(C_BTCTL2_ADDR, x"00000009"); -- falling, CAPIN2
        check_read(C_BTCTL2_ADDR, x"00000009", "BTCTL2");
        capin2 <= '0';
        wait_for_pulse(capture_event, "CAPIN2 falling capture");
        check_read(C_BTCAPR_ADDR, capture_value, "BTCAPR");

        report "STAGE 4 BASIC TIMER PASS" severity note;
        std.env.stop;
        wait;
    end process;
end architecture;
