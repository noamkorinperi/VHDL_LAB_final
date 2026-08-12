LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Multiplier16 is
    Port (
        A_i   : in  STD_LOGIC_VECTOR (15 downto 0);
        B_i   : in  STD_LOGIC_VECTOR (15 downto 0);
        Res_o : out STD_LOGIC_VECTOR (31 downto 0)
    );
end Multiplier16;

architecture Behavioral of Multiplier16 is
    -- Signals for 8-bit chunks
    signal A_low, A_high : std_logic_vector(7 downto 0);
    signal B_low, B_high : std_logic_vector(7 downto 0);

    -- Stage 1: Partial products (8-bit * 8-bit = 16-bit)
    signal P0, P1, P2, P3 : std_logic_vector(15 downto 0);
    
    -- Stage 2: Middle sum (16-bit + 16-bit requires 17-bit to avoid overflow)
    signal M              : std_logic_vector(16 downto 0); 

    -- Signals for final 32-bit alignment
    signal P0_32          : std_logic_vector(31 downto 0);
    signal M_32           : std_logic_vector(31 downto 0);
    signal P3_32          : std_logic_vector(31 downto 0);
    signal Result_32      : std_logic_vector(31 downto 0);

    --=========================================================
    -- SignalTap debug preservation
    --=========================================================
    attribute keep : boolean;

    attribute keep of A_low     : signal is true;
    attribute keep of A_high    : signal is true;
    attribute keep of B_low     : signal is true;
    attribute keep of B_high    : signal is true;

    attribute keep of P0        : signal is true;
    attribute keep of P1        : signal is true;
    attribute keep of P2        : signal is true;
    attribute keep of P3        : signal is true;

    attribute keep of M         : signal is true;
    attribute keep of Result_32 : signal is true;

begin
    -- Slice inputs into 8-bit chunks
    A_low  <= A_i(7 downto 0);
    A_high <= A_i(15 downto 8);
    B_low  <= B_i(7 downto 0);
    B_high <= B_i(15 downto 8);

    -- Stage 1: Four 8-bit multiplications
    -- Quartus will infer embedded multipliers here
    P0 <= A_low * B_low;
    P1 <= A_low * B_high;
    P2 <= A_high * B_low;
    P3 <= A_high * B_high;

    -- Stage 2: Combine middle terms
		-- (M is 17 bit as an addition of two 16 bit terms - needs one more bit for overflow)
    M <= ("0" & P1) + ("0" & P2);

    -- Align all terms to 32-bits before final addition 
    -- (Concatenation acts as an efficient logical shift left)
	-- Because  RESULT = P0 + (M << 8) + (P3 << 16)
    P0_32 <= x"0000" & P0;			-- Extend P0 to 32 bits (add 16 zeroes left)
    M_32  <= "0000000" & M & x"00"; -- Shift M left by 8 	(add 8 zeroes right)	and extend to 32 bit	(add 7 zeroes left )
    P3_32 <= P3 & x"0000";          -- Shift P3 left by 16	(add 16 zeroes right)

    -- Final addition
    Result_32 <= P0_32 + M_32 + P3_32;

    -- Cast back to standard logic vector for output
    Res_o <= std_logic_vector(Result_32);


end Behavioral;