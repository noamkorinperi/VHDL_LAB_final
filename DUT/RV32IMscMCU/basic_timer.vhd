library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.mcu_memory_map_pkg.all;

-- Basic Timer defined by Figures 7-8 of the project specification.
-- BTCMPR0 is the up-mode period/top value and BTCMPR1 is the PWM transition.
-- BTIFG is emitted as a one-sysclk event; the phase-6 interrupt controller
-- latches that event into its software-visible IFG register.
entity basic_timer is
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        address_i    : in  std_logic_vector(31 downto 0);
        write_data_i : in  std_logic_vector(31 downto 0);
        read_i       : in  std_logic;
        write_i      : in  std_logic;
        read_data_o  : out std_logic_vector(31 downto 0);
        hit_o        : out std_logic;

        capin1_i : in std_logic;
        capin2_i : in std_logic;

        pwm_o           : out std_logic;
        btifg_event_o   : out std_logic;
        compare0_event_o: out std_logic;
        compare1_event_o: out std_logic;
        capture_event_o : out std_logic;

        counter_o : out std_logic_vector(31 downto 0);
        capture_o : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of basic_timer is
    signal btctl1_q  : std_logic_vector(7 downto 0) := (others => '0');
    signal btctl2_q  : std_logic_vector(7 downto 0) := (others => '0');
    signal btcmpr0_q : std_logic_vector(31 downto 0) := (others => '0');
    signal btcmpr1_q : std_logic_vector(31 downto 0) := (others => '0');
    signal btcapr_q  : std_logic_vector(31 downto 0) := (others => '0');
    signal btcnt_q   : unsigned(31 downto 0) := (others => '0');

    signal prescaler_q : unsigned(2 downto 0) := (others => '0');
    signal timer_tick_w : std_logic;

    signal capin1_sync1_q, capin1_sync2_q : std_logic := '0';
    signal capin2_sync1_q, capin2_sync2_q : std_logic := '0';
    signal selected_capture_w, selected_capture_prev_q : std_logic := '0';

    signal pwm_q, btifg_event_q : std_logic := '0';
    signal compare0_event_q, compare1_event_q, capture_event_q : std_logic := '0';

    function is_timer_address(address : std_logic_vector(31 downto 0))
        return boolean is
    begin
        return address = C_BTCTL1_ADDR or address = C_BTCTL2_ADDR or
               address = C_BTCMPR0_ADDR or address = C_BTCMPR1_ADDR or
               address = C_BTCAPR_ADDR;
    end function;
begin
    -- BTSSEL: 00=SMCLK, 01=SMCLK/2, 10=SMCLK/4, 11=SMCLK/8.
    timer_tick_w <= '1' when btctl1_q(4 downto 3) = "00" else
                    prescaler_q(0) when btctl1_q(4 downto 3) = "01" else
                    '1' when btctl1_q(4 downto 3) = "10" and
                                  prescaler_q(1 downto 0) = "11" else
                    '1' when btctl1_q(4 downto 3) = "11" and
                                  prescaler_q = "111" else
                    '0';

    with btctl2_q(1 downto 0) select selected_capture_w <=
        capin1_sync2_q when "00",
        capin2_sync2_q when "01",
        '1' when "10",
        '0' when others;

    process (clk_i, reset_i)
        variable compare0_v, compare1_v, capture_v : boolean;
        variable clear_v : boolean;
    begin
        if reset_i = '1' then
            btctl1_q <= (others => '0');
            btctl2_q <= (others => '0');
            btcmpr0_q <= (others => '0');
            btcmpr1_q <= (others => '0');
            btcapr_q <= (others => '0');
            btcnt_q <= (others => '0');
            prescaler_q <= (others => '0');
            capin1_sync1_q <= '0';
            capin1_sync2_q <= '0';
            capin2_sync1_q <= '0';
            capin2_sync2_q <= '0';
            selected_capture_prev_q <= '0';
            pwm_q <= '0';
            btifg_event_q <= '0';
            compare0_event_q <= '0';
            compare1_event_q <= '0';
            capture_event_q <= '0';
        elsif rising_edge(clk_i) then
            prescaler_q <= prescaler_q + 1;
            capin1_sync1_q <= capin1_i;
            capin1_sync2_q <= capin1_sync1_q;
            capin2_sync1_q <= capin2_i;
            capin2_sync2_q <= capin2_sync1_q;
            selected_capture_prev_q <= selected_capture_w;

            compare0_v := false;
            compare1_v := false;
            capture_v := false;
            clear_v := write_i = '1' and address_i = C_BTCTL1_ADDR and
                       write_data_i(2) = '1';

            btifg_event_q <= '0';
            compare0_event_q <= '0';
            compare1_event_q <= '0';
            capture_event_q <= '0';

            if write_i = '1' then
                case address_i is
                    when C_BTCTL1_ADDR =>
                        btctl1_q <= write_data_i(7 downto 0);
                        -- BTCLR is a write-one command and reads back as zero.
                        btctl1_q(2) <= '0';
                        if btctl1_q(6) = '0' and write_data_i(6) = '1' then
                            -- Initial level for Mode0 is low; for Mode1 high.
                            pwm_q <= write_data_i(7);
                        end if;
                    when C_BTCTL2_ADDR =>
                        btctl2_q <= "0000" & write_data_i(3 downto 0);
                    when C_BTCMPR0_ADDR =>
                        btcmpr0_q <= write_data_i;
                    when C_BTCMPR1_ADDR =>
                        btcmpr1_q <= write_data_i;
                    when C_BTCAPR_ADDR =>
                        btcapr_q <= write_data_i;
                    when others => null;
                end case;
            end if;

            if clear_v then
                btcnt_q <= (others => '0');
                prescaler_q <= (others => '0');
                if write_data_i(6) = '1' then
                    pwm_q <= write_data_i(7);
                end if;
            elsif btctl1_q(5) = '0' and timer_tick_w = '1' then
                compare0_v := std_logic_vector(btcnt_q) = btcmpr0_q;
                compare1_v := std_logic_vector(btcnt_q) = btcmpr1_q;

                if compare0_v then
                    btcnt_q <= (others => '0');
                else
                    btcnt_q <= btcnt_q + 1;
                end if;

                if btctl1_q(6) = '1' then
                    -- Mode0: set at CMP1, reset at CMP0.
                    -- Mode1: reset at CMP1, set at CMP0.
                    if compare0_v then
                        pwm_q <= btctl1_q(7);
                    elsif compare1_v then
                        pwm_q <= not btctl1_q(7);
                    end if;
                end if;
            end if;

            case btctl2_q(3 downto 2) is
                when "01" =>
                    capture_v := selected_capture_prev_q = '0' and
                                 selected_capture_w = '1';
                when "10" =>
                    capture_v := selected_capture_prev_q = '1' and
                                 selected_capture_w = '0';
                when others =>
                    capture_v := false;
            end case;

            if capture_v then
                btcapr_q <= std_logic_vector(btcnt_q);
            end if;

            if compare0_v then compare0_event_q <= '1'; end if;
            if compare1_v then compare1_event_q <= '1'; end if;
            if capture_v then capture_event_q <= '1'; end if;

            case btctl1_q(1 downto 0) is
                when "00" =>
                    if compare0_v then btifg_event_q <= '1'; end if;
                when "01" =>
                    if compare1_v then btifg_event_q <= '1'; end if;
                when others =>
                    if capture_v then btifg_event_q <= '1'; end if;
            end case;
        end if;
    end process;

    process (all)
    begin
        read_data_o <= (others => '0');
        if read_i = '1' then
            case address_i is
                when C_BTCTL1_ADDR  => read_data_o(7 downto 0) <= btctl1_q;
                when C_BTCTL2_ADDR  => read_data_o(7 downto 0) <= btctl2_q;
                when C_BTCMPR0_ADDR => read_data_o <= btcmpr0_q;
                when C_BTCMPR1_ADDR => read_data_o <= btcmpr1_q;
                when C_BTCAPR_ADDR  => read_data_o <= btcapr_q;
                when others => null;
            end case;
        end if;
    end process;

    hit_o <= '1' when is_timer_address(address_i) else '0';
    pwm_o <= pwm_q;
    btifg_event_o <= btifg_event_q;
    compare0_event_o <= compare0_event_q;
    compare1_event_o <= compare1_event_q;
    capture_event_o <= capture_event_q;
    counter_o <= std_logic_vector(btcnt_q);
    capture_o <= btcapr_q;
end architecture;
