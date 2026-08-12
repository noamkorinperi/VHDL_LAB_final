--============================================================================
-- LAB5 Part 2 - FPGA board-level TOP wrapper for the RV32IM pipelined core.
--
-- Purpose (PDF clause 6 / Figure 8, MD sections 20-21):
--   * Structural wrapper around RV32IM_PIPELINE_CORE (core/MUL/hazard logic UNCHANGED).
--   * SW7..SW0 feed the core BPADDR_i input. The BPADDR register is inside the core
--     and is sampled in the core clock domain.
--   * STRIGGER_o : SignalTap trigger, asserted when IF_PC (word address) == BPADDR_i.
--   * Exposes IF_PC, IF instruction, STCNT, FHCNT, mclk_cnt and key datapath taps as
--     internal debug signals; a few are mirrored on LEDR for board-level feedback.
--
-- Board mapping (assign in Quartus .qsf, board-specific):
--   clk_i  <- CLOCK_50 (50 MHz)        ; the core's internal PLL divides it to the 25 MHz mclk
--   rst_i  <- KEY0      (active-low push-button: pressed = '0' = reset, per MD section 2)
--   SW     <- SW7..SW0                  (breakpoint word address)
--   LEDR   -> LEDR9..LEDR0             (status)
--
-- Build configuration: G_MODELSIM = 0 (FPGA) so the core instantiates the PLL and uses the
-- (not KEY0) reset polarity.  The testbench overrides MODELSIM => 1 for simulation.
--============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cond_compilation_package.all;
use work.aux_package.all;

entity RV32IM_pipeline_top is
    generic(
        WORD_GRANULARITY : boolean := G_WORD_GRANULARITY;
        MODELSIM         : integer := G_MODELSIM;          -- 0 = FPGA build
        DATA_BUS_WIDTH   : integer := 32;
        ITCM_ADDR_WIDTH  : integer := G_ADDRWIDTH;
        DTCM_ADDR_WIDTH  : integer := G_ADDRWIDTH;
        PC_WIDTH         : integer := G_PC_WIDTH;
        MA_WIDTH         : integer := G_MA_WIDTH;
        DATA_WORDS_NUM   : integer := G_DATA_WORDSNUM;
        CLK_CNT_WIDTH    : integer := 32                   -- wide cycle counter for IPC on hardware
    );
    port(
        -- Board inputs
        clk_i   : in  std_logic;                          -- CLOCK_50
        rst_i   : in  std_logic;                          -- KEY0 (active-low)
        SW      : in  std_logic_vector(7 downto 0);       -- SW7..SW0 -> core BPADDR_i

        -- Board outputs
        LEDR    : out std_logic_vector(9 downto 0);       -- status LEDs

        -- Figure-8 / SignalTap debug ports. Assign these as virtual pins in Quartus
        -- unless you intentionally route a small subset to physical pins.
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
        STCNT_o           : out std_logic_vector(15 downto 0);
        FHCNT_o           : out std_logic_vector(15 downto 0);
        STRIGGER_o        : out std_logic;

        IDpc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
        IDinstruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        EXpc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
        EXinstruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        MEMpc_o           : out std_logic_vector(PC_WIDTH-1 downto 0);
        MEMinstruction_o  : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        WBpc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
        WBinstruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0)
    );

end RV32IM_pipeline_top;

architecture structure of RV32IM_pipeline_top is

    ------------------------------------------------------------------------
    -- Core debug taps
    ------------------------------------------------------------------------
    signal if_pc_s          : std_logic_vector(PC_WIDTH-1 downto 0);
    signal if_instruction_s : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    signal regwrite_s       : std_logic;
    signal memwrite_s       : std_logic;
    signal branch_s         : std_logic;

    signal read_data1_s     : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal read_data2_s     : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal write_data_s     : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    signal alu_res_s        : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal brtaken_s        : std_logic;

    signal dtcm_addr_s      : std_logic_vector(DTCM_ADDR_WIDTH-1 downto 0);
    signal dtcm_data_wr_s   : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal dtcm_data_rd_s   : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    signal mclk_cnt_s       : std_logic_vector(CLK_CNT_WIDTH-1 downto 0);   -- CLKCNT
    signal stcnt_s          : std_logic_vector(15 downto 0);
    signal fhcnt_s          : std_logic_vector(15 downto 0);

    ------------------------------------------------------------------------
    -- Per-stage PC/instruction debug taps (IF is pc_o/instruction_o = if_pc_s/if_instruction_s)
    ------------------------------------------------------------------------
    signal id_pc_s          : std_logic_vector(PC_WIDTH-1 downto 0);
    signal id_instruction_s : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal ex_pc_s          : std_logic_vector(PC_WIDTH-1 downto 0);
    signal ex_instruction_s : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal mem_pc_s         : std_logic_vector(PC_WIDTH-1 downto 0);
    signal mem_instruction_s: std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal wb_pc_s          : std_logic_vector(PC_WIDTH-1 downto 0);
    signal wb_instruction_s : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    ------------------------------------------------------------------------
    -- SignalTap trigger returned from core
    ------------------------------------------------------------------------
    signal strigger_s       : std_logic;                      -- IF_PC(word) == BPADDR_i

    ------------------------------------------------------------------------
    -- SignalTap / debug preservation attributes for wrapper-level aliases.
    -- These help the Node Finder keep readable top-wrapper names for the
    -- same debug buses that are already exposed at the core boundary.
    ------------------------------------------------------------------------
    attribute keep : boolean;

    attribute keep of if_pc_s           : signal is true;
    attribute keep of if_instruction_s  : signal is true;
    attribute keep of regwrite_s        : signal is true;
    attribute keep of memwrite_s        : signal is true;
    attribute keep of branch_s          : signal is true;
    attribute keep of read_data1_s      : signal is true;
    attribute keep of read_data2_s      : signal is true;
    attribute keep of write_data_s      : signal is true;
    attribute keep of alu_res_s         : signal is true;
    attribute keep of brtaken_s         : signal is true;
    attribute keep of dtcm_addr_s       : signal is true;
    attribute keep of dtcm_data_wr_s    : signal is true;
    attribute keep of dtcm_data_rd_s    : signal is true;
    attribute keep of mclk_cnt_s        : signal is true;
    attribute keep of stcnt_s           : signal is true;
    attribute keep of fhcnt_s           : signal is true;
    attribute keep of id_pc_s           : signal is true;
    attribute keep of id_instruction_s  : signal is true;
    attribute keep of ex_pc_s           : signal is true;
    attribute keep of ex_instruction_s  : signal is true;
    attribute keep of mem_pc_s          : signal is true;
    attribute keep of mem_instruction_s : signal is true;
    attribute keep of wb_pc_s           : signal is true;
    attribute keep of wb_instruction_s  : signal is true;
    attribute keep of strigger_s        : signal is true;


begin

    ------------------------------------------------------------------------
    -- RISC-V pipelined core (unchanged). Internal PLL makes the 25 MHz mclk.
    ------------------------------------------------------------------------
    CPU : entity work.RV32IM_PIPELINE_CORE
        generic map(
            WORD_GRANULARITY => WORD_GRANULARITY,
            MODELSIM         => MODELSIM,
            DATA_BUS_WIDTH   => DATA_BUS_WIDTH,
            ITCM_ADDR_WIDTH  => ITCM_ADDR_WIDTH,
            DTCM_ADDR_WIDTH  => DTCM_ADDR_WIDTH,
            PC_WIDTH         => PC_WIDTH,
            MA_WIDTH         => MA_WIDTH,
            DATA_WORDS_NUM   => DATA_WORDS_NUM,
            CLK_CNT_WIDTH    => CLK_CNT_WIDTH
        )
        port map(
            rst_i           => rst_i,        -- KEY0; core inverts it internally for FPGA
            clk_i           => clk_i,        -- CLOCK_50; core PLL -> mclk
            BPADDR_i        => SW,           -- sampled inside the core clock domain

            pc_o            => if_pc_s,       -- IF_PC
            instruction_o   => if_instruction_s,

            RegWrite_ctrl_o => regwrite_s,
            MemWrite_ctrl_o => memwrite_s,
            Branch_ctrl_o   => branch_s,

            read_data1_o    => read_data1_s,
            read_data2_o    => read_data2_s,
            write_data_o    => write_data_s,

            alu_res_o       => alu_res_s,
            brTaken_o       => brtaken_s,

            dtcm_addr_o     => dtcm_addr_s,
            dtcm_data_wr_o  => dtcm_data_wr_s,
            dtcm_data_rd_o  => dtcm_data_rd_s,

            mclk_cnt_o      => mclk_cnt_s,
            CLKCNT_o        => open,
            STCNT_o         => stcnt_s,
            FHCNT_o         => fhcnt_s,
            STRIGGER_o      => strigger_s,

            -- per-stage debug taps
            IDpc_o           => id_pc_s,
            IDinstruction_o  => id_instruction_s,
            EXpc_o           => ex_pc_s,
            EXinstruction_o  => ex_instruction_s,
            MEMpc_o          => mem_pc_s,
            MEMinstruction_o => mem_instruction_s,
            WBpc_o           => wb_pc_s,
            WBinstruction_o  => wb_instruction_s
        );

    ------------------------------------------------------------------------
    -- Board status LEDs (optional feedback / anchors synthesis):
    --   LEDR(7..0) = stall counter low byte, LEDR(8) = breakpoint hit, LEDR(9) = any flush seen
    ------------------------------------------------------------------------
    LEDR(7 downto 0) <= stcnt_s(7 downto 0);
    LEDR(8)          <= strigger_s;
    LEDR(9)          <= '0' when (fhcnt_s = x"0000") else '1';


    ------------------------------------------------------------------------
    -- Figure-8 / SignalTap debug port mirrors
    ------------------------------------------------------------------------
    pc_o              <= if_pc_s;
    instruction_o     <= if_instruction_s;

    RegWrite_ctrl_o   <= regwrite_s;
    MemWrite_ctrl_o   <= memwrite_s;
    Branch_ctrl_o     <= branch_s;

    read_data1_o      <= read_data1_s;
    read_data2_o      <= read_data2_s;
    write_data_o      <= write_data_s;

    alu_res_o         <= alu_res_s;
    brTaken_o         <= brtaken_s;

    dtcm_addr_o       <= dtcm_addr_s;
    dtcm_data_wr_o    <= dtcm_data_wr_s;
    dtcm_data_rd_o    <= dtcm_data_rd_s;

    mclk_cnt_o        <= mclk_cnt_s;
    CLKCNT_o          <= mclk_cnt_s;
    STCNT_o           <= stcnt_s;
    FHCNT_o           <= fhcnt_s;
    STRIGGER_o        <= strigger_s;

    IDpc_o            <= id_pc_s;
    IDinstruction_o   <= id_instruction_s;
    EXpc_o            <= ex_pc_s;
    EXinstruction_o   <= ex_instruction_s;
    MEMpc_o           <= mem_pc_s;
    MEMinstruction_o  <= mem_instruction_s;
    WBpc_o            <= wb_pc_s;
    WBinstruction_o   <= wb_instruction_s;

end structure;
