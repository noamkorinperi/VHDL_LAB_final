library ieee;
use ieee.std_logic_1164.all;
use std.env.all;
use work.const_package.all;

entity tb_stage3_divider_unit is end entity;

architecture sim of tb_stage3_divider_unit is
    signal sysclk, divclk, reset, start, busy, done : std_logic := '0';
    signal operation : std_logic_vector(2 downto 0) := DIVOP_NONE;
    signal dividend, divisor, result : std_logic_vector(31 downto 0) := (others => '0');
begin
    sysclk <= not sysclk after 20 ns;
    divclk <= not divclk after 10 ns;
    dut : entity work.divider_accelerator
        port map (
            sys_clk_i => sysclk, div_clk_i => divclk, reset_i => reset,
            start_i => start, operation_i => operation, dividend_i => dividend,
            divisor_i => divisor, busy_o => busy, done_o => done, result_o => result
        );

    stimulus : process
        procedure check_div(constant op : std_logic_vector(2 downto 0);
                            constant a, b, expected : std_logic_vector(31 downto 0);
                            constant label_text : string) is
        begin
            wait until rising_edge(sysclk);
            operation <= op; dividend <= a; divisor <= b; start <= '1';
            wait until rising_edge(sysclk); start <= '0';
            wait until done = '1' for 3 us;
            assert done = '1' report "Stage 3 timeout: " & label_text severity failure;
            wait for 1 ns;
            assert result = expected report "Stage 3 wrong result: " & label_text severity failure;
        end procedure;
    begin
        reset <= '1'; wait for 100 ns; reset <= '0';
        check_div(DIVOP_DIV,  x"00000014", x"00000003", x"00000006", "20 / 3");
        check_div(DIVOP_REM,  x"FFFFFFEC", x"00000003", x"FFFFFFFE", "-20 rem 3");
        check_div(DIVOP_DIV,  x"FFFFFFEC", x"00000003", x"FFFFFFFA", "-20 / 3");
        check_div(DIVOP_DIVU, x"FFFFFFF0", x"00000010", x"0FFFFFFF", "unsigned quotient");
        check_div(DIVOP_REMU, x"00000014", x"00000006", x"00000002", "unsigned remainder");
        check_div(DIVOP_DIV,  x"12345678", x"00000000", x"FFFFFFFF", "division by zero");
        check_div(DIVOP_REM,  x"12345678", x"00000000", x"12345678", "remainder by zero");
        check_div(DIVOP_DIV,  x"80000000", x"FFFFFFFF", x"80000000", "signed overflow quotient");
        check_div(DIVOP_REM,  x"80000000", x"FFFFFFFF", x"00000000", "signed overflow remainder");
        report "STAGE 3 DIVIDER UNIT PASS" severity note;
        stop;
    end process;
end architecture;
