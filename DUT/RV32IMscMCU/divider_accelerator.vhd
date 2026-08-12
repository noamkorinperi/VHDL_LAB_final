library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.const_package.all;

-- Two-clock divider accelerator.  A toggle handshake transfers one request
-- from the CPU clock domain to DIVCLK and one result back.  Operands and the
-- result are held stable while the corresponding toggle crosses the domains.
entity divider_accelerator is
    port (
        sys_clk_i  : in  std_logic;
        div_clk_i  : in  std_logic;
        reset_i    : in  std_logic;
        start_i    : in  std_logic;
        operation_i: in  std_logic_vector(2 downto 0);
        dividend_i : in  std_logic_vector(31 downto 0);
        divisor_i  : in  std_logic_vector(31 downto 0);
        busy_o     : out std_logic;
        done_o     : out std_logic;
        result_o   : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of divider_accelerator is
    signal request_toggle_sys_q : std_logic := '0';
    signal dividend_sys_q       : std_logic_vector(31 downto 0) := (others => '0');
    signal divisor_sys_q        : std_logic_vector(31 downto 0) := (others => '0');
    signal operation_sys_q      : std_logic_vector(2 downto 0) := DIVOP_NONE;

    signal ack_sync1_sys_q : std_logic := '0';
    signal ack_sync2_sys_q : std_logic := '0';
    signal ack_seen_sys_q  : std_logic := '0';
    signal done_sys_q      : std_logic := '0';
    signal result_sys_q    : std_logic_vector(31 downto 0) := (others => '0');

    signal request_sync1_div_q : std_logic := '0';
    signal request_sync2_div_q : std_logic := '0';
    signal request_seen_div_q  : std_logic := '0';
    signal ack_toggle_div_q    : std_logic := '0';
    signal result_hold_div_q   : std_logic_vector(31 downto 0) := (others => '0');

    signal operation_div_q : std_logic_vector(2 downto 0) := DIVOP_NONE;
    signal negate_quotient_div_q  : std_logic := '0';
    signal negate_remainder_div_q : std_logic := '0';

    signal core_start_div_q : std_logic := '0';
    signal core_busy_div_w  : std_logic;
    signal core_done_div_w  : std_logic;
    signal core_dividend_w  : std_logic_vector(31 downto 0) := (others => '0');
    signal core_divisor_w   : std_logic_vector(31 downto 0) := (others => '0');
    signal core_quotient_w  : std_logic_vector(31 downto 0);
    signal core_remainder_w : std_logic_vector(31 downto 0);

    function twos_complement(value : std_logic_vector(31 downto 0))
        return std_logic_vector is
    begin
        return std_logic_vector(unsigned(not value) + 1);
    end function;
begin
    -- CPU clock domain: capture a request only when the previous transaction
    -- has been acknowledged, then pulse done when the returned toggle arrives.
    process (sys_clk_i, reset_i)
    begin
        if reset_i = '1' then
            request_toggle_sys_q <= '0';
            dividend_sys_q       <= (others => '0');
            divisor_sys_q        <= (others => '0');
            operation_sys_q      <= DIVOP_NONE;
            ack_sync1_sys_q      <= '0';
            ack_sync2_sys_q      <= '0';
            ack_seen_sys_q       <= '0';
            done_sys_q           <= '0';
            result_sys_q         <= (others => '0');
        elsif rising_edge(sys_clk_i) then
            ack_sync1_sys_q <= ack_toggle_div_q;
            ack_sync2_sys_q <= ack_sync1_sys_q;
            done_sys_q      <= '0';

            if start_i = '1' and request_toggle_sys_q = ack_sync2_sys_q then
                dividend_sys_q       <= dividend_i;
                divisor_sys_q        <= divisor_i;
                operation_sys_q      <= operation_i;
                request_toggle_sys_q <= not request_toggle_sys_q;
            end if;

            if ack_sync2_sys_q /= ack_seen_sys_q then
                result_sys_q   <= result_hold_div_q;
                ack_seen_sys_q <= ack_sync2_sys_q;
                done_sys_q     <= '1';
            end if;
        end if;
    end process;

    -- DIVCLK domain: synchronize the request, handle RISC-V exceptional cases,
    -- and otherwise launch one 32-cycle unsigned division.
    process (div_clk_i, reset_i)
        variable signed_operation_v : boolean;
        variable dividend_abs_v     : std_logic_vector(31 downto 0);
        variable divisor_abs_v      : std_logic_vector(31 downto 0);
        variable selected_result_v  : std_logic_vector(31 downto 0);
    begin
        if reset_i = '1' then
            request_sync1_div_q     <= '0';
            request_sync2_div_q     <= '0';
            request_seen_div_q      <= '0';
            ack_toggle_div_q        <= '0';
            result_hold_div_q       <= (others => '0');
            operation_div_q         <= DIVOP_NONE;
            negate_quotient_div_q   <= '0';
            negate_remainder_div_q  <= '0';
            core_start_div_q        <= '0';
            core_dividend_w         <= (others => '0');
            core_divisor_w          <= (others => '0');
        elsif rising_edge(div_clk_i) then
            request_sync1_div_q <= request_toggle_sys_q;
            request_sync2_div_q <= request_sync1_div_q;
            core_start_div_q    <= '0';

            if request_sync2_div_q /= request_seen_div_q and core_busy_div_w = '0' then
                request_seen_div_q <= request_sync2_div_q;
                operation_div_q    <= operation_sys_q;
                signed_operation_v := operation_sys_q = DIVOP_DIV or operation_sys_q = DIVOP_REM;

                if divisor_sys_q = x"00000000" then
                    if operation_sys_q = DIVOP_DIV or operation_sys_q = DIVOP_DIVU then
                        result_hold_div_q <= (others => '1');
                    else
                        result_hold_div_q <= dividend_sys_q;
                    end if;
                    ack_toggle_div_q <= request_sync2_div_q;
                elsif signed_operation_v and dividend_sys_q = x"80000000" and divisor_sys_q = x"FFFFFFFF" then
                    if operation_sys_q = DIVOP_DIV then
                        result_hold_div_q <= x"80000000";
                    else
                        result_hold_div_q <= (others => '0');
                    end if;
                    ack_toggle_div_q <= request_sync2_div_q;
                else
                    dividend_abs_v := dividend_sys_q;
                    divisor_abs_v  := divisor_sys_q;
                    if signed_operation_v and dividend_sys_q(31) = '1' then
                        dividend_abs_v := twos_complement(dividend_sys_q);
                    end if;
                    if signed_operation_v and divisor_sys_q(31) = '1' then
                        divisor_abs_v := twos_complement(divisor_sys_q);
                    end if;

                    core_dividend_w <= dividend_abs_v;
                    core_divisor_w  <= divisor_abs_v;
                    if signed_operation_v and
                       (dividend_sys_q(31) xor divisor_sys_q(31)) = '1' then
                        negate_quotient_div_q <= '1';
                    else
                        negate_quotient_div_q <= '0';
                    end if;
                    if signed_operation_v and dividend_sys_q(31) = '1' then
                        negate_remainder_div_q <= '1';
                    else
                        negate_remainder_div_q <= '0';
                    end if;
                    core_start_div_q <= '1';
                end if;
            elsif core_done_div_w = '1' then
                if operation_div_q = DIVOP_DIV or operation_div_q = DIVOP_DIVU then
                    selected_result_v := core_quotient_w;
                    if negate_quotient_div_q = '1' then
                        selected_result_v := twos_complement(selected_result_v);
                    end if;
                else
                    selected_result_v := core_remainder_w;
                    if negate_remainder_div_q = '1' then
                        selected_result_v := twos_complement(selected_result_v);
                    end if;
                end if;
                result_hold_div_q <= selected_result_v;
                ack_toggle_div_q  <= request_seen_div_q;
            end if;
        end if;
    end process;

    divider_core : entity work.divider_unsigned
        port map (
            clk_i       => div_clk_i,
            reset_i     => reset_i,
            start_i     => core_start_div_q,
            dividend_i  => core_dividend_w,
            divisor_i   => core_divisor_w,
            busy_o      => core_busy_div_w,
            done_o      => core_done_div_w,
            quotient_o  => core_quotient_w,
            remainder_o => core_remainder_w
        );

    busy_o   <= '1' when request_toggle_sys_q /= ack_sync2_sys_q else '0';
    done_o   <= done_sys_q;
    result_o <= result_sys_q;
end architecture;
