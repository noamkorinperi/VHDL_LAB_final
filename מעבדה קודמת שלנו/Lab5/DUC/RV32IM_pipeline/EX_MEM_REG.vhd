library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity EX_MEM_REG is
    generic(
        DATA_BUS_WIDTH : integer := 32;
        PC_WIDTH       : integer := 10
    );
    port(
        -- inputs
        clk_i           : in  std_logic;
        rst_i           : in  std_logic;
        Flush_i         : in  std_logic;

        -- data inputs from EX stage
        pc_i            : in  std_logic_vector(PC_WIDTH-1 downto 0);
        pc_plus4_i      : in  std_logic_vector(PC_WIDTH-1 downto 0);
        instruction_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        alu_res_i       : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        addr_gen_i      : in  std_logic_vector(PC_WIDTH-1 downto 0);
        brTaken_i       : in  std_logic;

        -- store data, usually forwarded rs2 value
        read_data2_i    : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        -- MUL stage-1 partial products {P3,P2,P1,P0}
        mul_pp_i        : in  std_logic_vector(63 downto 0);

        -- destination register
        rd_i            : in  std_logic_vector(4 downto 0);

        -- control inputs
        RegDst_ctrl_i   : in  std_logic;
        MemtoReg_ctrl_i : in  std_logic;
        RegWrite_ctrl_i : in  std_logic;
        MemRead_ctrl_i  : in  std_logic;
        MemWrite_ctrl_i : in  std_logic;
        Branch_ctrl_i   : in  std_logic;
        Jal_ctrl_i      : in  std_logic;
        Jalr_ctrl_i     : in  std_logic;
        MULOp_ctrl_i    : in  std_logic;

        -- data outputs to MEM stage
        pc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
        pc_plus4_o      : out std_logic_vector(PC_WIDTH-1 downto 0);
        instruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        alu_res_o       : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        addr_gen_o      : out std_logic_vector(PC_WIDTH-1 downto 0);
        brTaken_o       : out std_logic;

        read_data2_o    : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        mul_pp_o        : out std_logic_vector(63 downto 0);

        rd_o            : out std_logic_vector(4 downto 0);

        -- control outputs to MEM/WB stages
        RegDst_ctrl_o   : out std_logic;
        MemtoReg_ctrl_o : out std_logic;
        RegWrite_ctrl_o : out std_logic;
        MemRead_ctrl_o  : out std_logic;
        MemWrite_ctrl_o : out std_logic;
        Branch_ctrl_o   : out std_logic;
        Jal_ctrl_o      : out std_logic;
        Jalr_ctrl_o     : out std_logic;
        MULOp_ctrl_o    : out std_logic
    );
end EX_MEM_REG;

architecture behavior of EX_MEM_REG is

begin

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then

            pc_o            <= (others => '0');
            pc_plus4_o      <= (others => '0');
            instruction_o   <= (others => '0');

            alu_res_o       <= (others => '0');
            addr_gen_o      <= (others => '0');
            brTaken_o       <= '0';

            read_data2_o    <= (others => '0');
            mul_pp_o        <= (others => '0');

            rd_o            <= (others => '0');

            RegDst_ctrl_o   <= '0';
            MemtoReg_ctrl_o <= '0';
            RegWrite_ctrl_o <= '0';
            MemRead_ctrl_o  <= '0';
            MemWrite_ctrl_o <= '0';
            Branch_ctrl_o   <= '0';
            Jal_ctrl_o      <= '0';
            Jalr_ctrl_o     <= '0';
            MULOp_ctrl_o    <= '0';

            elsif Flush_i = '1' then

                pc_o            <= (others => '0');
                pc_plus4_o      <= (others => '0');
                instruction_o   <= (others => '0');

                alu_res_o       <= (others => '0');
                addr_gen_o      <= (others => '0');
                brTaken_o       <= '0';

                read_data2_o    <= (others => '0');
                mul_pp_o        <= (others => '0');

                rd_o            <= (others => '0');

                RegDst_ctrl_o   <= '0';
                MemtoReg_ctrl_o <= '0';
                RegWrite_ctrl_o <= '0';
                MemRead_ctrl_o  <= '0';
                MemWrite_ctrl_o <= '0';
                Branch_ctrl_o   <= '0';
                Jal_ctrl_o      <= '0';
                Jalr_ctrl_o     <= '0';
                MULOp_ctrl_o    <= '0';

            else

                pc_o            <= pc_i;
                pc_plus4_o      <= pc_plus4_i;
                instruction_o   <= instruction_i;

                alu_res_o       <= alu_res_i;
                addr_gen_o      <= addr_gen_i;
                brTaken_o       <= brTaken_i;

                read_data2_o    <= read_data2_i;
                mul_pp_o        <= mul_pp_i;

                rd_o            <= rd_i;

                RegDst_ctrl_o   <= RegDst_ctrl_i;
                MemtoReg_ctrl_o <= MemtoReg_ctrl_i;
                RegWrite_ctrl_o <= RegWrite_ctrl_i;
                MemRead_ctrl_o  <= MemRead_ctrl_i;
                MemWrite_ctrl_o <= MemWrite_ctrl_i;
                Branch_ctrl_o   <= Branch_ctrl_i;
                Jal_ctrl_o      <= Jal_ctrl_i;
                Jalr_ctrl_o     <= Jalr_ctrl_i;
                MULOp_ctrl_o    <= MULOp_ctrl_i;

            end if;

        end if;
    end process;

end behavior;
