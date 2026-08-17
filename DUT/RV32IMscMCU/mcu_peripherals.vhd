library ieee;
use ieee.std_logic_1164.all;

-- Structural MMIO peripheral block. The interrupt event outputs are exposed
-- now so stage 6 can connect them without changing the timer/button interfaces.
entity mcu_peripherals is
    generic (
        PB_DEBOUNCE_CYCLES : positive := 250000
    );
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        address_i    : in  std_logic_vector(31 downto 0);
        write_data_i : in  std_logic_vector(31 downto 0);
        read_i       : in  std_logic;
        write_i      : in  std_logic;
        read_data_o  : out std_logic_vector(31 downto 0);
        hit_o        : out std_logic;

        switches_i : in std_logic_vector(7 downto 0);
        keys_n_i   : in std_logic_vector(2 downto 0);
        capin1_i   : in std_logic;
        capin2_i   : in std_logic;

        ledr_o : out std_logic_vector(7 downto 0);
        hex0_o : out std_logic_vector(6 downto 0);
        hex1_o : out std_logic_vector(6 downto 0);
        hex2_o : out std_logic_vector(6 downto 0);
        hex3_o : out std_logic_vector(6 downto 0);
        hex4_o : out std_logic_vector(6 downto 0);
        hex5_o : out std_logic_vector(6 downto 0);

        pwm_o         : out std_logic;
        timer_event_o : out std_logic;
        key_event_o   : out std_logic_vector(2 downto 0);
        button_state_o: out std_logic_vector(2 downto 0);

        timer_count_o   : out std_logic_vector(31 downto 0);
        timer_capture_o : out std_logic_vector(31 downto 0)
    );
end entity;

architecture structural of mcu_peripherals is
    signal gpio_rdata_w, timer_rdata_w, button_rdata_w : std_logic_vector(31 downto 0);
    signal gpio_hit_w, timer_hit_w, button_hit_w : std_logic;
begin
    gpio : entity work.gpio_peripheral
        port map (
            clk_i => clk_i,
            reset_i => reset_i,
            address_i => address_i,
            write_data_i => write_data_i,
            read_i => read_i,
            write_i => write_i,
            read_data_o => gpio_rdata_w,
            hit_o => gpio_hit_w,
            switches_i => switches_i,
            ledr_o => ledr_o,
            hex0_o => hex0_o,
            hex1_o => hex1_o,
            hex2_o => hex2_o,
            hex3_o => hex3_o,
            hex4_o => hex4_o,
            hex5_o => hex5_o
        );

    timer : entity work.basic_timer
        port map (
            clk_i => clk_i,
            reset_i => reset_i,
            address_i => address_i,
            write_data_i => write_data_i,
            read_i => read_i,
            write_i => write_i,
            read_data_o => timer_rdata_w,
            hit_o => timer_hit_w,
            capin1_i => capin1_i,
            capin2_i => capin2_i,
            pwm_o => pwm_o,
            btifg_event_o => timer_event_o,
            compare0_event_o => open,
            compare1_event_o => open,
            capture_event_o => open,
            counter_o => timer_count_o,
            capture_o => timer_capture_o
        );

    pushbuttons : entity work.pushbutton_unit
        generic map (
            DEBOUNCE_CYCLES => PB_DEBOUNCE_CYCLES
        )
        port map (
            clk_i => clk_i,
            reset_i => reset_i,
            address_i => address_i,
            read_i => read_i,
            read_data_o => button_rdata_w,
            hit_o => button_hit_w,
            keys_n_i => keys_n_i,
            buttons_o => button_state_o,
            press_event_o => key_event_o
        );

    read_data_o <= gpio_rdata_w when gpio_hit_w = '1' else
                   timer_rdata_w when timer_hit_w = '1' else
                   button_rdata_w when button_hit_w = '1' else
                   (others => '0');

    hit_o <= gpio_hit_w or timer_hit_w or button_hit_w;
end architecture;
