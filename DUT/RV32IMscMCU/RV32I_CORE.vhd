--============================================================================
-- RV32IM single-cycle core with an external data bus and multi-cycle divider.
-- Ordinary RV32I/MUL instructions remain single-cycle. DIV/DIVU/REM/REMU hold
-- the PC and defer register write-back until the accelerator returns a result.
--============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.cond_compilation_package.all;
use work.const_package.all;

entity RV32I_CORE is
    generic (
        WORD_GRANULARITY : boolean := G_WORD_GRANULARITY;
        MODELSIM         : integer := G_MODELSIM;
        DATA_BUS_WIDTH   : integer := 32;
        ITCM_ADDR_WIDTH  : integer := G_ADDRWIDTH;
        DTCM_ADDR_WIDTH  : integer := G_ADDRWIDTH;
        PC_WIDTH         : integer := G_PC_WIDTH;
        MA_WIDTH         : integer := G_MA_WIDTH;
        DATA_WORDS_NUM   : integer := G_DATA_WORDSNUM;
        CLK_CNT_WIDTH    : integer := 16;
        ITCM_INIT_FILE   : string := "ITCM.hex";
        DTCM_INIT_FILE   : string := "DTCM.hex"
    );
    port (
        rst_i    : in std_logic;
        clk_i    : in std_logic;
        divclk_i : in std_logic;

        dbus_rdata_i : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        dbus_addr_o  : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        dbus_wdata_o : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        dbus_read_o  : out std_logic;
        dbus_write_o : out std_logic;

        pc_o          : out std_logic_vector(PC_WIDTH-1 downto 0);
        instruction_o : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        RegWrite_ctrl_o : out std_logic;
        MemWrite_ctrl_o : out std_logic;
        Branch_ctrl_o   : out std_logic;
        read_data1_o  : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        read_data2_o  : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        write_data_o  : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        alu_res_o     : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        brTaken_o     : out std_logic;
        dtcm_addr_o    : out std_logic_vector(DTCM_ADDR_WIDTH-1 downto 0);
        dtcm_data_wr_o : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        dtcm_data_rd_o : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        div_busy_o     : out std_logic;
        div_done_o     : out std_logic;
        div_result_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        mclk_cnt_o     : out std_logic_vector(CLK_CNT_WIDTH-1 downto 0)
    );
end entity;

architecture structure of RV32I_CORE is
    signal pc_w, pc_plus4_w : std_logic_vector(PC_WIDTH-1 downto 0);
    signal instruction_w    : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal read_data1_w, read_data2_w : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal sign_extend_w, execute_result_w, writeback_result_w : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal addr_gen_w : std_logic_vector(PC_WIDTH-1 downto 0);

    signal alu_src_w, branch_w, jal_w, jalr_w : std_logic;
    signal reg_write_control_w, reg_write_effective_w : std_logic;
    signal reg_dst_w, branch_taken_w : std_logic;
    signal mem_write_w, mem_to_reg_w, mem_read_w : std_logic;
    signal upper_im_w : std_logic_vector(1 downto 0);
    signal alu_op_w   : std_logic_vector(4 downto 0);
    signal mul_op_w   : std_logic;
    signal div_op_w   : std_logic_vector(2 downto 0);

    signal div_instruction_w : std_logic;
    signal div_start_w, div_busy_w, div_done_w : std_logic;
    signal div_active_q : std_logic := '0';
    signal div_retired_q : std_logic := '0';
    signal div_result_w : std_logic_vector(31 downto 0);
    signal divider_hold_w : std_logic;

    signal mclk_cnt_q : std_logic_vector(CLK_CNT_WIDTH-1 downto 0) := (others => '0');

    attribute keep : boolean;
    attribute keep of pc_w, instruction_w, read_data1_w, read_data2_w : signal is true;
    attribute keep of execute_result_w, reg_write_effective_w, mem_write_w : signal is true;
    attribute keep of mem_read_w, branch_w, branch_taken_w, mul_op_w : signal is true;
    attribute keep of div_busy_w, div_done_w, div_result_w, divider_hold_w : signal is true;
begin
    fetch_unit : entity work.Ifetch
        generic map (
            WORD_GRANULARITY => WORD_GRANULARITY,
            DATA_BUS_WIDTH   => DATA_BUS_WIDTH,
            PC_WIDTH         => PC_WIDTH,
            ITCM_ADDR_WIDTH  => ITCM_ADDR_WIDTH,
            WORDS_NUM        => DATA_WORDS_NUM,
            INIT_FILE        => ITCM_INIT_FILE
        )
        port map (
            clk_i         => clk_i,
            rst_i         => rst_i,
            divider_hold_i => divider_hold_w,
            addr_gen_i    => addr_gen_w,
            Branch_ctrl_i => branch_w,
            brTaken_i     => branch_taken_w,
            Jal_ctrl_i    => jal_w,
            Jalr_ctrl_i   => jalr_w,
            alu_res_i     => execute_result_w,
            pc_o          => pc_w,
            pc_plus4_o    => pc_plus4_w,
            instruction_o => instruction_w
        );

    decode_unit : entity work.Idecode
        generic map (PC_WIDTH => PC_WIDTH, DATA_BUS_WIDTH => DATA_BUS_WIDTH)
        port map (
            clk_i          => clk_i,
            rst_i          => rst_i,
            pc_plus4_i     => pc_plus4_w,
            instruction_i  => instruction_w,
            dtcm_data_rd_i => dbus_rdata_i,
            alu_res_i      => writeback_result_w,
            RegDst_ctrl_i  => reg_dst_w,
            RegWrite_ctrl_i=> reg_write_effective_w,
            MemtoReg_ctrl_i=> mem_to_reg_w,
            read_data1_o   => read_data1_w,
            read_data2_o   => read_data2_w,
            SignExt_o      => sign_extend_w
        );

    control_unit : entity work.control
        port map (
            instruction_i   => instruction_w,
            RegDst_ctrl_o    => reg_dst_w,
            ALUSrc_ctrl_o    => alu_src_w,
            MemtoReg_ctrl_o  => mem_to_reg_w,
            RegWrite_ctrl_o  => reg_write_control_w,
            MemRead_ctrl_o   => mem_read_w,
            MemWrite_ctrl_o  => mem_write_w,
            Branch_ctrl_o    => branch_w,
            Jal_ctrl_o       => jal_w,
            Jalr_ctrl_o      => jalr_w,
            UpperIm_ctrl_o   => upper_im_w,
            MULOp_ctrl_o     => mul_op_w,
            DivOp_ctrl_o     => div_op_w,
            ALUOp_ctrl_o     => alu_op_w
        );

    execute_unit : entity work.Execute
        generic map (DATA_BUS_WIDTH => DATA_BUS_WIDTH, PC_WIDTH => PC_WIDTH)
        port map (
            read_data1_i   => read_data1_w,
            read_data2_i   => read_data2_w,
            sign_extend_i  => sign_extend_w,
            UpperIm_ctrl_i => upper_im_w,
            MULOp_ctrl_i   => mul_op_w,
            ALUOp_ctrl_i   => alu_op_w,
            ALUSrc_ctrl_i  => alu_src_w,
            pc_i           => pc_w,
            brTaken_o      => branch_taken_w,
            alu_res_o      => execute_result_w,
            addr_gen_o     => addr_gen_w
        );

    divider : entity work.divider_accelerator
        port map (
            sys_clk_i   => clk_i,
            div_clk_i   => divclk_i,
            reset_i     => rst_i,
            start_i     => div_start_w,
            operation_i => div_op_w,
            dividend_i  => read_data1_w,
            divisor_i   => read_data2_w,
            busy_o      => div_busy_w,
            done_o      => div_done_w,
            result_o    => div_result_w
        );

    div_instruction_w <= '1' when div_op_w /= DIVOP_NONE else '0';
    -- Keep the divider instruction visible through the clock edge that writes
    -- its result. div_retired_q releases fetch only after that edge and also
    -- prevents the still-visible instruction from launching a second request.
    div_start_w       <= div_instruction_w and not div_active_q and not div_retired_q;
    divider_hold_w    <= div_instruction_w and not div_retired_q;
    writeback_result_w <= div_result_w when div_instruction_w = '1' else execute_result_w;
    reg_write_effective_w <= reg_write_control_w when div_instruction_w = '0' else div_done_w;

    process (clk_i, rst_i)
    begin
        if rst_i = '1' then
            div_active_q <= '0';
            div_retired_q <= '0';
        elsif rising_edge(clk_i) then
            if div_done_w = '1' then
                div_active_q <= '0';
                div_retired_q <= '1';
            elsif div_retired_q = '1' then
                -- One release cycle advances fetch to the following
                -- instruction. Clearing here also supports two divider
                -- instructions placed back-to-back.
                div_retired_q <= '0';
            elsif div_start_w = '1' then
                div_active_q <= '1';
                div_retired_q <= '0';
            end if;
        end if;
    end process;

    process (clk_i, rst_i)
    begin
        if rst_i = '1' then
            mclk_cnt_q <= (others => '0');
        elsif rising_edge(clk_i) then
            mclk_cnt_q <= mclk_cnt_q + 1;
        end if;
    end process;

    -- Full byte address leaves the core.  Address truncation happens only at
    -- the DTCM boundary inside mcu_interconnect.
    dbus_addr_o  <= execute_result_w;
    dbus_wdata_o <= read_data2_w;
    dbus_read_o  <= mem_read_w;
    dbus_write_o <= mem_write_w;

    pc_o              <= pc_w;
    instruction_o     <= instruction_w;
    RegWrite_ctrl_o   <= reg_write_effective_w;
    MemWrite_ctrl_o   <= mem_write_w;
    Branch_ctrl_o     <= branch_w;
    read_data1_o      <= read_data1_w;
    read_data2_o      <= read_data2_w;
    write_data_o      <= dbus_rdata_i when mem_to_reg_w = '1' else writeback_result_w;
    alu_res_o         <= writeback_result_w;
    brTaken_o         <= branch_taken_w;
    dtcm_addr_o       <= execute_result_w(DTCM_ADDR_WIDTH+1 downto 2);
    dtcm_data_wr_o    <= read_data2_w;
    dtcm_data_rd_o    <= dbus_rdata_i;
    div_busy_o        <= div_busy_w;
    div_done_o        <= div_done_w;
    div_result_o      <= div_result_w;
    mclk_cnt_o        <= mclk_cnt_q;
end architecture;
