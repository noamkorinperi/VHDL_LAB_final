library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MEM_WB_REG is
    generic(
        DATA_BUS_WIDTH : integer := 32;
        PC_WIDTH       : integer := 10
    );
    port(
        -- inputs
        clk_i           : in  std_logic;
        rst_i           : in  std_logic;

        -- data inputs from MEM stage
        pc_i            : in  std_logic_vector(PC_WIDTH-1 downto 0);
        pc_plus4_i      : in  std_logic_vector(PC_WIDTH-1 downto 0);
        instruction_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        alu_res_i       : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        dtcm_data_rd_i  : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        mul_res_i       : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        -- destination register
        rd_i            : in  std_logic_vector(4 downto 0);

        -- control inputs needed for WB stage
        RegDst_ctrl_i   : in  std_logic;
        MemtoReg_ctrl_i : in  std_logic;
        RegWrite_ctrl_i : in  std_logic;
        MULOp_ctrl_i    : in  std_logic;

        -- outputs to WB stage
        pc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
        pc_plus4_o      : out std_logic_vector(PC_WIDTH-1 downto 0);
        instruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        alu_res_o       : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        dtcm_data_rd_o  : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        mul_res_o       : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        rd_o            : out std_logic_vector(4 downto 0);

        RegDst_ctrl_o   : out std_logic;
        MemtoReg_ctrl_o : out std_logic;
        RegWrite_ctrl_o : out std_logic;
        MULOp_ctrl_o    : out std_logic
    );
end MEM_WB_REG;

architecture behavior of MEM_WB_REG is

begin

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then

            pc_o            <= (others => '0');
            pc_plus4_o      <= (others => '0');
            instruction_o   <= (others => '0');

            alu_res_o       <= (others => '0');
            dtcm_data_rd_o  <= (others => '0');
            mul_res_o       <= (others => '0');

            rd_o            <= (others => '0');

            RegDst_ctrl_o   <= '0';
            MemtoReg_ctrl_o <= '0';
            RegWrite_ctrl_o <= '0';
            MULOp_ctrl_o    <= '0';

            else

            pc_o            <= pc_i;
            pc_plus4_o      <= pc_plus4_i;
            instruction_o   <= instruction_i;

            alu_res_o       <= alu_res_i;
            dtcm_data_rd_o  <= dtcm_data_rd_i;
            mul_res_o       <= mul_res_i;

            rd_o            <= rd_i;

            RegDst_ctrl_o   <= RegDst_ctrl_i;
            MemtoReg_ctrl_o <= MemtoReg_ctrl_i;
            RegWrite_ctrl_o <= RegWrite_ctrl_i;
            MULOp_ctrl_o    <= MULOp_ctrl_i;

            end if;
        end if;
    end process;

end behavior;
