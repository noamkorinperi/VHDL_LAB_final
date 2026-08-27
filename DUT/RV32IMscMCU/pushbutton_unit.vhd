library ieee;
use ieee.std_logic_1164.all;

use work.mcu_memory_map_pkg.all;

-- KEY1-KEY3 are active-low and already hardware-debounced on the board. The
-- instructor therefore requires no extra synchronizer/debounce chain. Software
-- reads active-high pressed states at PORT_PB[2:0], while interrupts are
-- generated once on the physical release transition (raw KEY 0 -> 1).
entity pushbutton_unit is
    port (
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;
        address_i   : in  std_logic_vector(31 downto 0);
        read_i      : in  std_logic;
        read_data_o : out std_logic_vector(31 downto 0);
        hit_o       : out std_logic;

        keys_n_i      : in  std_logic_vector(2 downto 0);
        buttons_o     : out std_logic_vector(2 downto 0);
        release_event_o : out std_logic_vector(2 downto 0)
    );
end entity;

architecture rtl of pushbutton_unit is
    signal keys_prev_n_q : std_logic_vector(2 downto 0) := (others => '1');
    signal buttons_q, release_event_q : std_logic_vector(2 downto 0) :=
        (others => '0');
begin
    process (clk_i, reset_i)
    begin
        if reset_i = '1' then
            keys_prev_n_q <= (others => '1');
            buttons_q <= (others => '0');
            release_event_q <= (others => '0');
        elsif rising_edge(clk_i) then
            buttons_q <= not keys_n_i;
            release_event_q <= keys_n_i and not keys_prev_n_q;
            keys_prev_n_q <= keys_n_i;
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
    release_event_o <= release_event_q;
end architecture;
