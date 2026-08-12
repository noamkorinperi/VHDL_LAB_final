library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity IF_ID_REG is
    generic(
        DATA_BUS_WIDTH : integer := 32;
        PC_WIDTH       : integer := 10
    );
    port(
        -- inputs
        clk_i           : in  std_logic;
        rst_i           : in  std_logic;
        IFIDWrite_i     : in  std_logic;
        Flush_i         : in  std_logic;

        pc_i            : in  std_logic_vector(PC_WIDTH-1 downto 0);
        pc_plus4_i      : in  std_logic_vector(PC_WIDTH-1 downto 0);
        instruction_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        -- outputs
        pc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
        pc_plus4_o      : out std_logic_vector(PC_WIDTH-1 downto 0);
        instruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0)
    );
end IF_ID_REG;

architecture behavior of IF_ID_REG is

    signal pc_q          : std_logic_vector(PC_WIDTH-1 downto 0);
    signal pc_plus4_q    : std_logic_vector(PC_WIDTH-1 downto 0);
    signal instruction_q : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

begin

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
            pc_q          <= (others => '0');
            pc_plus4_q    <= (others => '0');
            instruction_q <= (others => '0');

            elsif Flush_i = '1' then
                pc_q          <= (others => '0');
                pc_plus4_q    <= (others => '0');
                instruction_q <= (others => '0');

            elsif IFIDWrite_i = '1' then
                pc_q          <= pc_i;
                pc_plus4_q    <= pc_plus4_i;
                instruction_q <= instruction_i;

            end if;

        end if;
    end process;

    pc_o          <= pc_q;
    pc_plus4_o    <= pc_plus4_q;
    instruction_o <= instruction_q;

end behavior;