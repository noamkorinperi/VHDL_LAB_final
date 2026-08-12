library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_Multiplier16 is
end tb_Multiplier16;

architecture behavior of tb_Multiplier16 is

    component Multiplier16
        Port (
            A_i   : in  STD_LOGIC_VECTOR (15 downto 0);
            B_i   : in  STD_LOGIC_VECTOR (15 downto 0);
            Res_o : out STD_LOGIC_VECTOR (31 downto 0)
        );
    end component;

    signal A_i   : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal B_i   : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal Res_o : STD_LOGIC_VECTOR(31 downto 0);

    constant T_WAIT : time := 10 ns;

    type test_vec_array_t is array (natural range <>) of std_logic_vector(15 downto 0);

    constant TEST_VALUES : test_vec_array_t := (
        x"0000",
        x"0001",
        x"0002",
        x"000F",
        x"00FF",
        x"0100",
        x"0101",
        x"0F0F",
        x"1234",
        x"5678",
        x"7FFF",
        x"8000",
        x"AAAA",
        x"5555",
        x"FF00",
        x"FFFF"
    );

begin

    -- Unit Under Test
    uut: Multiplier16
        port map (
            A_i   => A_i,
            B_i   => B_i,
            Res_o => Res_o
        );

    stim_proc: process

        procedure check_mult(
            constant A_val     : in std_logic_vector(15 downto 0);
            constant B_val     : in std_logic_vector(15 downto 0);
            constant test_name : in string
        ) is
            variable expected : unsigned(31 downto 0);
        begin
            A_i <= A_val;
            B_i <= B_val;

            wait for T_WAIT;

            expected := unsigned(A_val) * unsigned(B_val);

            assert Res_o = std_logic_vector(expected)
                report "FAILED: " & test_name
                severity error;
        end procedure;

    begin

        report "Starting Multiplier16 testbench..." severity note;

        --------------------------------------------------------------------
        -- Directed tests: important edge and structure cases
        --------------------------------------------------------------------
        check_mult(x"0000", x"0000", "0 * 0");
        check_mult(x"0001", x"0001", "1 * 1");
        check_mult(x"0005", x"0004", "small low-byte multiplication");
        check_mult(x"00FF", x"00FF", "max low-byte * max low-byte");
        check_mult(x"0100", x"0100", "high-byte * high-byte");
        check_mult(x"0200", x"0003", "high-byte * low value");
        check_mult(x"00FF", x"FF00", "low-byte * high-byte stress");
        check_mult(x"FFFF", x"0001", "max * 1");
        check_mult(x"FFFF", x"00FF", "max * low-byte max");
        check_mult(x"8000", x"0002", "MSB set * 2");
        check_mult(x"7FFF", x"0002", "large positive-looking value * 2");
        check_mult(x"AAAA", x"5555", "alternating bit patterns");
        check_mult(x"1234", x"5678", "mixed random-looking values");
        check_mult(x"FFFF", x"FFFF", "maximum 16-bit * maximum 16-bit");

        --------------------------------------------------------------------
        -- Cross-product test set:
        -- tests many combinations of low/high bytes, carries, and boundaries
        --------------------------------------------------------------------
        for i in TEST_VALUES'range loop
            for j in TEST_VALUES'range loop
                check_mult(TEST_VALUES(i), TEST_VALUES(j), "cross-product directed test");
            end loop;
        end loop;

        --------------------------------------------------------------------
        -- Extra pseudo-random deterministic tests
        --------------------------------------------------------------------
        for k in 0 to 255 loop
            check_mult(
                std_logic_vector(to_unsigned((k * 251 + 17) mod 65536, 16)),
                std_logic_vector(to_unsigned((k * 193 + 91) mod 65536, 16)),
                "pseudo-random deterministic test"
            );
        end loop;

        report "All Multiplier16 tests passed successfully." severity note;

        wait;
    end process;

end behavior;