library ieee;
use ieee.std_logic_1164.all;

use work.mcu_memory_map_pkg.all;

entity tb_stage5_pushbuttons is
end entity;

architecture sim of tb_stage5_pushbuttons is
    constant C_CLK_PERIOD : time := 20 ns;
    constant C_RESERVED_ZERO : std_logic_vector(31 downto 3) := (others => '0');

    signal clk, reset, read_en, hit : std_logic := '0';
    signal address, read_data : std_logic_vector(31 downto 0) := (others => '0');
    signal keys_n : std_logic_vector(2 downto 0) := (others => '1');
    signal buttons, press_event : std_logic_vector(2 downto 0);
    signal key1_events, key2_events, key3_events : natural := 0;
begin
    clk <= not clk after C_CLK_PERIOD / 2;

    dut : entity work.pushbutton_unit
        generic map (DEBOUNCE_CYCLES => 3)
        port map (
            clk_i => clk, reset_i => reset,
            address_i => address, read_i => read_en,
            read_data_o => read_data, hit_o => hit,
            keys_n_i => keys_n, buttons_o => buttons,
            press_event_o => press_event
        );

    event_counter : process (clk)
    begin
        if rising_edge(clk) then
            if press_event(0) = '1' then key1_events <= key1_events + 1; end if;
            if press_event(1) = '1' then key2_events <= key2_events + 1; end if;
            if press_event(2) = '1' then key3_events <= key3_events + 1; end if;
        end if;
    end process;

    stimulus : process
        procedure wait_cycles(constant count : positive) is
        begin
            for cycle in 1 to count loop
                wait until rising_edge(clk);
                wait for 1 ns;
            end loop;
        end procedure;

        procedure check_port(constant expected : std_logic_vector(2 downto 0);
                             constant label_text : string) is
        begin
            address <= C_PORT_PB_ADDR;
            read_en <= '1';
            wait for 1 ns;
            assert hit = '1' report label_text & ": PORT_PB was not decoded"
                severity failure;
            assert read_data(2 downto 0) = expected
                report label_text & ": PORT_PB readback mismatch" severity failure;
            assert read_data(31 downto 3) = C_RESERVED_ZERO
                report label_text & ": reserved PORT_PB bits were not zero"
                severity failure;
            read_en <= '0';
            address <= (others => '0');
            wait for 1 ns;
        end procedure;
    begin
        reset <= '1';
        wait_cycles(3);
        reset <= '0';
        wait_cycles(3);
        check_port("000", "Reset");

        address <= x"00002015";
        read_en <= '1';
        wait for 1 ns;
        assert hit = '0' and read_data = x"00000000"
            report "Pushbutton unit decoded an unmapped address" severity failure;
        read_en <= '0';
        address <= (others => '0');

        -- Short transitions are contact bounce and must not be reported.
        keys_n(0) <= '0';
        wait_cycles(1);
        keys_n(0) <= '1';
        wait_cycles(1);
        keys_n(0) <= '0';
        wait_cycles(1);
        keys_n(0) <= '1';
        wait_cycles(4);
        assert buttons(0) = '0' and key1_events = 0
            report "KEY1 bounce produced a false press" severity failure;

        keys_n(0) <= '0';
        wait_cycles(7);
        check_port("001", "Stable KEY1 press");
        assert key1_events = 1
            report "Stable KEY1 press did not produce exactly one event"
            severity failure;

        wait_cycles(8);
        assert key1_events = 1
            report "Held KEY1 repeated its press event" severity failure;

        -- Release is debounced but deliberately does not create a press event.
        keys_n(0) <= '1';
        wait_cycles(1);
        keys_n(0) <= '0';
        wait_cycles(1);
        keys_n(0) <= '1';
        wait_cycles(7);
        check_port("000", "KEY1 release");
        assert key1_events = 1
            report "KEY1 release created a press event" severity failure;

        keys_n(2 downto 1) <= "00";
        wait_cycles(7);
        check_port("110", "Simultaneous KEY2/KEY3 press");
        assert key2_events = 1 and key3_events = 1
            report "Simultaneous key presses were not independently detected"
            severity failure;

        report "STAGE 5 PUSHBUTTONS PASS" severity note;
        std.env.stop;
        wait;
    end process;
end architecture;
