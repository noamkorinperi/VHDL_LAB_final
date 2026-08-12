---------------------------------------------------------------------------------------------
-- Updated auxiliary package for RV32IM pipeline simulation
-- This package keeps the original package name: aux_package.
--
-- Use this file instead of the old aux_package.vhd inside the RV32IM_pipeline project.
-- Do not compile both old and updated aux_package files in the same work library.
---------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.cond_compilation_package.all;

package aux_package is

---------------------------------------------------------------------------------------------
-- Pipeline core
---------------------------------------------------------------------------------------------
    component RV32IM_PIPELINE_CORE is
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

            -- Pipeline performance counters
            STCNT_o           : out std_logic_vector(15 downto 0);
            FHCNT_o           : out std_logic_vector(15 downto 0);
            STRIGGER_o        : out std_logic;

            -- Pipeline-stage debug taps for SignalTap (no behavior change)
            IDpc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
            IDinstruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            EXpc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
            EXinstruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            MEMpc_o           : out std_logic_vector(PC_WIDTH-1 downto 0);
            MEMinstruction_o  : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            WBpc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
            WBinstruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0)
        );
    end component;

---------------------------------------------------------------------------------------------
-- Control unit
---------------------------------------------------------------------------------------------
    component control is
        port(
            -- Inputs
            instruction_i      : in  std_logic_vector(31 downto 0);

            -- Outputs
            RegDst_ctrl_o      : out std_logic;
            ALUSrc_ctrl_o      : out std_logic;
            MemtoReg_ctrl_o    : out std_logic;
            RegWrite_ctrl_o    : out std_logic;
            MemRead_ctrl_o     : out std_logic;
            MemWrite_ctrl_o    : out std_logic;
            Branch_ctrl_o      : out std_logic;
            Jal_ctrl_o         : out std_logic;
            Jalr_ctrl_o        : out std_logic;
            UpperIm_ctrl_o     : out std_logic_vector(1 downto 0);
            MULOp_ctrl_o       : out std_logic;
            ALUOp_ctrl_o       : out std_logic_vector(4 downto 0)
        );
    end component;

---------------------------------------------------------------------------------------------
-- IFETCH, adapted for pipeline PC stall support
---------------------------------------------------------------------------------------------
    component Ifetch is
        generic(
            WORD_GRANULARITY : boolean := False;
            DATA_BUS_WIDTH   : integer := 32;
            PC_WIDTH         : integer := 10;
            ITCM_ADDR_WIDTH  : integer := 8;
            WORDS_NUM        : integer := 256
        );
        port(
            -- Inputs
            clk_i            : in  std_logic;
            rst_i            : in  std_logic;
            PCWrite_i        : in  std_logic;

            addr_gen_i       : in  std_logic_vector(PC_WIDTH-1 downto 0);
            Branch_ctrl_i    : in  std_logic;
            brTaken_i        : in  std_logic;
            Jal_ctrl_i       : in  std_logic;
            Jalr_ctrl_i      : in  std_logic;
            alu_res_i        : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            -- Outputs
            pc_o             : out std_logic_vector(PC_WIDTH-1 downto 0);
            pc_plus4_o       : out std_logic_vector(PC_WIDTH-1 downto 0);
            instruction_o    : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0)
        );
    end component;

---------------------------------------------------------------------------------------------
-- IDECODE, adapted for pipeline writeback
---------------------------------------------------------------------------------------------
    component Idecode is
        generic(
            PC_WIDTH       : integer := 10;
            DATA_BUS_WIDTH : integer := 32
        );
        port(
            -- Inputs
            clk_i           : in  std_logic;
            rst_i           : in  std_logic;

            -- Instruction currently in ID stage
            instruction_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            -- Writeback from WB stage
            wb_rd_i         : in  std_logic_vector(4 downto 0);
            wb_write_data_i : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            wb_regwrite_i   : in  std_logic;

            -- Outputs
            read_data1_o    : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            read_data2_o    : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            SignExt_o       : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0)
        );
    end component;

---------------------------------------------------------------------------------------------
-- EXECUTE
---------------------------------------------------------------------------------------------
    component Execute is
        generic(
            DATA_BUS_WIDTH : integer := 32;
            PC_WIDTH       : integer := 10
        );
        port(
            -- Inputs
            read_data1_i    : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            read_data2_i    : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            sign_extend_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            UpperIm_ctrl_i  : in  std_logic_vector(1 downto 0);
            ALUOp_ctrl_i    : in  std_logic_vector(4 downto 0);
            ALUSrc_ctrl_i   : in  std_logic;
            pc_i            : in  std_logic_vector(PC_WIDTH-1 downto 0);

            -- Outputs
            brTaken_o       : out std_logic;
            alu_res_o       : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            addr_gen_o      : out std_logic_vector(PC_WIDTH-1 downto 0)
        );
    end component;

---------------------------------------------------------------------------------------------
-- DMEMORY
---------------------------------------------------------------------------------------------
    component dmemory is
        generic(
            DATA_BUS_WIDTH  : integer := 32;
            DTCM_ADDR_WIDTH : integer := 8;
            WORDS_NUM       : integer := 256
        );
        port(
            -- Inputs
            clk_i           : in  std_logic;
            rst_i           : in  std_logic;
            dtcm_addr_i     : in  std_logic_vector(DTCM_ADDR_WIDTH-1 downto 0);
            dtcm_data_wr_i  : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            MemRead_ctrl_i  : in  std_logic;
            MemWrite_ctrl_i : in  std_logic;

            -- Outputs
            dtcm_data_rd_o  : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0)
        );
    end component;

---------------------------------------------------------------------------------------------
-- IF/ID pipeline register
---------------------------------------------------------------------------------------------
    component IF_ID_REG is
        generic(
            DATA_BUS_WIDTH : integer := 32;
            PC_WIDTH       : integer := 10
        );
        port(
            clk_i           : in  std_logic;
            rst_i           : in  std_logic;
            IFIDWrite_i     : in  std_logic;
            Flush_i         : in  std_logic;

            pc_i            : in  std_logic_vector(PC_WIDTH-1 downto 0);
            pc_plus4_i      : in  std_logic_vector(PC_WIDTH-1 downto 0);
            instruction_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            pc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
            pc_plus4_o      : out std_logic_vector(PC_WIDTH-1 downto 0);
            instruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0)
        );
    end component;

---------------------------------------------------------------------------------------------
-- ID/EX pipeline register
---------------------------------------------------------------------------------------------
    component ID_EX_REG is
        generic(
            DATA_BUS_WIDTH : integer := 32;
            PC_WIDTH       : integer := 10
        );
        port(
            clk_i           : in  std_logic;
            rst_i           : in  std_logic;
            Stall_i         : in  std_logic;
            Flush_i         : in  std_logic;

            pc_i            : in  std_logic_vector(PC_WIDTH-1 downto 0);
            pc_plus4_i      : in  std_logic_vector(PC_WIDTH-1 downto 0);
            instruction_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            read_data1_i    : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            read_data2_i    : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            sign_extend_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            rs1_i           : in  std_logic_vector(4 downto 0);
            rs2_i           : in  std_logic_vector(4 downto 0);
            rd_i            : in  std_logic_vector(4 downto 0);

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

            pc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
            pc_plus4_o      : out std_logic_vector(PC_WIDTH-1 downto 0);
            instruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            read_data1_o    : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            read_data2_o    : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            sign_extend_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            rs1_o           : out std_logic_vector(4 downto 0);
            rs2_o           : out std_logic_vector(4 downto 0);
            rd_o            : out std_logic_vector(4 downto 0);

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
    end component;

---------------------------------------------------------------------------------------------
-- EX/MEM pipeline register
---------------------------------------------------------------------------------------------
    component EX_MEM_REG is
        generic(
            DATA_BUS_WIDTH : integer := 32;
            PC_WIDTH       : integer := 10
        );
        port(
            clk_i           : in  std_logic;
            rst_i           : in  std_logic;
            Flush_i         : in  std_logic;

            pc_i            : in  std_logic_vector(PC_WIDTH-1 downto 0);
            pc_plus4_i      : in  std_logic_vector(PC_WIDTH-1 downto 0);
            instruction_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            alu_res_i       : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            addr_gen_i      : in  std_logic_vector(PC_WIDTH-1 downto 0);
            brTaken_i       : in  std_logic;

            read_data2_i    : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            mul_pp_i        : in  std_logic_vector(63 downto 0);

            rd_i            : in  std_logic_vector(4 downto 0);

            RegDst_ctrl_i   : in  std_logic;
            MemtoReg_ctrl_i : in  std_logic;
            RegWrite_ctrl_i : in  std_logic;
            MemRead_ctrl_i  : in  std_logic;
            MemWrite_ctrl_i : in  std_logic;
            Branch_ctrl_i   : in  std_logic;
            Jal_ctrl_i      : in  std_logic;
            Jalr_ctrl_i     : in  std_logic;
            MULOp_ctrl_i    : in  std_logic;

            pc_o            : out std_logic_vector(PC_WIDTH-1 downto 0);
            pc_plus4_o      : out std_logic_vector(PC_WIDTH-1 downto 0);
            instruction_o   : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            alu_res_o       : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            addr_gen_o      : out std_logic_vector(PC_WIDTH-1 downto 0);
            brTaken_o       : out std_logic;

            read_data2_o    : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            mul_pp_o        : out std_logic_vector(63 downto 0);

            rd_o            : out std_logic_vector(4 downto 0);

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
    end component;

---------------------------------------------------------------------------------------------
-- MEM/WB pipeline register
---------------------------------------------------------------------------------------------
    component MEM_WB_REG is
        generic(
            DATA_BUS_WIDTH : integer := 32;
            PC_WIDTH       : integer := 10
        );
        port(
            clk_i           : in  std_logic;
            rst_i           : in  std_logic;

            pc_i            : in  std_logic_vector(PC_WIDTH-1 downto 0);
            pc_plus4_i      : in  std_logic_vector(PC_WIDTH-1 downto 0);
            instruction_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            alu_res_i       : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            dtcm_data_rd_i  : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            mul_res_i       : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            rd_i            : in  std_logic_vector(4 downto 0);

            RegDst_ctrl_i   : in  std_logic;
            MemtoReg_ctrl_i : in  std_logic;
            RegWrite_ctrl_i : in  std_logic;
            MULOp_ctrl_i    : in  std_logic;

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
    end component;

---------------------------------------------------------------------------------------------
-- Stall unit
---------------------------------------------------------------------------------------------
    component stall_unit is
        port(
            id_ex_memread_i : in  std_logic;
            id_ex_mulop_i   : in  std_logic;
            id_ex_rd_i      : in  std_logic_vector(4 downto 0);

            if_id_rs1_i     : in  std_logic_vector(4 downto 0);
            if_id_rs2_i     : in  std_logic_vector(4 downto 0);
            if_id_uses_rs1_i : in  std_logic;
            if_id_uses_rs2_i : in  std_logic;

            PCwrite_o       : out std_logic;
            IFIDWrite_o     : out std_logic;
            Stall_o         : out std_logic
        );
    end component;

---------------------------------------------------------------------------------------------
-- Forwarding unit
---------------------------------------------------------------------------------------------
    component forwarding_unit is
        port(
            id_ex_rs1_i       : in  std_logic_vector(4 downto 0);
            id_ex_rs2_i       : in  std_logic_vector(4 downto 0);

            ex_mem_rd_i       : in  std_logic_vector(4 downto 0);
            ex_mem_regwrite_i : in  std_logic;

            mem_wb_rd_i       : in  std_logic_vector(4 downto 0);
            mem_wb_regwrite_i : in  std_logic;

            forwardA_o        : out std_logic_vector(1 downto 0);
            forwardB_o        : out std_logic_vector(1 downto 0)
        );
    end component;

---------------------------------------------------------------------------------------------
-- Pipeline muxes: forwarding muxes + WB mux
---------------------------------------------------------------------------------------------
    component pipeline_muxes is
        generic(
            DATA_BUS_WIDTH : integer := 32;
            PC_WIDTH       : integer := 10
        );
        port(
            id_ex_read_data1_i      : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            id_ex_read_data2_i      : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            ex_mem_alu_res_i        : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            forwardA_sel_i          : in  std_logic_vector(1 downto 0);
            forwardB_sel_i          : in  std_logic_vector(1 downto 0);

            mem_wb_alu_res_i        : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            mem_wb_dtcm_data_rd_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            mem_wb_mul_res_i        : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            mem_wb_pc_plus4_i       : in  std_logic_vector(PC_WIDTH-1 downto 0);

            mem_wb_RegDst_ctrl_i    : in  std_logic;
            mem_wb_MemtoReg_ctrl_i  : in  std_logic;
            mem_wb_MULOp_ctrl_i     : in  std_logic;

            forwarded_data1_o       : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
            forwarded_data2_o       : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            store_data_o            : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

            wb_write_data_o         : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0)
        );
    end component;

---------------------------------------------------------------------------------------------
-- Two-stage partial-product multiplier (Figure 6).
--   Stage 1 (EX) : Multiplier16_s1 -> packed partial products {P3,P2,P1,P0}
--   Stage 2 (MEM): Multiplier16_s2 -> 32-bit result
---------------------------------------------------------------------------------------------
    component Multiplier16_s1 is
        port(
            A_i : in  std_logic_vector(15 downto 0);
            B_i : in  std_logic_vector(15 downto 0);
            P_o : out std_logic_vector(63 downto 0)
        );
    end component;

    component Multiplier16_s2 is
        port(
            P_i   : in  std_logic_vector(63 downto 0);
            Res_o : out std_logic_vector(31 downto 0)
        );
    end component;

---------------------------------------------------------------------------------------------
-- PLL
---------------------------------------------------------------------------------------------
    component PLL is
        port(
            areset : in  std_logic := '0';
            inclk0 : in  std_logic := '0';
            c0     : out std_logic;
            locked : out std_logic
        );
    end component;

end aux_package;
