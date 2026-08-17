library ieee;
use ieee.std_logic_1164.all;

use work.mcu_memory_map_pkg.all;

-- Basic priority interrupt controller from Figures 13-14 of the project
-- specification. UART register positions remain implemented/reserved even
-- though no UART interrupt sources are connected in the mandatory design.
entity interrupt_controller is
    port (
        clk_i        : in  std_logic;
        reset_i      : in  std_logic;
        address_i    : in  std_logic_vector(31 downto 0);
        write_data_i : in  std_logic_vector(31 downto 0);
        read_i       : in  std_logic;
        write_i      : in  std_logic;
        read_data_o  : out std_logic_vector(31 downto 0);
        hit_o        : out std_logic;

        timer_event_i : in std_logic;
        key_event_i   : in std_logic_vector(2 downto 0);
        gie_i         : in std_logic;
        inta_i        : in std_logic;

        intr_o : out std_logic;
        type_o : out std_logic_vector(7 downto 0);
        ie_o   : out std_logic_vector(7 downto 0);
        ifg_o  : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of interrupt_controller is
    signal ie_q, ifg_q : std_logic_vector(5 downto 0) := (others => '0');
    signal enabled_pending_w : std_logic_vector(5 downto 0);
    signal type_w : std_logic_vector(7 downto 0);
begin
    enabled_pending_w <= ie_q and ifg_q;

    -- Lowest vector number has the highest priority. RX/TX are retained for
    -- address compatibility but remain inactive unless software sets IFG.
    process (all)
    begin
        type_w <= C_IRQ_TYPE_RESET;
        if enabled_pending_w(C_IRQ_RX_BIT) = '1' then
            type_w <= x"08";
        elsif enabled_pending_w(C_IRQ_TX_BIT) = '1' then
            type_w <= x"0C";
        elsif enabled_pending_w(C_IRQ_TIMER_BIT) = '1' then
            type_w <= C_IRQ_TYPE_TIMER;
        elsif enabled_pending_w(C_IRQ_KEY1_BIT) = '1' then
            type_w <= C_IRQ_TYPE_KEY1;
        elsif enabled_pending_w(C_IRQ_KEY2_BIT) = '1' then
            type_w <= C_IRQ_TYPE_KEY2;
        elsif enabled_pending_w(C_IRQ_KEY3_BIT) = '1' then
            type_w <= C_IRQ_TYPE_KEY3;
        end if;
    end process;

    process (clk_i, reset_i)
        variable next_ifg_v : std_logic_vector(5 downto 0);
    begin
        if reset_i = '1' then
            ie_q <= (others => '0');
            ifg_q <= (others => '0');
        elsif rising_edge(clk_i) then
            if write_i = '1' and address_i = C_IE_ADDR then
                ie_q <= write_data_i(5 downto 0);
            end if;

            next_ifg_v := ifg_q;
            if write_i = '1' and address_i = C_IFG_ADDR then
                -- The supplied applications use read/AND/write clearing.
                next_ifg_v := write_data_i(5 downto 0);
            end if;

            -- Synchronous sources are cleared automatically on service.
            -- Pushbutton flags intentionally require software clearing.
            if inta_i = '1' and type_w = C_IRQ_TYPE_TIMER then
                next_ifg_v(C_IRQ_TIMER_BIT) := '0';
            elsif inta_i = '1' and type_w = x"08" then
                next_ifg_v(C_IRQ_RX_BIT) := '0';
            elsif inta_i = '1' and type_w = x"0C" then
                next_ifg_v(C_IRQ_TX_BIT) := '0';
            end if;

            -- A new event wins over a simultaneous clear so no event is lost.
            if timer_event_i = '1' then
                next_ifg_v(C_IRQ_TIMER_BIT) := '1';
            end if;
            if key_event_i(0) = '1' then
                next_ifg_v(C_IRQ_KEY1_BIT) := '1';
            end if;
            if key_event_i(1) = '1' then
                next_ifg_v(C_IRQ_KEY2_BIT) := '1';
            end if;
            if key_event_i(2) = '1' then
                next_ifg_v(C_IRQ_KEY3_BIT) := '1';
            end if;
            ifg_q <= next_ifg_v;
        end if;
    end process;

    process (all)
    begin
        read_data_o <= (others => '0');
        if read_i = '1' then
            case address_i is
                when C_IE_ADDR   => read_data_o(5 downto 0) <= ie_q;
                when C_IFG_ADDR  => read_data_o(5 downto 0) <= ifg_q;
                when C_TYPE_ADDR => read_data_o(7 downto 0) <= type_w;
                when others => null;
            end case;
        end if;
    end process;

    hit_o <= '1' when address_i = C_IE_ADDR or address_i = C_IFG_ADDR or
                      address_i = C_TYPE_ADDR else '0';
    intr_o <= '1' when gie_i = '1' and enabled_pending_w /= "000000" else '0';
    type_o <= type_w;
    ie_o <= "00" & ie_q;
    ifg_o <= "00" & ifg_q;
end architecture;
