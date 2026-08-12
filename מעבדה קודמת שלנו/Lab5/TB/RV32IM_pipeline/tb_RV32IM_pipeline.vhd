---------------------------------------------------------------------------------------------
-- LAB5 Part 2 : Testbench for RV32IM pipelined core (RV32IM_PIPELINE_CORE).
--
-- Main fix in this version:
--   The old TB detected program halt from IF-stage pc_o/instruction_o.
--   That is wrong for a pipeline, because IF can contain wrong-path instructions that will later
--   be flushed after a taken branch/jump is resolved in MEM.
--
--   This TB detects the final self-loop halt using MEMpc_o/MEMinstruction_o instead.
--   In this DUT, branches/jumps are resolved in the MEM stage, so an instruction that reaches
--   MEM is the first stage where branch/jump behavior is architecturally meaningful enough for
--   this simple halt detector.
--
-- Assumptions about DUT interface:
--   RV32IM_PIPELINE_CORE exposes the normal debug outputs plus per-stage debug taps:
--     IDpc_o, IDinstruction_o, EXpc_o, EXinstruction_o,
--     MEMpc_o, MEMinstruction_o, WBpc_o, WBinstruction_o.
--
-- Validation flow:
--   1. Compile the DUT first.
--   2. Compile this TB.
--   3. Run entity tb_RV32IM_pipeline.
--   4. Export/inspect DTCM and compare against RARS/GOLDEN DTCM.
---------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY STD;
USE STD.ENV.ALL;

USE work.cond_compilation_package.ALL;
USE work.const_package.ALL;

ENTITY tb_RV32IM_pipeline IS
    GENERIC(
        WORD_GRANULARITY  : boolean := G_WORD_GRANULARITY;
        MODELSIM          : integer := 1;        -- force simulation mode: active-high reset, no PLL
        DATA_BUS_WIDTH    : integer := 32;
        ITCM_ADDR_WIDTH   : integer := G_ADDRWIDTH;
        DTCM_ADDR_WIDTH   : integer := G_ADDRWIDTH;
        PC_WIDTH          : integer := G_PC_WIDTH;
        MA_WIDTH          : integer := G_MA_WIDTH;
        DATA_WORDS_NUM    : integer := G_DATA_WORDSNUM;
        CLK_CNT_WIDTH     : integer := 32;       -- wide cycle counter to avoid wrap in long runs
        MAX_CYCLES        : integer := 20000;    -- timeout guard; keep large enough for TEST2/TEST3
        HALT_REPEAT_COUNT : integer := 4;        -- repeated sightings of same MEM self-loop = done
        REQUIRE_HALT      : boolean := true;     -- fail on timeout if halt not reached
        REQUIRE_MUL       : boolean := false     -- optionally require a MUL to reach MEM stage
    );
END ENTITY tb_RV32IM_pipeline;

ARCHITECTURE sim OF tb_RV32IM_pipeline IS

    CONSTANT CLK_PERIOD  : time := 100 ns;
    CONSTANT SETTLE_TIME : time := 10 ns;

    -- Common infinite-loop encodings used as program halt:
    --   jal x0, 0         => j .
    --   beq x0, x0, 0     => branch to itself
    CONSTANT INST_JSELF : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"0000006f";
    CONSTANT INST_BSELF : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000063";

    ---------------------------------------------------------------------------
    -- DUT I/O
    ---------------------------------------------------------------------------
    SIGNAL clk_i : STD_LOGIC := '0';
    SIGNAL rst_i : STD_LOGIC := '1';

    -- IF-stage debug outputs
    SIGNAL pc_o          : STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
    SIGNAL instruction_o : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

    -- Main debug/control outputs
    SIGNAL RegWrite_ctrl_o : STD_LOGIC;
    SIGNAL MemWrite_ctrl_o : STD_LOGIC;
    SIGNAL Branch_ctrl_o   : STD_LOGIC;

    SIGNAL read_data1_o : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL read_data2_o : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL write_data_o : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

    SIGNAL alu_res_o : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL brTaken_o : STD_LOGIC;

    SIGNAL dtcm_addr_o    : STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
    SIGNAL dtcm_data_wr_o : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL dtcm_data_rd_o : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

    SIGNAL mclk_cnt_o : STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
    SIGNAL CLKCNT_o   : STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);
    SIGNAL STCNT_o    : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL FHCNT_o    : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL STRIGGER_o : STD_LOGIC;

    -- Pipeline-stage debug taps
    SIGNAL IDpc_o           : STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
    SIGNAL IDinstruction_o  : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL EXpc_o           : STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
    SIGNAL EXinstruction_o  : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL MEMpc_o          : STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
    SIGNAL MEMinstruction_o : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL WBpc_o           : STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
    SIGNAL WBinstruction_o  : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

    ---------------------------------------------------------------------------
    -- TB visibility signals for waveform/debug
    ---------------------------------------------------------------------------
    SIGNAL tb_cycle_count : integer := 0;
    SIGNAL tb_done        : STD_LOGIC := '0';
    SIGNAL tb_pass        : STD_LOGIC := '0';
    SIGNAL tb_stalls      : integer := 0;
    SIGNAL tb_flushes     : integer := 0;
    SIGNAL tb_stores      : integer := 0;
    SIGNAL tb_mul_mem     : integer := 0;
    SIGNAL tb_regwrites   : integer := 0;
    SIGNAL tb_halt_pc     : STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_halt_repeat : integer := 0;

    FUNCTION u16(v : STD_LOGIC_VECTOR(15 DOWNTO 0)) RETURN natural IS
    BEGIN
        RETURN TO_INTEGER(UNSIGNED(v));
    END FUNCTION;

    -- 16-bit counter delta with wrap handling
    FUNCTION delta16(curr : natural; prev : natural) RETURN natural IS
    BEGIN
        IF curr >= prev THEN
            RETURN curr - prev;
        ELSE
            RETURN curr + 65536 - prev;
        END IF;
    END FUNCTION;

    FUNCTION is_self_loop(inst : STD_LOGIC_VECTOR(31 DOWNTO 0)) RETURN boolean IS
    BEGIN
        RETURN (inst = INST_JSELF) OR (inst = INST_BSELF);
    END FUNCTION;

    FUNCTION is_mul(inst : STD_LOGIC_VECTOR(31 DOWNTO 0)) RETURN boolean IS
    BEGIN
        RETURN (inst AND INST_MUL_MASK) = INST_MUL;
    END FUNCTION;

BEGIN

    ---------------------------------------------------------------------------
    -- DUT
    ---------------------------------------------------------------------------
    DUT : ENTITY work.RV32IM_PIPELINE_CORE
        GENERIC MAP(
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
        PORT MAP(
            rst_i           => rst_i,
            clk_i           => clk_i,
            BPADDR_i        => (others => '0'),

            pc_o            => pc_o,
            instruction_o   => instruction_o,

            RegWrite_ctrl_o => RegWrite_ctrl_o,
            MemWrite_ctrl_o => MemWrite_ctrl_o,
            Branch_ctrl_o   => Branch_ctrl_o,

            read_data1_o    => read_data1_o,
            read_data2_o    => read_data2_o,
            write_data_o    => write_data_o,

            alu_res_o       => alu_res_o,
            brTaken_o       => brTaken_o,

            dtcm_addr_o     => dtcm_addr_o,
            dtcm_data_wr_o  => dtcm_data_wr_o,
            dtcm_data_rd_o  => dtcm_data_rd_o,

            mclk_cnt_o      => mclk_cnt_o,
            CLKCNT_o        => CLKCNT_o,
            STCNT_o         => STCNT_o,
            FHCNT_o         => FHCNT_o,
            STRIGGER_o      => STRIGGER_o,

            IDpc_o           => IDpc_o,
            IDinstruction_o  => IDinstruction_o,
            EXpc_o           => EXpc_o,
            EXinstruction_o  => EXinstruction_o,
            MEMpc_o          => MEMpc_o,
            MEMinstruction_o => MEMinstruction_o,
            WBpc_o           => WBpc_o,
            WBinstruction_o  => WBinstruction_o
        );

    ---------------------------------------------------------------------------
    -- Free-running clock
    ---------------------------------------------------------------------------
    clk_i <= NOT clk_i AFTER CLK_PERIOD / 2;

    ---------------------------------------------------------------------------
    -- Reset: active high for MODELSIM = 1.
    ---------------------------------------------------------------------------
    gen_rst : PROCESS
    BEGIN
        rst_i <= '1';
        WAIT FOR 3 * CLK_PERIOD;
        WAIT UNTIL rising_edge(clk_i);
        rst_i <= '0';
        WAIT;
    END PROCESS;

    ---------------------------------------------------------------------------
    -- Monitor / checker
    ---------------------------------------------------------------------------
    monitor : PROCESS
        VARIABLE cycle       : integer := 0;
        VARIABLE error_count : integer := 0;

        VARIABLE last_stcnt : natural := 0;
        VARIABLE last_fhcnt : natural := 0;
        VARIABLE curr_stcnt : natural := 0;
        VARIABLE curr_fhcnt : natural := 0;
        VARIABLE st_delta   : natural := 0;
        VARIABLE fh_delta   : natural := 0;

        VARIABLE stalls_total  : integer := 0;
        VARIABLE flushes_total : integer := 0;
        VARIABLE stores_total  : integer := 0;
        VARIABLE mul_mem_total : integer := 0;
        VARIABLE regwr_total   : integer := 0;

        VARIABLE halt_pc     : STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0) := (OTHERS => '0');
        VARIABLE halt_seen   : boolean := false;
        VARIABLE halt_repeat : integer := 0;
        VARIABLE halted      : boolean := false;

        PROCEDURE tb_error(msg : IN string) IS
        BEGIN
            error_count := error_count + 1;
            ASSERT FALSE REPORT msg SEVERITY ERROR;
        END PROCEDURE;
    BEGIN
        WAIT UNTIL rst_i = '0';
        WAIT UNTIL rising_edge(clk_i);
        WAIT FOR SETTLE_TIME;

        last_stcnt := u16(STCNT_o);
        last_fhcnt := u16(FHCNT_o);

        WHILE cycle < MAX_CYCLES LOOP
            WAIT UNTIL rising_edge(clk_i);
            cycle := cycle + 1;
            tb_cycle_count <= cycle;
            WAIT FOR SETTLE_TIME;

            curr_stcnt := u16(STCNT_o);
            curr_fhcnt := u16(FHCNT_o);
            st_delta   := delta16(curr_stcnt, last_stcnt);
            fh_delta   := delta16(curr_fhcnt, last_fhcnt);

            -- Performance counters should not jump by more than one per cycle.
            IF st_delta > 1 THEN
                tb_error("STCNT incremented by more than 1 in a single cycle.");
            END IF;

            IF fh_delta > 1 THEN
                tb_error("FHCNT incremented by more than 1 in a single cycle.");
            END IF;

            stalls_total  := stalls_total  + st_delta;
            flushes_total := flushes_total + fh_delta;

            -- Log every DTCM store. DTCM writes on NOT(clk), so this is the value/control
            -- that will be committed on the following falling edge.
            IF MemWrite_ctrl_o = '1' THEN
                stores_total := stores_total + 1;
                REPORT "STORE cycle=" & integer'image(cycle) &
                       " MEM_PC=0x"    & to_hstring(MEMpc_o) &
                       " dtcm_addr=0x" & to_hstring(dtcm_addr_o) &
                       " data=0x"      & to_hstring(dtcm_data_wr_o)
                       SEVERITY NOTE;
            END IF;

            -- Coarse writeback counter.
            IF RegWrite_ctrl_o = '1' THEN
                regwr_total := regwr_total + 1;
            END IF;

            -- Count MULs that reached MEM stage, not IF fetches.
            -- This avoids counting wrong-path MULs that are fetched but later flushed.
            IF is_mul(MEMinstruction_o) THEN
                mul_mem_total := mul_mem_total + 1;
            END IF;

            -------------------------------------------------------------------
            -- Corrected halt detection:
            -- Use MEM stage, not IF stage.
            -- IF can see the final self-loop as a wrong-path fall-through while a loop
            -- branch is still waiting to be resolved. MEM should only see it if it was
            -- not flushed and is actually executing as the program's final loop.
            -------------------------------------------------------------------
            IF is_self_loop(MEMinstruction_o) THEN
                IF halt_seen AND (MEMpc_o = halt_pc) THEN
                    halt_repeat := halt_repeat + 1;
                ELSE
                    halt_seen   := true;
                    halt_pc     := MEMpc_o;
                    halt_repeat := 1;
                END IF;

                tb_halt_pc     <= MEMpc_o;
                tb_halt_repeat <= halt_repeat;
            END IF;

            -- Mirror to visible waveform signals.
            tb_stalls    <= stalls_total;
            tb_flushes   <= flushes_total;
            tb_stores    <= stores_total;
            tb_mul_mem   <= mul_mem_total;
            tb_regwrites <= regwr_total;

            -- Periodic heartbeat.
            IF (cycle MOD 512) = 0 THEN
                REPORT "heartbeat cycle=" & integer'image(cycle) &
                       " IF_PC=0x"  & to_hstring(pc_o) &
                       " MEM_PC=0x" & to_hstring(MEMpc_o) &
                       " WB_PC=0x"  & to_hstring(WBpc_o) &
                       " STCNT="    & integer'image(curr_stcnt) &
                       " FHCNT="    & integer'image(curr_fhcnt) &
                       " mclk="     & integer'image(TO_INTEGER(UNSIGNED(mclk_cnt_o)))
                       SEVERITY NOTE;
            END IF;

            IF halt_repeat >= HALT_REPEAT_COUNT THEN
                halted := true;
                EXIT;
            END IF;

            last_stcnt := curr_stcnt;
            last_fhcnt := curr_fhcnt;
        END LOOP;

        tb_done <= '1';

        IF REQUIRE_HALT AND NOT halted THEN
            tb_error("TIMEOUT: MEM-stage program self-loop halt was not reached before MAX_CYCLES.");
        END IF;

        IF REQUIRE_MUL AND mul_mem_total = 0 THEN
            tb_error("REQUIRE_MUL failed: no MUL instruction reached MEM stage.");
        END IF;

        IF error_count = 0 THEN
            tb_pass <= '1';
            REPORT "RV32IM pipeline TB PASS." &
                   " cycles="         & integer'image(cycle) &
                   " mclk_cnt="       & integer'image(TO_INTEGER(UNSIGNED(mclk_cnt_o))) &
                   " stalls="         & integer'image(stalls_total) &
                   " flushes="        & integer'image(flushes_total) &
                   " stores="         & integer'image(stores_total) &
                   " mul_mem="        & integer'image(mul_mem_total) &
                   " reg_writebacks=" & integer'image(regwr_total) &
                   " halted="         & boolean'image(halted) &
                   " halt_pc=0x"      & to_hstring(halt_pc)
                   SEVERITY NOTE;

            REPORT "DTCM validation still must be done by comparing exported DTCM against the RARS/GOLDEN DTCM."
                   SEVERITY NOTE;
        ELSE
            ASSERT FALSE
                REPORT "RV32IM pipeline TB FAILED with " & integer'image(error_count) & " error(s)."
                SEVERITY FAILURE;
        END IF;

        STOP;
        WAIT;
    END PROCESS;

END ARCHITECTURE sim;