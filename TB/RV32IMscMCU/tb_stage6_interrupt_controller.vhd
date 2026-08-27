library ieee;
use ieee.std_logic_1164.all;

use work.mcu_memory_map_pkg.all;

entity tb_stage6_interrupt_controller is
end entity;

architecture sim of tb_stage6_interrupt_controller is
    constant C_CLK_PERIOD : time := 20 ns;

    signal clk, reset, read_en, write_en, hit : std_logic := '0';
    signal address, write_data, read_data : std_logic_vector(31 downto 0) :=
        (others => '0');
    signal timer_event, gie, inta, intr : std_logic := '0';
    signal key_event : std_logic_vector(2 downto 0) := (others => '0');
    signal irq_type, ie_value, ifg_value : std_logic_vector(7 downto 0);
begin
    clk <= not clk after C_CLK_PERIOD / 2;

    dut : entity work.interrupt_controller
        port map (
            clk_i => clk, reset_i => reset,
            address_i => address, write_data_i => write_data,
            read_i => read_en, write_i => write_en,
            read_data_o => read_data, hit_o => hit,
            timer_event_i => timer_event, key_event_i => key_event,
            gie_i => gie, inta_i => inta,
            intr_o => intr, type_o => irq_type,
            ie_o => ie_value, ifg_o => ifg_value
        );

    stimulus : process
        procedure clock_edge is
        begin
            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

        procedure bus_write(
            constant target_address : std_logic_vector(31 downto 0);
            constant value : std_logic_vector(31 downto 0)) is
        begin
            address <= target_address;
            write_data <= value;
            write_en <= '1';
            clock_edge;
            write_en <= '0';
            address <= (others => '0');
            write_data <= (others => '0');
        end procedure;

        procedure check_read(
            constant target_address : std_logic_vector(31 downto 0);
            constant expected : std_logic_vector(31 downto 0);
            constant label_text : string) is
        begin
            address <= target_address;
            read_en <= '1';
            wait for 1 ns;
            assert hit = '1' report label_text & ": no MMIO hit" severity failure;
            assert read_data = expected report label_text & ": readback mismatch"
                severity failure;
            read_en <= '0';
            address <= (others => '0');
            wait for 1 ns;
        end procedure;

        procedure pulse_sources(
            constant timer_value : std_logic;
            constant key_value : std_logic_vector(2 downto 0)) is
        begin
            timer_event <= timer_value;
            key_event <= key_value;
            clock_edge;
            timer_event <= '0';
            key_event <= (others => '0');
        end procedure;

        procedure acknowledge is
        begin
            inta <= '1';
            clock_edge;
            inta <= '0';
        end procedure;
    begin
        reset <= '1';
        clock_edge;
        clock_edge;
        reset <= '0';
        clock_edge;
        assert ie_value = x"00" and ifg_value = x"00" and intr = '0'
            report "Interrupt controller reset mismatch" severity failure;

        -- An event with IE=0 must not be latched for later service.
        pulse_sources('0', "100");
        assert ifg_value = x"00" and intr = '0'
            report "Disabled KEY3 event was retained in IFG" severity failure;

        bus_write(C_IE_ADDR, x"000000FC");
        check_read(C_IE_ADDR, x"0000003C", "IE reserved bits");
        assert intr = '0' report "IE alone asserted INTR" severity failure;

        -- A disabled GIE suppresses INTR without losing the pending flag.
        pulse_sources('0', "100");
        check_read(C_IFG_ADDR, x"00000020", "KEY3 flag latch");
        assert intr = '0' report "GIE=0 did not mask INTR" severity failure;
        gie <= '1';
        wait for 1 ns;
        assert intr = '1' and irq_type = C_IRQ_TYPE_KEY3
            report "KEY3 interrupt/type mismatch" severity failure;

        -- Timer, KEY1 and KEY3 pending together: timer has highest priority.
        pulse_sources('1', "001");
        assert ifg_value = x"2C" and irq_type = C_IRQ_TYPE_TIMER
            report "Priority selection did not choose timer" severity failure;
        check_read(C_TYPE_ADDR, x"00000010", "TYPE timer");

        acknowledge;
        assert ifg_value = x"28" and irq_type = C_IRQ_TYPE_KEY1
            report "Timer flag did not auto-clear on INTA" severity failure;

        -- Pushbutton flags remain pending until software writes IFG.
        acknowledge;
        assert ifg_value = x"28"
            report "KEY1 flag was incorrectly auto-cleared" severity failure;
        bus_write(C_IFG_ADDR, x"00000020");
        assert ifg_value = x"20" and irq_type = C_IRQ_TYPE_KEY3
            report "Software IFG clear or KEY3 selection failed" severity failure;

        -- Disabling an IE bit clears its corresponding pending IFG.
        bus_write(C_IE_ADDR, x"00000004");
        assert intr = '0' and ifg_value = x"00"
            report "IE clear did not clear pending KEY3 IFG" severity failure;

        -- Timer event coincident with its acknowledge must not be lost.
        bus_write(C_IFG_ADDR, x"00000004");
        timer_event <= '1';
        inta <= '1';
        clock_edge;
        timer_event <= '0';
        inta <= '0';
        assert ifg_value = x"04" and intr = '1'
            report "Simultaneous timer event/clear lost the new event"
            severity failure;

        -- UART slots retain their documented priority/address compatibility.
        bus_write(C_IE_ADDR, x"00000003");
        bus_write(C_IFG_ADDR, x"00000003");
        assert irq_type = x"08" report "RX priority/type mismatch" severity failure;

        address <= x"0000202F";
        read_en <= '1';
        wait for 1 ns;
        assert hit = '0' and read_data = x"00000000"
            report "Interrupt controller decoded an unmapped address"
            severity failure;

        report "STAGE 6 INTERRUPT CONTROLLER PASS" severity note;
        std.env.stop;
        wait;
    end process;
end architecture;
