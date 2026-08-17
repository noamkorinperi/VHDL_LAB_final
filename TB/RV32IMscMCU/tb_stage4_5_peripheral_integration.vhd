library ieee;
use ieee.std_logic_1164.all;

use work.mcu_memory_map_pkg.all;

entity tb_stage4_5_peripheral_integration is
end entity;

architecture sim of tb_stage4_5_peripheral_integration is
    constant C_CLK_PERIOD : time := 20 ns;

    signal clk, reset, read_en, write_en, hit : std_logic := '0';
    signal address, write_data, read_data : std_logic_vector(31 downto 0) :=
        (others => '0');
    signal switches, ledr : std_logic_vector(7 downto 0) := (others => '0');
    signal keys_n : std_logic_vector(2 downto 0) := (others => '1');
    signal capin1, capin2, pwm, timer_event : std_logic := '0';
    signal key_event, button_state : std_logic_vector(2 downto 0);
    signal timer_count, timer_capture : std_logic_vector(31 downto 0);
    signal hex0, hex1, hex2, hex3, hex4, hex5 : std_logic_vector(6 downto 0);
begin
    clk <= not clk after C_CLK_PERIOD / 2;

    dut : entity work.mcu_peripherals
        generic map (PB_DEBOUNCE_CYCLES => 2)
        port map (
            clk_i => clk, reset_i => reset,
            address_i => address, write_data_i => write_data,
            read_i => read_en, write_i => write_en,
            read_data_o => read_data, hit_o => hit,
            switches_i => switches, keys_n_i => keys_n,
            capin1_i => capin1, capin2_i => capin2,
            ledr_o => ledr, hex0_o => hex0, hex1_o => hex1,
            hex2_o => hex2, hex3_o => hex3, hex4_o => hex4, hex5_o => hex5,
            pwm_o => pwm, timer_event_o => timer_event,
            key_event_o => key_event, button_state_o => button_state,
            timer_count_o => timer_count, timer_capture_o => timer_capture
        );

    stimulus : process
        procedure wait_cycles(constant count : positive) is
        begin
            for cycle in 1 to count loop
                wait until rising_edge(clk);
                wait for 1 ns;
            end loop;
        end procedure;

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
            assert hit = '1' report label_text & ": MMIO hit missing" severity failure;
            assert read_data = expected report label_text & ": read data mismatch"
                severity failure;
            read_en <= '0';
            address <= (others => '0');
            wait for 1 ns;
        end procedure;
    begin
        reset <= '1';
        wait_cycles(3);
        reset <= '0';
        wait_cycles(2);

        -- Existing stage-2 GPIO remains reachable through the shared mux.
        bus_write(C_PORT_LEDR_ADDR, x"000000A5");
        assert ledr = x"A5" report "GPIO write was broken by peripheral mux"
            severity failure;
        check_read(C_PORT_LEDR_ADDR, x"000000A5", "LEDR");

        switches <= x"3C";
        check_read(C_PORT_SW_ADDR, x"0000003C", "Switches");

        -- Timer registers and event/PWM outputs share the same MMIO bus.
        bus_write(C_BTCMPR0_ADDR, x"00000003");
        bus_write(C_BTCMPR1_ADDR, x"00000001");
        bus_write(C_BTCTL1_ADDR, x"00000044"); -- output enable + clear
        check_read(C_BTCMPR0_ADDR, x"00000003", "BTCMPR0");
        for cycle in 1 to 12 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            exit when pwm = '1';
        end loop;
        assert pwm = '1' report "Integrated PWM never changed state" severity failure;
        for cycle in 1 to 12 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            exit when timer_event = '1';
        end loop;
        assert timer_event = '1'
            report "Integrated timer event never asserted" severity failure;

        -- Debounced key state and one-cycle press event reach the wrapper ports.
        keys_n(1) <= '0';
        wait_cycles(6);
        assert button_state = "010"
            report "Integrated pushbutton state mismatch" severity failure;
        check_read(C_PORT_PB_ADDR, x"00000002", "PORT_PB");

        address <= x"00002030";
        read_en <= '1';
        wait for 1 ns;
        assert hit = '0' and read_data = x"00000000"
            report "Peripheral mux did not zero an unmapped read" severity failure;

        report "STAGE 4/5 PERIPHERAL INTEGRATION PASS" severity note;
        std.env.stop;
        wait;
    end process;
end architecture;
