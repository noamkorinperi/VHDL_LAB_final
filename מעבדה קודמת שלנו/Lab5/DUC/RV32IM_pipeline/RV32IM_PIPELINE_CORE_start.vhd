--============================================================================
-- RV32IM Pipelined Core - first integration skeleton
-- Based on the single-cycle core structure, sliced into 5 pipeline stages.
--
-- NOTE:
-- 1. This file assumes you already have these entities in the work library:
--      Ifetch               -- adapted version with PCWrite_i
--      Idecode              -- adapted pipeline version with WB inputs
--      control
--      Execute
--      dmemory
--      IF_ID_REG
--      ID_EX_REG
--      EX_MEM_REG
--      MEM_WB_REG
--      stall_unit
--      forwarding_unit
--      pipeline_muxes
--
-- 2. This version still uses the current single-cycle style Execute.
--    The two-stage multiplier will be integrated later.
--============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.cond_compilation_package.all;
use work.aux_package.all;
use work.const_package.all;

entity RV32IM_PIPELINE_CORE is
    generic(
        WORD_GRANULARITY : boolean := G_WORD_GRANULARITY;
        MODELSIM         : integer := G_MODELSIM;
        DATA_BUS_WIDTH   : integer := 32;
        ITCM_ADDR_WIDTH  : integer := G_ADDRWIDTH;
        DTCM_ADDR_WIDTH  : integer := G_ADDRWIDTH;
        PC_WIDTH         : integer := G_PC_WIDTH;
        MA_WIDTH         : integer := G_MA_WIDTH;
        DATA_WORDS_NUM   : integer := G_DATA_WORDSNUM;
        CLK_CNT_WIDTH    : integer := 16
    );
    port(
        -- Inputs
        rst_i             : in  std_logic;
        clk_i             : in  std_logic;

        -- Breakpoint input for SignalTap trigger. Word-granularity, normally driven by SW7..SW0.
        BPADDR_i          : in  std_logic_vector(7 downto 0) := (others => '0');

        -- Debug / SignalTap outputs
        pc_o              : out std_logic_vector(PC_WIDTH-1 downto 0);
        instruction_o     : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        RegWrite_ctrl_o   : out std_logic;
        MemWrite_ctrl_o   : out std_logic;
        Branch_ctrl_o     : out std_logic;

        read_data1_o      : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        read_data2_o      : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        write_data_o      : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        alu_res_o         : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        brTaken_o         : out std_logic;

        dtcm_addr_o       : out std_logic_vector(DTCM_ADDR_WIDTH-1 downto 0);
        dtcm_data_wr_o    : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        dtcm_data_rd_o    : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        mclk_cnt_o        : out std_logic_vector(CLK_CNT_WIDTH-1 downto 0);
        CLKCNT_o          : out std_logic_vector(CLK_CNT_WIDTH-1 downto 0);

        -- Pipeline performance counters / SignalTap trigger
        STCNT_o           : out std_logic_vector(15 downto 0);
        FHCNT_o           : out std_logic_vector(15 downto 0);
        STRIGGER_o        : out std_logic;

        -- Pipeline-stage debug taps for SignalTap (combinational mirrors of the
        -- existing pipeline-register stage outputs; do NOT affect core behavior).
        IDpc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
        IDinstruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        EXpc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
        EXinstruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        MEMpc_o           : out std_logic_vector(PC_WIDTH-1 downto 0);
        MEMinstruction_o  : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        WBpc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
        WBinstruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0)
    );
end RV32IM_PIPELINE_CORE;

architecture structure of RV32IM_PIPELINE_CORE is

    ------------------------------------------------------------------------
    -- Clock / reset
    ------------------------------------------------------------------------
    signal mclk_w          : std_logic;
    signal pll_locked_w    : std_logic;
    signal rst_core_w      : std_logic;

    signal mclk_cnt_q      : std_logic_vector(CLK_CNT_WIDTH-1 downto 0);
    signal stcnt_q         : std_logic_vector(15 downto 0);
    signal fhcnt_q         : std_logic_vector(15 downto 0);
    signal bpaddr_q        : std_logic_vector(7 downto 0);
    signal strigger_s      : std_logic;

    ------------------------------------------------------------------------
    -- IF stage
    ------------------------------------------------------------------------
    signal if_pc_s          : std_logic_vector(PC_WIDTH-1 downto 0);
    signal if_pc_plus4_s    : std_logic_vector(PC_WIDTH-1 downto 0);
    signal if_instruction_s : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    ------------------------------------------------------------------------
    -- IF/ID pipeline register outputs
    ------------------------------------------------------------------------
    signal if_id_pc_s          : std_logic_vector(PC_WIDTH-1 downto 0);
    signal if_id_pc_plus4_s    : std_logic_vector(PC_WIDTH-1 downto 0);
    signal if_id_instruction_s : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    ------------------------------------------------------------------------
    -- ID stage signals
    ------------------------------------------------------------------------
    signal id_read_data1_s   : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal id_read_data2_s   : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal id_sign_extend_s  : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    signal id_rs1_s          : std_logic_vector(4 downto 0);
    signal id_rs2_s          : std_logic_vector(4 downto 0);
    signal id_rd_s           : std_logic_vector(4 downto 0);
    signal id_opcode_s       : std_logic_vector(6 downto 0);
    signal id_uses_rs1_s     : std_logic;
    signal id_uses_rs2_s     : std_logic;

    -- Control outputs in ID stage
    signal id_RegDst_ctrl_s   : std_logic;
    signal id_ALUSrc_ctrl_s   : std_logic;
    signal id_MemtoReg_ctrl_s : std_logic;
    signal id_RegWrite_ctrl_s : std_logic;
    signal id_MemRead_ctrl_s  : std_logic;
    signal id_MemWrite_ctrl_s : std_logic;
    signal id_Branch_ctrl_s   : std_logic;
    signal id_Jal_ctrl_s      : std_logic;
    signal id_Jalr_ctrl_s     : std_logic;
    signal id_UpperIm_ctrl_s  : std_logic_vector(1 downto 0);
    signal id_MULOp_ctrl_s    : std_logic;
    signal id_ALUOp_ctrl_s    : std_logic_vector(4 downto 0);

    ------------------------------------------------------------------------
    -- ID/EX pipeline register outputs
    ------------------------------------------------------------------------
    signal id_ex_pc_s          : std_logic_vector(PC_WIDTH-1 downto 0);
    signal id_ex_pc_plus4_s    : std_logic_vector(PC_WIDTH-1 downto 0);
    signal id_ex_instruction_s : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    signal id_ex_read_data1_s  : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal id_ex_read_data2_s  : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal id_ex_sign_extend_s : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    signal id_ex_rs1_s         : std_logic_vector(4 downto 0);
    signal id_ex_rs2_s         : std_logic_vector(4 downto 0);
    signal id_ex_rd_s          : std_logic_vector(4 downto 0);

    signal id_ex_RegDst_ctrl_s   : std_logic;
    signal id_ex_ALUSrc_ctrl_s   : std_logic;
    signal id_ex_MemtoReg_ctrl_s : std_logic;
    signal id_ex_RegWrite_ctrl_s : std_logic;
    signal id_ex_MemRead_ctrl_s  : std_logic;
    signal id_ex_MemWrite_ctrl_s : std_logic;
    signal id_ex_Branch_ctrl_s   : std_logic;
    signal id_ex_Jal_ctrl_s      : std_logic;
    signal id_ex_Jalr_ctrl_s     : std_logic;
    signal id_ex_UpperIm_ctrl_s  : std_logic_vector(1 downto 0);
    signal id_ex_MULOp_ctrl_s    : std_logic;
    signal id_ex_ALUOp_ctrl_s    : std_logic_vector(4 downto 0);

    ------------------------------------------------------------------------
    -- EX stage
    ------------------------------------------------------------------------
    signal forwarded_data1_s  : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal forwarded_data2_s  : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal store_data_s       : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    signal ex_alu_res_s       : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal ex_addr_gen_s      : std_logic_vector(PC_WIDTH-1 downto 0);
    signal ex_brTaken_s       : std_logic;
    signal ex_mul_pp_s        : std_logic_vector(63 downto 0);  -- MUL stage-1 partial products {P3,P2,P1,P0}

    ------------------------------------------------------------------------
    -- EX/MEM pipeline register outputs
    ------------------------------------------------------------------------
    signal ex_mem_pc_s          : std_logic_vector(PC_WIDTH-1 downto 0);
    signal ex_mem_pc_plus4_s    : std_logic_vector(PC_WIDTH-1 downto 0);
    signal ex_mem_instruction_s : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    signal ex_mem_alu_res_s     : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal ex_mem_addr_gen_s    : std_logic_vector(PC_WIDTH-1 downto 0);
    signal ex_mem_brTaken_s     : std_logic;

    signal ex_mem_store_data_s  : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    signal ex_mem_pp_s          : std_logic_vector(63 downto 0);  -- MUL partial products carried to MEM

    signal ex_mem_rd_s          : std_logic_vector(4 downto 0);

    signal ex_mem_RegDst_ctrl_s   : std_logic;
    signal ex_mem_MemtoReg_ctrl_s : std_logic;
    signal ex_mem_RegWrite_ctrl_s : std_logic;
    signal ex_mem_MemRead_ctrl_s  : std_logic;
    signal ex_mem_MemWrite_ctrl_s : std_logic;
    signal ex_mem_Branch_ctrl_s   : std_logic;
    signal ex_mem_Jal_ctrl_s      : std_logic;
    signal ex_mem_Jalr_ctrl_s     : std_logic;
    signal ex_mem_MULOp_ctrl_s    : std_logic;

    ------------------------------------------------------------------------
    -- MEM stage
    ------------------------------------------------------------------------
    signal dtcm_addr_s       : std_logic_vector(DTCM_ADDR_WIDTH-1 downto 0);
    signal dtcm_data_rd_s    : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal mem_mul_res_s     : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);  -- MUL stage-2 result (in MEM)

    ------------------------------------------------------------------------
    -- MEM/WB pipeline register outputs
    ------------------------------------------------------------------------
    signal mem_wb_pc_s          : std_logic_vector(PC_WIDTH-1 downto 0);
    signal mem_wb_pc_plus4_s    : std_logic_vector(PC_WIDTH-1 downto 0);
    signal mem_wb_instruction_s : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    signal mem_wb_alu_res_s      : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal mem_wb_dtcm_data_rd_s : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal mem_wb_mul_res_s      : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);  -- MUL result to WB

    signal mem_wb_rd_s           : std_logic_vector(4 downto 0);

    signal mem_wb_RegDst_ctrl_s   : std_logic;
    signal mem_wb_MemtoReg_ctrl_s : std_logic;
    signal mem_wb_RegWrite_ctrl_s : std_logic;
    signal mem_wb_MULOp_ctrl_s    : std_logic;

    ------------------------------------------------------------------------
    -- WB / hazard signals
    ------------------------------------------------------------------------
    signal wb_write_data_s   : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    signal pcwrite_s         : std_logic;
    signal ifidwrite_s       : std_logic;
    signal stall_s           : std_logic;
    signal flush_s           : std_logic;

    signal forwardA_s        : std_logic_vector(1 downto 0);
    signal forwardB_s        : std_logic_vector(1 downto 0);

    ------------------------------------------------------------------------
    -- SignalTap / debug preservation attributes
    --
    -- These attributes are intentionally used only to make key internal
    -- pipeline/hazard/MUL/memory/debug signals visible in Quartus SignalTap.
    -- They do not change the functional RTL, but they can reduce optimization
    -- quality. Use this file/build for SignalTap debug captures, and use a
    -- clean no-SignalTap/no-extra-keep build for official PPA if required.
    ------------------------------------------------------------------------
    attribute keep     : boolean;
    attribute preserve : boolean;

    -- Clock / reset / debug counters / breakpoint trigger
    attribute keep of mclk_w       : signal is true;
    attribute keep of pll_locked_w : signal is true;
    attribute keep of rst_core_w   : signal is true;
    attribute keep of mclk_cnt_q   : signal is true;
    attribute keep of stcnt_q      : signal is true;
    attribute keep of fhcnt_q      : signal is true;
    attribute keep of bpaddr_q     : signal is true;
    attribute keep of strigger_s   : signal is true;

    attribute preserve of mclk_cnt_q : signal is true;
    attribute preserve of stcnt_q    : signal is true;
    attribute preserve of fhcnt_q    : signal is true;
    attribute preserve of bpaddr_q   : signal is true;

    -- IF and pipeline-stage mirrors inside the core
    attribute keep of if_pc_s              : signal is true;
    attribute keep of if_pc_plus4_s        : signal is true;
    attribute keep of if_instruction_s     : signal is true;
    attribute keep of if_id_pc_s           : signal is true;
    attribute keep of if_id_pc_plus4_s     : signal is true;
    attribute keep of if_id_instruction_s  : signal is true;
    attribute keep of id_ex_pc_s           : signal is true;
    attribute keep of id_ex_pc_plus4_s     : signal is true;
    attribute keep of id_ex_instruction_s  : signal is true;
    attribute keep of ex_mem_pc_s          : signal is true;
    attribute keep of ex_mem_pc_plus4_s    : signal is true;
    attribute keep of ex_mem_instruction_s : signal is true;
    attribute keep of mem_wb_pc_s          : signal is true;
    attribute keep of mem_wb_pc_plus4_s    : signal is true;
    attribute keep of mem_wb_instruction_s : signal is true;

    -- ID decode / precise-use bits / hazard inputs
    attribute keep of id_rs1_s      : signal is true;
    attribute keep of id_rs2_s      : signal is true;
    attribute keep of id_rd_s       : signal is true;
    attribute keep of id_opcode_s   : signal is true;
    attribute keep of id_uses_rs1_s : signal is true;
    attribute keep of id_uses_rs2_s : signal is true;

    -- Main ID control signals
    attribute keep of id_RegWrite_ctrl_s : signal is true;
    attribute keep of id_MemRead_ctrl_s  : signal is true;
    attribute keep of id_MemWrite_ctrl_s : signal is true;
    attribute keep of id_Branch_ctrl_s   : signal is true;
    attribute keep of id_Jal_ctrl_s      : signal is true;
    attribute keep of id_Jalr_ctrl_s     : signal is true;
    attribute keep of id_MULOp_ctrl_s    : signal is true;
    attribute keep of id_ALUOp_ctrl_s    : signal is true;

    -- ID/EX hazard/control signals
    attribute keep of id_ex_rs1_s           : signal is true;
    attribute keep of id_ex_rs2_s           : signal is true;
    attribute keep of id_ex_rd_s            : signal is true;
    attribute keep of id_ex_RegWrite_ctrl_s : signal is true;
    attribute keep of id_ex_MemRead_ctrl_s  : signal is true;
    attribute keep of id_ex_MemWrite_ctrl_s : signal is true;
    attribute keep of id_ex_Branch_ctrl_s   : signal is true;
    attribute keep of id_ex_Jal_ctrl_s      : signal is true;
    attribute keep of id_ex_Jalr_ctrl_s     : signal is true;
    attribute keep of id_ex_MULOp_ctrl_s    : signal is true;
    attribute keep of id_ex_ALUOp_ctrl_s    : signal is true;

    -- Forwarding / EX datapath / MUL stage 1
    attribute keep of forwardA_s        : signal is true;
    attribute keep of forwardB_s        : signal is true;
    attribute keep of forwarded_data1_s : signal is true;
    attribute keep of forwarded_data2_s : signal is true;
    attribute keep of store_data_s      : signal is true;
    attribute keep of ex_alu_res_s      : signal is true;
    attribute keep of ex_addr_gen_s     : signal is true;
    attribute keep of ex_brTaken_s      : signal is true;
    attribute keep of ex_mul_pp_s       : signal is true;

    -- EX/MEM control/datapath/MUL partial products
    attribute keep of ex_mem_alu_res_s           : signal is true;
    attribute keep of ex_mem_addr_gen_s          : signal is true;
    attribute keep of ex_mem_brTaken_s           : signal is true;
    attribute keep of ex_mem_store_data_s        : signal is true;
    attribute keep of ex_mem_pp_s                : signal is true;
    attribute keep of ex_mem_rd_s                : signal is true;
    attribute keep of ex_mem_RegWrite_ctrl_s     : signal is true;
    attribute keep of ex_mem_MemRead_ctrl_s      : signal is true;
    attribute keep of ex_mem_MemWrite_ctrl_s     : signal is true;
    attribute keep of ex_mem_Branch_ctrl_s       : signal is true;
    attribute keep of ex_mem_Jal_ctrl_s          : signal is true;
    attribute keep of ex_mem_Jalr_ctrl_s         : signal is true;
    attribute keep of ex_mem_MULOp_ctrl_s        : signal is true;

    -- MEM / DTCM / MUL stage 2
    attribute keep of dtcm_addr_s    : signal is true;
    attribute keep of dtcm_data_rd_s : signal is true;
    attribute keep of mem_mul_res_s  : signal is true;

    -- MEM/WB and WB mux result
    attribute keep of mem_wb_alu_res_s          : signal is true;
    attribute keep of mem_wb_dtcm_data_rd_s     : signal is true;
    attribute keep of mem_wb_mul_res_s          : signal is true;
    attribute keep of mem_wb_rd_s               : signal is true;
    attribute keep of mem_wb_RegWrite_ctrl_s    : signal is true;
    attribute keep of mem_wb_MemtoReg_ctrl_s    : signal is true;
    attribute keep of mem_wb_MULOp_ctrl_s       : signal is true;
    attribute keep of wb_write_data_s           : signal is true;

    -- Interlock / flush / pipeline control
    attribute keep of pcwrite_s   : signal is true;
    attribute keep of ifidwrite_s : signal is true;
    attribute keep of stall_s     : signal is true;
    attribute keep of flush_s     : signal is true;

begin

    ------------------------------------------------------------------------
    -- PLL
    ------------------------------------------------------------------------
    G_PLL:
    if (MODELSIM = 0) generate
        MCLK: PLL
            port map(
                areset => '0',
                inclk0 => clk_i,
                c0     => mclk_w,
                locked => pll_locked_w
            );
    end generate;

    G_NO_PLL:
    if (MODELSIM /= 0) generate
        mclk_w       <= clk_i;
        pll_locked_w <= '1';
    end generate;

    ------------------------------------------------------------------------
    -- Reset polarity adaptation
    ------------------------------------------------------------------------
    rst_core_w <= rst_i when MODELSIM = 1 else ((not rst_i) or (not pll_locked_w));

    ------------------------------------------------------------------------
    -- Flush logic
    -- Branch and jump are resolved in MEM stage, using EX/MEM outputs.
    ------------------------------------------------------------------------
    flush_s <= (ex_mem_Branch_ctrl_s and ex_mem_brTaken_s) or
               ex_mem_Jal_ctrl_s or
               ex_mem_Jalr_ctrl_s;

    ------------------------------------------------------------------------
    -- IF stage
    ------------------------------------------------------------------------
    IFE : entity work.Ifetch
        generic map(
            WORD_GRANULARITY => WORD_GRANULARITY,
            DATA_BUS_WIDTH   => DATA_BUS_WIDTH,
            PC_WIDTH         => PC_WIDTH,
            ITCM_ADDR_WIDTH  => ITCM_ADDR_WIDTH,
            WORDS_NUM        => DATA_WORDS_NUM
        )
        port map(
            clk_i         => mclk_w,
            rst_i         => rst_core_w,
            PCWrite_i     => pcwrite_s,

            addr_gen_i    => ex_mem_addr_gen_s,
            Branch_ctrl_i => ex_mem_Branch_ctrl_s,
            brTaken_i     => ex_mem_brTaken_s,
            Jal_ctrl_i    => ex_mem_Jal_ctrl_s,
            Jalr_ctrl_i   => ex_mem_Jalr_ctrl_s,
            alu_res_i     => ex_mem_alu_res_s,

            pc_o          => if_pc_s,
            pc_plus4_o    => if_pc_plus4_s,
            instruction_o => if_instruction_s
        );

    ------------------------------------------------------------------------
    -- IF/ID register
    ------------------------------------------------------------------------
    IF_ID : entity work.IF_ID_REG
        generic map(
            DATA_BUS_WIDTH => DATA_BUS_WIDTH,
            PC_WIDTH       => PC_WIDTH
        )
        port map(
            clk_i         => mclk_w,
            rst_i         => rst_core_w,
            IFIDWrite_i   => ifidwrite_s,
            Flush_i       => flush_s,

            pc_i          => if_pc_s,
            pc_plus4_i    => if_pc_plus4_s,
            instruction_i => if_instruction_s,

            pc_o          => if_id_pc_s,
            pc_plus4_o    => if_id_pc_plus4_s,
            instruction_o => if_id_instruction_s
        );

    ------------------------------------------------------------------------
    -- ID stage register indexes
    ------------------------------------------------------------------------
    id_rs1_s    <= if_id_instruction_s(19 downto 15);
    id_rs2_s    <= if_id_instruction_s(24 downto 20);
    id_rd_s     <= if_id_instruction_s(11 downto 7);
    id_opcode_s <= if_id_instruction_s(6 downto 0);

    -- Precise source-use decode for the interlock unit.
    -- This prevents false load-use/mul-use stalls against rs fields that are actually immediate bits.
    id_uses_rs1_s <= '1' when (id_opcode_s = RTYPE_OPC or
                               id_opcode_s = ITYPE_OPC or
                               id_opcode_s = INST_LW(6 downto 0) or
                               id_opcode_s = STYPE_OPC or
                               id_opcode_s = SBTYPE_OPC or
                               id_opcode_s = INST_JALR(6 downto 0))
                     else '0';

    id_uses_rs2_s <= '1' when (id_opcode_s = RTYPE_OPC or
                               id_opcode_s = STYPE_OPC or
                               id_opcode_s = SBTYPE_OPC)
                     else '0';

    ------------------------------------------------------------------------
    -- IDECODE
    --
    -- This assumes your adapted Idecode has the following WB inputs:
    --   wb_rd_i, wb_write_data_i, wb_regwrite_i
    ------------------------------------------------------------------------
    ID : entity work.Idecode
        generic map(
            PC_WIDTH       => PC_WIDTH,
            DATA_BUS_WIDTH => DATA_BUS_WIDTH
        )
        port map(
            clk_i           => mclk_w,
            rst_i           => rst_core_w,

            instruction_i   => if_id_instruction_s,

            wb_rd_i         => mem_wb_rd_s,
            wb_write_data_i => wb_write_data_s,
            wb_regwrite_i   => mem_wb_RegWrite_ctrl_s,

            read_data1_o    => id_read_data1_s,
            read_data2_o    => id_read_data2_s,
            SignExt_o       => id_sign_extend_s
        );

    ------------------------------------------------------------------------
    -- CONTROL
    ------------------------------------------------------------------------
    CTL : entity work.control
        port map(
            instruction_i      => if_id_instruction_s,

            RegDst_ctrl_o     => id_RegDst_ctrl_s,
            ALUSrc_ctrl_o     => id_ALUSrc_ctrl_s,
            MemtoReg_ctrl_o   => id_MemtoReg_ctrl_s,
            RegWrite_ctrl_o   => id_RegWrite_ctrl_s,
            MemRead_ctrl_o    => id_MemRead_ctrl_s,
            MemWrite_ctrl_o   => id_MemWrite_ctrl_s,
            Branch_ctrl_o     => id_Branch_ctrl_s,
            Jal_ctrl_o        => id_Jal_ctrl_s,
            Jalr_ctrl_o       => id_Jalr_ctrl_s,
            UpperIm_ctrl_o    => id_UpperIm_ctrl_s,
            MULOp_ctrl_o      => id_MULOp_ctrl_s,
            ALUOp_ctrl_o      => id_ALUOp_ctrl_s
        );

    ------------------------------------------------------------------------
    -- Stall unit
    ------------------------------------------------------------------------
    STALL_U : entity work.stall_unit
        port map(
            id_ex_memread_i => id_ex_MemRead_ctrl_s,
            id_ex_mulop_i   => id_ex_MULOp_ctrl_s,
            id_ex_rd_i      => id_ex_rd_s,

            if_id_rs1_i     => id_rs1_s,
            if_id_rs2_i     => id_rs2_s,
            if_id_uses_rs1_i => id_uses_rs1_s,
            if_id_uses_rs2_i => id_uses_rs2_s,

            PCwrite_o       => pcwrite_s,
            IFIDWrite_o     => ifidwrite_s,
            Stall_o         => stall_s
        );

    ------------------------------------------------------------------------
    -- ID/EX register
    ------------------------------------------------------------------------
    ID_EX : entity work.ID_EX_REG
        generic map(
            DATA_BUS_WIDTH => DATA_BUS_WIDTH,
            PC_WIDTH       => PC_WIDTH
        )
        port map(
            clk_i           => mclk_w,
            rst_i           => rst_core_w,
            Stall_i         => stall_s,
            Flush_i         => flush_s,

            pc_i            => if_id_pc_s,
            pc_plus4_i      => if_id_pc_plus4_s,
            instruction_i   => if_id_instruction_s,

            read_data1_i    => id_read_data1_s,
            read_data2_i    => id_read_data2_s,
            sign_extend_i   => id_sign_extend_s,

            rs1_i           => id_rs1_s,
            rs2_i           => id_rs2_s,
            rd_i            => id_rd_s,

            RegDst_ctrl_i   => id_RegDst_ctrl_s,
            ALUSrc_ctrl_i   => id_ALUSrc_ctrl_s,
            MemtoReg_ctrl_i => id_MemtoReg_ctrl_s,
            RegWrite_ctrl_i => id_RegWrite_ctrl_s,
            MemRead_ctrl_i  => id_MemRead_ctrl_s,
            MemWrite_ctrl_i => id_MemWrite_ctrl_s,
            Branch_ctrl_i   => id_Branch_ctrl_s,
            Jal_ctrl_i      => id_Jal_ctrl_s,
            Jalr_ctrl_i     => id_Jalr_ctrl_s,
            UpperIm_ctrl_i  => id_UpperIm_ctrl_s,
            MULOp_ctrl_i    => id_MULOp_ctrl_s,
            ALUOp_ctrl_i    => id_ALUOp_ctrl_s,

            pc_o            => id_ex_pc_s,
            pc_plus4_o      => id_ex_pc_plus4_s,
            instruction_o   => id_ex_instruction_s,

            read_data1_o    => id_ex_read_data1_s,
            read_data2_o    => id_ex_read_data2_s,
            sign_extend_o   => id_ex_sign_extend_s,

            rs1_o           => id_ex_rs1_s,
            rs2_o           => id_ex_rs2_s,
            rd_o            => id_ex_rd_s,

            RegDst_ctrl_o   => id_ex_RegDst_ctrl_s,
            ALUSrc_ctrl_o   => id_ex_ALUSrc_ctrl_s,
            MemtoReg_ctrl_o => id_ex_MemtoReg_ctrl_s,
            RegWrite_ctrl_o => id_ex_RegWrite_ctrl_s,
            MemRead_ctrl_o  => id_ex_MemRead_ctrl_s,
            MemWrite_ctrl_o => id_ex_MemWrite_ctrl_s,
            Branch_ctrl_o   => id_ex_Branch_ctrl_s,
            Jal_ctrl_o      => id_ex_Jal_ctrl_s,
            Jalr_ctrl_o     => id_ex_Jalr_ctrl_s,
            UpperIm_ctrl_o  => id_ex_UpperIm_ctrl_s,
            MULOp_ctrl_o    => id_ex_MULOp_ctrl_s,
            ALUOp_ctrl_o    => id_ex_ALUOp_ctrl_s
        );

    ------------------------------------------------------------------------
    -- Forwarding unit
    ------------------------------------------------------------------------
    FWD_U : entity work.forwarding_unit
        port map(
            id_ex_rs1_i        => id_ex_rs1_s,
            id_ex_rs2_i        => id_ex_rs2_s,

            ex_mem_rd_i        => ex_mem_rd_s,
            ex_mem_regwrite_i  => ex_mem_RegWrite_ctrl_s,

            mem_wb_rd_i        => mem_wb_rd_s,
            mem_wb_regwrite_i  => mem_wb_RegWrite_ctrl_s,

            forwardA_o         => forwardA_s,
            forwardB_o         => forwardB_s
        );

    ------------------------------------------------------------------------
    -- Pipeline muxes: forwarding muxes + WB mux
    ------------------------------------------------------------------------
    MUXES : entity work.pipeline_muxes
        generic map(
            DATA_BUS_WIDTH => DATA_BUS_WIDTH,
            PC_WIDTH       => PC_WIDTH
        )
        port map(
            id_ex_read_data1_i      => id_ex_read_data1_s,
            id_ex_read_data2_i      => id_ex_read_data2_s,

            ex_mem_alu_res_i        => ex_mem_alu_res_s,

            forwardA_sel_i          => forwardA_s,
            forwardB_sel_i          => forwardB_s,

            mem_wb_alu_res_i        => mem_wb_alu_res_s,
            mem_wb_dtcm_data_rd_i   => mem_wb_dtcm_data_rd_s,
            mem_wb_mul_res_i        => mem_wb_mul_res_s,
            mem_wb_pc_plus4_i       => mem_wb_pc_plus4_s,

            mem_wb_RegDst_ctrl_i    => mem_wb_RegDst_ctrl_s,
            mem_wb_MemtoReg_ctrl_i  => mem_wb_MemtoReg_ctrl_s,
            mem_wb_MULOp_ctrl_i     => mem_wb_MULOp_ctrl_s,

            forwarded_data1_o       => forwarded_data1_s,
            forwarded_data2_o       => forwarded_data2_s,
            store_data_o            => store_data_s,
            wb_write_data_o         => wb_write_data_s
        );

    ------------------------------------------------------------------------
    -- EX stage
    ------------------------------------------------------------------------
    EXE : entity work.Execute
        generic map(
            DATA_BUS_WIDTH => DATA_BUS_WIDTH,
            PC_WIDTH       => PC_WIDTH
        )
        port map(
            read_data1_i    => forwarded_data1_s,
            read_data2_i    => forwarded_data2_s,
            sign_extend_i   => id_ex_sign_extend_s,

            UpperIm_ctrl_i  => id_ex_UpperIm_ctrl_s,
            ALUOp_ctrl_i    => id_ex_ALUOp_ctrl_s,
            ALUSrc_ctrl_i   => id_ex_ALUSrc_ctrl_s,

            pc_i            => id_ex_pc_s,

            brTaken_o       => ex_brTaken_s,
            alu_res_o       => ex_alu_res_s,
            addr_gen_o      => ex_addr_gen_s
        );

    ------------------------------------------------------------------------
    -- MUL stage 1 (EX): four 8-bit embedded multiplies -> packed partial products.
    -- Uses the forwarded EX operands; the result is latched in the EX/MEM register.
    ------------------------------------------------------------------------
    MUL_S1 : entity work.Multiplier16_s1
        port map(
            A_i => forwarded_data1_s(15 downto 0),
            B_i => forwarded_data2_s(15 downto 0),
            P_o => ex_mul_pp_s
        );

    ------------------------------------------------------------------------
    -- EX/MEM register
    ------------------------------------------------------------------------
    EX_MEM : entity work.EX_MEM_REG
        generic map(
            DATA_BUS_WIDTH => DATA_BUS_WIDTH,
            PC_WIDTH       => PC_WIDTH
        )
        port map(
            clk_i           => mclk_w,
            rst_i           => rst_core_w,
            Flush_i         => flush_s,

            pc_i            => id_ex_pc_s,
            pc_plus4_i      => id_ex_pc_plus4_s,
            instruction_i   => id_ex_instruction_s,

            alu_res_i       => ex_alu_res_s,
            addr_gen_i      => ex_addr_gen_s,
            brTaken_i       => ex_brTaken_s,

            read_data2_i    => store_data_s,

            mul_pp_i        => ex_mul_pp_s,

            rd_i            => id_ex_rd_s,

            RegDst_ctrl_i   => id_ex_RegDst_ctrl_s,
            MemtoReg_ctrl_i => id_ex_MemtoReg_ctrl_s,
            RegWrite_ctrl_i => id_ex_RegWrite_ctrl_s,
            MemRead_ctrl_i  => id_ex_MemRead_ctrl_s,
            MemWrite_ctrl_i => id_ex_MemWrite_ctrl_s,
            Branch_ctrl_i   => id_ex_Branch_ctrl_s,
            Jal_ctrl_i      => id_ex_Jal_ctrl_s,
            Jalr_ctrl_i     => id_ex_Jalr_ctrl_s,
            MULOp_ctrl_i    => id_ex_MULOp_ctrl_s,

            pc_o            => ex_mem_pc_s,
            pc_plus4_o      => ex_mem_pc_plus4_s,
            instruction_o   => ex_mem_instruction_s,

            alu_res_o       => ex_mem_alu_res_s,
            addr_gen_o      => ex_mem_addr_gen_s,
            brTaken_o       => ex_mem_brTaken_s,

            read_data2_o    => ex_mem_store_data_s,

            mul_pp_o        => ex_mem_pp_s,

            rd_o            => ex_mem_rd_s,

            RegDst_ctrl_o   => ex_mem_RegDst_ctrl_s,
            MemtoReg_ctrl_o => ex_mem_MemtoReg_ctrl_s,
            RegWrite_ctrl_o => ex_mem_RegWrite_ctrl_s,
            MemRead_ctrl_o  => ex_mem_MemRead_ctrl_s,
            MemWrite_ctrl_o => ex_mem_MemWrite_ctrl_s,
            Branch_ctrl_o   => ex_mem_Branch_ctrl_s,
            Jal_ctrl_o      => ex_mem_Jal_ctrl_s,
            Jalr_ctrl_o     => ex_mem_Jalr_ctrl_s,
            MULOp_ctrl_o    => ex_mem_MULOp_ctrl_s
        );

    ------------------------------------------------------------------------
    -- DTCM address selection
    ------------------------------------------------------------------------
    G_DTCM_WORD_ADDR:
    if (WORD_GRANULARITY = True) generate
        dtcm_addr_s <= ex_mem_alu_res_s(MA_WIDTH-1 downto 2);
    end generate;

    G_DTCM_BYTE_ADDR:
    if (WORD_GRANULARITY = False) generate
        dtcm_addr_s <= ex_mem_alu_res_s(MA_WIDTH-1 downto 0);
    end generate;

    ------------------------------------------------------------------------
    -- MEM stage
    ------------------------------------------------------------------------
    MEM : entity work.dmemory
        generic map(
            DATA_BUS_WIDTH  => DATA_BUS_WIDTH,
            DTCM_ADDR_WIDTH => DTCM_ADDR_WIDTH,
            WORDS_NUM       => DATA_WORDS_NUM
        )
        port map(
            clk_i           => mclk_w,
            rst_i           => rst_core_w,

            dtcm_addr_i     => dtcm_addr_s,
            dtcm_data_wr_i  => ex_mem_store_data_s,

            MemRead_ctrl_i  => ex_mem_MemRead_ctrl_s,
            MemWrite_ctrl_i => ex_mem_MemWrite_ctrl_s,

            dtcm_data_rd_o  => dtcm_data_rd_s
        );

    ------------------------------------------------------------------------
    -- MUL stage 2 (MEM): adder tree over the latched partial products.
    -- Result becomes available in MEM/WB, exactly like a load (mul-use needs 1 stall).
    ------------------------------------------------------------------------
    MUL_S2 : entity work.Multiplier16_s2
        port map(
            P_i   => ex_mem_pp_s,
            Res_o => mem_mul_res_s
        );

    ------------------------------------------------------------------------
    -- MEM/WB register
    ------------------------------------------------------------------------
    MEM_WB : entity work.MEM_WB_REG
        generic map(
            DATA_BUS_WIDTH => DATA_BUS_WIDTH,
            PC_WIDTH       => PC_WIDTH
        )
        port map(
            clk_i           => mclk_w,
            rst_i           => rst_core_w,

            pc_i            => ex_mem_pc_s,
            pc_plus4_i      => ex_mem_pc_plus4_s,
            instruction_i   => ex_mem_instruction_s,

            alu_res_i       => ex_mem_alu_res_s,
            dtcm_data_rd_i  => dtcm_data_rd_s,
            mul_res_i       => mem_mul_res_s,

            rd_i            => ex_mem_rd_s,

            RegDst_ctrl_i   => ex_mem_RegDst_ctrl_s,
            MemtoReg_ctrl_i => ex_mem_MemtoReg_ctrl_s,
            RegWrite_ctrl_i => ex_mem_RegWrite_ctrl_s,
            MULOp_ctrl_i    => ex_mem_MULOp_ctrl_s,

            pc_o            => mem_wb_pc_s,
            pc_plus4_o      => mem_wb_pc_plus4_s,
            instruction_o   => mem_wb_instruction_s,

            alu_res_o       => mem_wb_alu_res_s,
            dtcm_data_rd_o  => mem_wb_dtcm_data_rd_s,
            mul_res_o       => mem_wb_mul_res_s,

            rd_o            => mem_wb_rd_s,

            RegDst_ctrl_o   => mem_wb_RegDst_ctrl_s,
            MemtoReg_ctrl_o => mem_wb_MemtoReg_ctrl_s,
            RegWrite_ctrl_o => mem_wb_RegWrite_ctrl_s,
            MULOp_ctrl_o    => mem_wb_MULOp_ctrl_s
        );

    ------------------------------------------------------------------------
    -- Counters
    ------------------------------------------------------------------------
    process(mclk_w)
    begin
        if rising_edge(mclk_w) then
            if rst_core_w = '1' then
                mclk_cnt_q <= (others => '0');
                stcnt_q    <= (others => '0');
                fhcnt_q    <= (others => '0');
                bpaddr_q   <= (others => '0');
            else
                mclk_cnt_q <= mclk_cnt_q + '1';
                bpaddr_q   <= BPADDR_i;

                if stall_s = '1' then
                    stcnt_q <= stcnt_q + '1';
                end if;

                if flush_s = '1' then
                    fhcnt_q <= fhcnt_q + '1';
                end if;
            end if;
        end if;
    end process;


    ------------------------------------------------------------------------
    -- SignalTap breakpoint trigger. BPADDR_i is captured in the core clock
    -- domain above, so the comparison is fully inside mclk_w domain.
    -- BPADDR_i is word-granular; IF PC is byte-addressed when WORD_GRANULARITY=True.
    ------------------------------------------------------------------------
    G_STRIG_WORD:
    if (WORD_GRANULARITY = True) generate
        strigger_s <= '1' when (if_pc_s(9 downto 2) = bpaddr_q) else '0';
    end generate;

    G_STRIG_BYTE:
    if (WORD_GRANULARITY = False) generate
        strigger_s <= '1' when (if_pc_s(7 downto 0) = bpaddr_q) else '0';
    end generate;

    ------------------------------------------------------------------------
    -- Debug / output assignments
    ------------------------------------------------------------------------
    pc_o              <= if_pc_s;
    instruction_o     <= if_instruction_s;

    RegWrite_ctrl_o   <= mem_wb_RegWrite_ctrl_s;
    MemWrite_ctrl_o   <= ex_mem_MemWrite_ctrl_s;
    Branch_ctrl_o     <= ex_mem_Branch_ctrl_s;

    read_data1_o      <= id_read_data1_s;
    read_data2_o      <= id_read_data2_s;
    write_data_o      <= wb_write_data_s;

    alu_res_o         <= ex_mem_alu_res_s;
    brTaken_o         <= ex_mem_brTaken_s;

    dtcm_addr_o       <= dtcm_addr_s;
    dtcm_data_wr_o    <= ex_mem_store_data_s;
    dtcm_data_rd_o    <= dtcm_data_rd_s;

    mclk_cnt_o        <= mclk_cnt_q;
    CLKCNT_o          <= mclk_cnt_q;
    STCNT_o           <= stcnt_q;
    FHCNT_o           <= fhcnt_q;
    STRIGGER_o        <= strigger_s;

    ------------------------------------------------------------------------
    -- Pipeline-stage debug taps (SignalTap). Pure combinational mirrors of the
    -- pipeline-register stage outputs; no new state and no behavior change.
    --   IF  stage : pc_o / instruction_o (already exposed above)
    --   ID  stage : IF/ID register outputs
    --   EX  stage : ID/EX register outputs
    --   MEM stage : EX/MEM register outputs
    --   WB  stage : MEM/WB register outputs
    ------------------------------------------------------------------------
    IDpc_o            <= if_id_pc_s;
    IDinstruction_o   <= if_id_instruction_s;
    EXpc_o            <= id_ex_pc_s;
    EXinstruction_o   <= id_ex_instruction_s;
    MEMpc_o           <= ex_mem_pc_s;
    MEMinstruction_o  <= ex_mem_instruction_s;
    WBpc_o            <= mem_wb_pc_s;
    WBinstruction_o   <= mem_wb_instruction_s;

end structure;
