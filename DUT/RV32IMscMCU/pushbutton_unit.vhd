library ieee;
use ieee.std_logic_1164.all;

use work.mcu_memory_map_pkg.all;

-- KEY1-KEY3 are active-low on the DE10-Standard. Each input passes through a
-- two-flop synchronizer and must then remain changed for DEBOUNCE_CYCLES
-- sysclk edges. Software reads active-high pressed states at PORT_PB[2:0].
entity pushbutton_unit is
    generic (
        DEBOUNCE_CYCLES : positive := 200000
    );
    port (
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;
        address_i   : in  std_logic_vector(31 downto 0);
        read_i      : in  std_logic;
        read_data_o : out std_logic_vector(31 downto 0);
        hit_o       : out std_logic;

        keys_n_i      : in  std_logic_vector(2 downto 0);
        buttons_o     : out std_logic_vector(2 downto 0);
        press_event_o : out std_logic_vector(2 downto 0)
    );
end entity;

architecture rtl of pushbutton_unit is
    type debounce_counter_array_t is array (0 to 2) of
        integer range 0 to DEBOUNCE_CYCLES-1;

    signal key_sync1_n_q, key_sync2_n_q : std_logic_vector(2 downto 0) :=
        (others => '1');
    signal buttons_q, press_event_q : std_logic_vector(2 downto 0) :=
        (others => '0');
    signal debounce_count_q : debounce_counter_array_t := (others => 0);
begin
    process (clk_i, reset_i)
        variable sampled_pressed_v : std_logic;
    begin
        if reset_i = '1' then
            key_sync1_n_q <= (others => '1');
            key_sync2_n_q <= (others => '1');
            buttons_q <= (others => '0');
            press_event_q <= (others => '0');
            debounce_count_q <= (others => 0);
        elsif rising_edge(clk_i) then
            key_sync1_n_q <= keys_n_i;
            key_sync2_n_q <= key_sync1_n_q;
            press_event_q <= (others => '0');

            for index in 0 to 2 loop
                sampled_pressed_v := not key_sync2_n_q(index);
                if sampled_pressed_v = buttons_q(index) then
                    debounce_count_q(index) <= 0;
                elsif debounce_count_q(index) = DEBOUNCE_CYCLES-1 then
                    buttons_q(index) <= sampled_pressed_v;
                    debounce_count_q(index) <= 0;
                    if sampled_pressed_v = '1' then
                        press_event_q(index) <= '1';
                    end if;
                else
                    debounce_count_q(index) <= debounce_count_q(index) + 1;
                end if;
            end loop;
        end if;
    end process;

    process (all)
    begin
        read_data_o <= (others => '0');
        if read_i = '1' and address_i = C_PORT_PB_ADDR then
            read_data_o(2 downto 0) <= buttons_q;
        end if;
    end process;

    hit_o <= '1' when address_i = C_PORT_PB_ADDR else '0';
    buttons_o <= buttons_q;
    press_event_o <= press_event_q;
end architecture;
