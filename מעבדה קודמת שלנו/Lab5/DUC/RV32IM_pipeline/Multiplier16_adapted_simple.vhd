--============================================================================
-- LAB5 Part 2 - Partial M-extension multiplier (mul), PIPELINED across two stages
-- (Figure 6 of the task).
--   Stage 1 (EX  stage) : the four 8-bit embedded multiplies  (P0..P3)
--   Stage 2 (MEM stage) : the adder tree  M = P1+P2 ; RESULT = P0 + (M<<8) + (P3<<16)
--
-- A pipeline register (the EX/MEM register, in the structural core) sits between the
-- two stages, so 'mul' is a 2-cycle operation whose result becomes available in
-- MEM/WB - exactly like a load. A dependent instruction immediately after a 'mul'
-- therefore needs one stall (mul-use hazard) and is then forwarded from MEM/WB.
--
-- The four partial products are packed/unpacked as P = {P3,P2,P1,P0}.
--============================================================================

--------------------------------------------------------------------------------
-- Stage 1 : four 8-bit multiplications (inferred as embedded multipliers)
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Multiplier16_s1 is
    Port (
        A_i : in  STD_LOGIC_VECTOR (15 downto 0);
        B_i : in  STD_LOGIC_VECTOR (15 downto 0);
        P_o : out STD_LOGIC_VECTOR (63 downto 0)   -- {P3,P2,P1,P0}
    );
end Multiplier16_s1;

architecture Behavioral of Multiplier16_s1 is
    signal A_low_s, A_high_s : std_logic_vector(7 downto 0);
    signal B_low_s, B_high_s : std_logic_vector(7 downto 0);
    signal P0_s, P1_s, P2_s, P3_s : std_logic_vector(15 downto 0);
begin
    A_low_s  <= A_i(7 downto 0);
    A_high_s <= A_i(15 downto 8);
    B_low_s  <= B_i(7 downto 0);
    B_high_s <= B_i(15 downto 8);

    -- Quartus infers four embedded 8-bit multipliers here
    P0_s <= A_low_s  * B_low_s;
    P1_s <= A_low_s  * B_high_s;
    P2_s <= A_high_s * B_low_s;
    P3_s <= A_high_s * B_high_s;

    -- pack for the EX/MEM pipeline register
    P_o <= P3_s & P2_s & P1_s & P0_s;
end Behavioral;

--------------------------------------------------------------------------------
-- Stage 2 : the adder tree
--------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Multiplier16_s2 is
    Port (
        P_i   : in  STD_LOGIC_VECTOR (63 downto 0); -- {P3,P2,P1,P0}
        Res_o : out STD_LOGIC_VECTOR (31 downto 0)
    );
end Multiplier16_s2;

architecture Behavioral of Multiplier16_s2 is
    signal P0_s, P1_s, P2_s, P3_s : std_logic_vector(15 downto 0);
    signal M_s                    : std_logic_vector(16 downto 0); -- 17-bit to hold P1+P2 carry
    signal P0_32_s, M_32_s, P3_32_s : std_logic_vector(31 downto 0);
begin
    -- unpack the Stage-1 partial products
    P0_s <= P_i(15 downto 0);
    P1_s <= P_i(31 downto 16);
    P2_s <= P_i(47 downto 32);
    P3_s <= P_i(63 downto 48);

    -- middle sum
    M_s <= ('0' & P1_s) + ('0' & P2_s);

    -- align to 32 bits : RESULT = P0 + (M<<8) + (P3<<16)
    P0_32_s <= x"0000" & P0_s;
    M_32_s  <= "0000000" & M_s & x"00";
    P3_32_s <= P3_s & x"0000";

    Res_o <= P0_32_s + M_32_s + P3_32_s;
end Behavioral;
