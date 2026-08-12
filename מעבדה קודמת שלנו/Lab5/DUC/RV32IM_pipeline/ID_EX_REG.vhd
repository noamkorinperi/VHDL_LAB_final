library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ID_EX_REG is
    generic(
        DATA_BUS_WIDTH : integer := 32;
        PC_WIDTH       : integer := 10
    );
    port(
        -- inputs
        clk_i           : in  std_logic;
        rst_i           : in  std_logic;
        Stall_i         : in  std_logic;
        Flush_i         : in  std_logic;

        -- data inputs from ID stage
        pc_i            : in  std_logic_vector(PC_WIDTH-1 downto 0);
        pc_plus4_i      : in  std_logic_vector(PC_WIDTH-1 downto 0);
        instruction_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        read_data1_i    : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        read_data2_i    : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        sign_extend_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        rs1_i           : in  std_logic_vector(4 downto 0);
        rs2_i           : in  std_logic_vector(4 downto 0);
        rd_i            : in  std_logic_vector(4 downto 0);

        -- control inputs from CONTROL
        RegDst_ctrl_i   : in  std_logic;
        ALUSrc_ctrl_i   : in  std_logic;
        MemtoReg_ctrl_i : in  std_logic;
        RegWrite_ctrl_i : in  std_logic;
        MemRead_ctrl_i  : in  std_logic;
        MemWrite_ctrl_i : in  std_logic;
        Branch_ctrl_i   : in  std_logic;
        Jal_ctrl_i      : in  std_logic;
        Jalr_ctrl_i     : in  std_logic;
        UpperIm_ctrl_i  : in  std_logic_vector(1 downto 0);
        MULOp_ctrl_i    : in  std_logic;
        ALUOp_ctrl_i    : in  std_logic_vector(4 downto 0);

        -- data outputs to EX stage
        pc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
        pc_plus4_o      : out std_logic_vector(PC_WIDTH-1 downto 0);
        instruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        read_data1_o    : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        read_data2_o    : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        sign_extend_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        rs1_o           : out std_logic_vector(4 downto 0);
        rs2_o           : out std_logic_vector(4 downto 0);
        rd_o            : out std_logic_vector(4 downto 0);

        -- control outputs to EX / MEM / WB stages
        RegDst_ctrl_o   : out std_logic;
        ALUSrc_ctrl_o   : out std_logic;
        MemtoReg_ctrl_o : out std_logic;
        RegWrite_ctrl_o : out std_logic;
        MemRead_ctrl_o  : out std_logic;
        MemWrite_ctrl_o : out std_logic;
        Branch_ctrl_o   : out std_logic;
        Jal_ctrl_o      : out std_logic;
        Jalr_ctrl_o     : out std_logic;
        UpperIm_ctrl_o  : out std_logic_vector(1 downto 0);
        MULOp_ctrl_o    : out std_logic;
        ALUOp_ctrl_o    : out std_logic_vector(4 downto 0)
    );
end ID_EX_REG;

architecture behavior of ID_EX_REG is

begin

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then

            pc_o            <= (others => '0');
            pc_plus4_o      <= (others => '0');
            instruction_o   <= (others => '0');

            read_data1_o    <= (others => '0');
            read_data2_o    <= (others => '0');
            sign_extend_o   <= (others => '0');

            rs1_o           <= (others => '0');
            rs2_o           <= (others => '0');
            rd_o            <= (others => '0');

            RegDst_ctrl_o   <= '0';
            ALUSrc_ctrl_o   <= '0';
            MemtoReg_ctrl_o <= '0';
            RegWrite_ctrl_o <= '0';
            MemRead_ctrl_o  <= '0';
            MemWrite_ctrl_o <= '0';
            Branch_ctrl_o   <= '0';
            Jal_ctrl_o      <= '0';
            Jalr_ctrl_o     <= '0';
            UpperIm_ctrl_o  <= (others => '0');
            MULOp_ctrl_o    <= '0';
            ALUOp_ctrl_o    <= (others => '0');

            elsif Flush_i = '1' or Stall_i = '1' then

                pc_o            <= (others => '0');
                pc_plus4_o      <= (others => '0');
                instruction_o   <= (others => '0');

                read_data1_o    <= (others => '0');
                read_data2_o    <= (others => '0');
                sign_extend_o   <= (others => '0');

                rs1_o           <= (others => '0');
                rs2_o           <= (others => '0');
                rd_o            <= (others => '0');

                RegDst_ctrl_o   <= '0';
                ALUSrc_ctrl_o   <= '0';
                MemtoReg_ctrl_o <= '0';
                RegWrite_ctrl_o <= '0';
                MemRead_ctrl_o  <= '0';
                MemWrite_ctrl_o <= '0';
                Branch_ctrl_o   <= '0';
                Jal_ctrl_o      <= '0';
                Jalr_ctrl_o     <= '0';
                UpperIm_ctrl_o  <= (others => '0');
                MULOp_ctrl_o    <= '0';
                ALUOp_ctrl_o    <= (others => '0');

            else

                pc_o            <= pc_i;
                pc_plus4_o      <= pc_plus4_i;
                instruction_o   <= instruction_i;

                read_data1_o    <= read_data1_i;
                read_data2_o    <= read_data2_i;
                sign_extend_o   <= sign_extend_i;

                rs1_o           <= rs1_i;
                rs2_o           <= rs2_i;
                rd_o            <= rd_i;

                RegDst_ctrl_o   <= RegDst_ctrl_i;
                ALUSrc_ctrl_o   <= ALUSrc_ctrl_i;
                MemtoReg_ctrl_o <= MemtoReg_ctrl_i;
                RegWrite_ctrl_o <= RegWrite_ctrl_i;
                MemRead_ctrl_o  <= MemRead_ctrl_i;
                MemWrite_ctrl_o <= MemWrite_ctrl_i;
                Branch_ctrl_o   <= Branch_ctrl_i;
                Jal_ctrl_o      <= Jal_ctrl_i;
                Jalr_ctrl_o     <= Jalr_ctrl_i;
                UpperIm_ctrl_o  <= UpperIm_ctrl_i;
                MULOp_ctrl_o    <= MULOp_ctrl_i;
                ALUOp_ctrl_o    <= ALUOp_ctrl_i;

            end if;

        end if;
    end process;

end behavior;