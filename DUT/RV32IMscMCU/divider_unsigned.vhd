library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- 32-cycle restoring unsigned divider.  The wrapper handles signed operands
-- and all architectural corner cases; this block is deliberately unsigned.
entity divider_unsigned is
    port (
        clk_i       : in  std_logic;
        reset_i     : in  std_logic;
        start_i     : in  std_logic;
        dividend_i  : in  std_logic_vector(31 downto 0);
        divisor_i   : in  std_logic_vector(31 downto 0);
        busy_o      : out std_logic;
        done_o      : out std_logic;
        quotient_o  : out std_logic_vector(31 downto 0);
        remainder_o : out std_logic_vector(31 downto 0)
    );
end entity;

architecture rtl of divider_unsigned is
    signal dividend_q  : unsigned(31 downto 0) := (others => '0');
    signal divisor_q   : unsigned(31 downto 0) := (others => '0');
    signal quotient_q  : unsigned(31 downto 0) := (others => '0');
    signal remainder_q : unsigned(32 downto 0) := (others => '0');
    signal count_q     : unsigned(5 downto 0)  := (others => '0');
    signal busy_q      : std_logic := '0';
    signal done_q      : std_logic := '0';
begin
    process (clk_i, reset_i)
        variable shifted_remainder_v : unsigned(32 downto 0);
        variable shifted_dividend_v  : unsigned(31 downto 0);
        variable next_quotient_v     : unsigned(31 downto 0);
        variable next_remainder_v    : unsigned(32 downto 0);
    begin
        if reset_i = '1' then
            dividend_q  <= (others => '0');
            divisor_q   <= (others => '0');
            quotient_q  <= (others => '0');
            remainder_q <= (others => '0');
            count_q     <= (others => '0');
            busy_q      <= '0';
            done_q      <= '0';
        elsif rising_edge(clk_i) then
            done_q <= '0';

            if start_i = '1' and busy_q = '0' then
                dividend_q  <= unsigned(dividend_i);
                divisor_q   <= unsigned(divisor_i);
                quotient_q  <= (others => '0');
                remainder_q <= (others => '0');
                count_q     <= (others => '0');
                busy_q      <= '1';
            elsif busy_q = '1' then
                shifted_remainder_v := remainder_q(31 downto 0) & dividend_q(31);
                shifted_dividend_v  := dividend_q(30 downto 0) & '0';
                next_quotient_v     := quotient_q(30 downto 0) & '0';
                next_remainder_v    := shifted_remainder_v;

                if shifted_remainder_v >= ('0' & divisor_q) then
                    next_remainder_v := shifted_remainder_v - ('0' & divisor_q);
                    next_quotient_v(0) := '1';
                end if;

                dividend_q  <= shifted_dividend_v;
                quotient_q  <= next_quotient_v;
                remainder_q <= next_remainder_v;

                if count_q = 31 then
                    busy_q <= '0';
                    done_q <= '1';
                else
                    count_q <= count_q + 1;
                end if;
            end if;
        end if;
    end process;

    busy_o      <= busy_q;
    done_o      <= done_q;
    quotient_o  <= std_logic_vector(quotient_q);
    remainder_o <= std_logic_vector(remainder_q(31 downto 0));
end architecture;
