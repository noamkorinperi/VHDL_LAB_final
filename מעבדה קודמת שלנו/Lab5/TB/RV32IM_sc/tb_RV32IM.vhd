---------------------------------------------------------------------------------------------
-- LAB5 Part 1: RV32IM partial single-cycle core testbench for waveform validation
---------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY STD;
USE STD.ENV.ALL;

USE work.cond_compilation_package.ALL;
USE work.const_package.ALL;

ENTITY tb_RV32IM IS
    GENERIC(
        WORD_GRANULARITY   : boolean := G_WORD_GRANULARITY;
        -- Force ModelSim mode even if cond_compilation_package has G_MODELSIM=0 for Quartus.
        MODELSIM           : integer := 1;
        DATA_BUS_WIDTH     : integer := 32;
        ITCM_ADDR_WIDTH    : integer := G_ADDRWIDTH;
        DTCM_ADDR_WIDTH    : integer := G_ADDRWIDTH;
        PC_WIDTH           : integer := G_PC_WIDTH;
        MA_WIDTH           : integer := G_MA_WIDTH;
        DATA_WORDS_NUM     : integer := G_DATA_WORDSNUM;
        CLK_CNT_WIDTH      : integer := 16;
        MAX_CYCLES         : integer := 5000;
        HALT_STABLE_CYCLES : integer := 16
    );
END ENTITY tb_RV32IM;

ARCHITECTURE sim OF tb_RV32IM IS
    CONSTANT CLK_PERIOD : time := 100 ns;

    -- Core inputs
    SIGNAL rst_i : STD_LOGIC := '1';
    SIGNAL clk_i : STD_LOGIC := '0';

    -- Core outputs
    SIGNAL pc_o              : STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0);
    SIGNAL instruction_o     : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

    SIGNAL RegWrite_ctrl_o   : STD_LOGIC;
    SIGNAL MemWrite_ctrl_o   : STD_LOGIC;
    SIGNAL Branch_ctrl_o     : STD_LOGIC;

    SIGNAL read_data1_o      : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL read_data2_o      : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL write_data_o      : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

    SIGNAL alu_res_o         : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL brTaken_o         : STD_LOGIC;

    SIGNAL dtcm_addr_o       : STD_LOGIC_VECTOR(DTCM_ADDR_WIDTH-1 DOWNTO 0);
    SIGNAL dtcm_data_wr_o    : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);
    SIGNAL dtcm_data_rd_o    : STD_LOGIC_VECTOR(DATA_BUS_WIDTH-1 DOWNTO 0);

    SIGNAL mclk_cnt_o        : STD_LOGIC_VECTOR(CLK_CNT_WIDTH-1 DOWNTO 0);

    --------------------------------------------------------------------
    -- TB-level debug signals for Wave window
    --------------------------------------------------------------------
    SIGNAL tb_cycle_count    : integer := 0;
    SIGNAL tb_mul_detected   : STD_LOGIC := '0';
    SIGNAL tb_expected_mul   : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL tb_mul_match      : STD_LOGIC := '0';
    SIGNAL tb_mul_count      : integer := 0;
    SIGNAL tb_mul_fail_count : integer := 0;
    SIGNAL tb_store_count    : integer := 0;
    SIGNAL tb_halt_detected  : STD_LOGIC := '0';
    SIGNAL tb_done           : STD_LOGIC := '0';
    SIGNAL tb_pass           : STD_LOGIC := '0';

    FUNCTION is_mul_instruction(inst : STD_LOGIC_VECTOR(31 DOWNTO 0)) RETURN boolean IS
    BEGIN
        RETURN ((inst AND INST_MUL_MASK) = INST_MUL);
    END FUNCTION;

    -- LAB5 requirement: multiply only the lower 16 bits of rs1 and rs2.
    FUNCTION mul16_reference(a : STD_LOGIC_VECTOR(31 DOWNTO 0);
                             b : STD_LOGIC_VECTOR(31 DOWNTO 0)) RETURN STD_LOGIC_VECTOR IS
        VARIABLE p : UNSIGNED(31 DOWNTO 0);
    BEGIN
        p := RESIZE(UNSIGNED(a(15 DOWNTO 0)) * UNSIGNED(b(15 DOWNTO 0)), 32);
        RETURN STD_LOGIC_VECTOR(p);
    END FUNCTION;

BEGIN
    CORE : ENTITY work.RV32I_CORE
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
            rst_i            => rst_i,
            clk_i            => clk_i,

            pc_o             => pc_o,
            instruction_o    => instruction_o,

            RegWrite_ctrl_o  => RegWrite_ctrl_o,
            MemWrite_ctrl_o  => MemWrite_ctrl_o,
            Branch_ctrl_o    => Branch_ctrl_o,

            read_data1_o     => read_data1_o,
            read_data2_o     => read_data2_o,
            write_data_o     => write_data_o,

            alu_res_o        => alu_res_o,
            brTaken_o        => brTaken_o,

            dtcm_addr_o      => dtcm_addr_o,
            dtcm_data_wr_o   => dtcm_data_wr_o,
            dtcm_data_rd_o   => dtcm_data_rd_o,

            mclk_cnt_o       => mclk_cnt_o
        );

    --------------------------------------------------------------------
    -- Clock generation: 100 ns period, same as the original tb_RV32I style.
    --------------------------------------------------------------------
    clk_i <= NOT clk_i AFTER CLK_PERIOD / 2;

    --------------------------------------------------------------------
    -- Reset generation: active-high reset in ModelSim.
    --------------------------------------------------------------------
    gen_rst : PROCESS
    BEGIN
        rst_i <= '1';
        WAIT FOR 3 * CLK_PERIOD;
        rst_i <= '0';
        WAIT;
    END PROCESS;

    --------------------------------------------------------------------
    -- Continuous TB debug signals for Wave window.
    --------------------------------------------------------------------
    tb_mul_detected <= '1' WHEN is_mul_instruction(instruction_o) ELSE '0';
    tb_expected_mul <= mul16_reference(read_data1_o, read_data2_o);
    tb_mul_match    <= '1' WHEN (alu_res_o = tb_expected_mul) ELSE '0';

    --------------------------------------------------------------------
    -- Monitor/checker: no external files, only assertions + Wave signals.
    --------------------------------------------------------------------
    monitor : PROCESS
        VARIABLE cycle          : integer := 0;
        VARIABLE mul_count      : integer := 0;
        VARIABLE mul_fail_count : integer := 0;
        VARIABLE store_count    : integer := 0;
        VARIABLE halt_count     : integer := 0;
        VARIABLE last_pc        : STD_LOGIC_VECTOR(PC_WIDTH-1 DOWNTO 0) := (OTHERS => '1');
    BEGIN
        WAIT UNTIL rst_i = '0';
        WAIT UNTIL rising_edge(clk_i);

        WHILE cycle < MAX_CYCLES LOOP
            WAIT UNTIL rising_edge(clk_i);
            cycle := cycle + 1;
            tb_cycle_count <= cycle;

            -- Let combinational logic settle while still sampling before the falling-edge DTCM write.
            WAIT FOR 10 ns;

            IF tb_mul_detected = '1' THEN
                mul_count := mul_count + 1;

                IF alu_res_o /= tb_expected_mul THEN
                    mul_fail_count := mul_fail_count + 1;
                    ASSERT FALSE
                        REPORT "RV32IM MUL ERROR: alu_res_o does not match lower16(rs1)*lower16(rs2)."
                        SEVERITY ERROR;
                END IF;

                IF RegWrite_ctrl_o /= '1' THEN
                    mul_fail_count := mul_fail_count + 1;
                    ASSERT FALSE
                        REPORT "RV32IM MUL ERROR: RegWrite_ctrl_o is not asserted during mul."
                        SEVERITY ERROR;
                END IF;

                IF MemWrite_ctrl_o /= '0' THEN
                    mul_fail_count := mul_fail_count + 1;
                    ASSERT FALSE
                        REPORT "RV32IM MUL ERROR: MemWrite_ctrl_o is asserted during mul."
                        SEVERITY ERROR;
                END IF;

                IF Branch_ctrl_o /= '0' THEN
                    mul_fail_count := mul_fail_count + 1;
                    ASSERT FALSE
                        REPORT "RV32IM MUL ERROR: Branch_ctrl_o is asserted during mul."
                        SEVERITY ERROR;
                END IF;
            END IF;

            IF MemWrite_ctrl_o = '1' THEN
                store_count := store_count + 1;
            END IF;

            tb_mul_count      <= mul_count;
            tb_mul_fail_count <= mul_fail_count;
            tb_store_count    <= store_count;

            -- Stop when the benchmark reaches its usual infinite halt loop.
            -- In the LAB5 benchmark this is typically instruction 0x00000063 at a stable PC.
            IF (instruction_o = x"00000063") AND (pc_o = last_pc) THEN
                halt_count := halt_count + 1;
            ELSE
                halt_count := 0;
            END IF;
            last_pc := pc_o;

            IF halt_count >= HALT_STABLE_CYCLES THEN
                tb_halt_detected <= '1';
                EXIT;
            END IF;
        END LOOP;

        tb_done <= '1';

        ASSERT cycle < MAX_CYCLES
            REPORT "RV32IM TB TIMEOUT: benchmark did not reach halt loop before MAX_CYCLES."
            SEVERITY FAILURE;

        ASSERT mul_count > 0
            REPORT "RV32IM TB FAILURE: no mul instruction was observed. Check that ITCM.hex is an RV32IM benchmark."
            SEVERITY FAILURE;

        ASSERT mul_fail_count = 0
            REPORT "RV32IM TB FAILURE: one or more mul checks failed. See Wave signals tb_mul_detected, tb_expected_mul, tb_mul_match."
            SEVERITY FAILURE;

        ASSERT store_count > 0
            REPORT "RV32IM TB FAILURE: no DTCM write was observed."
            SEVERITY FAILURE;

        tb_pass <= '1';
        REPORT "RV32IM TB PASS: mul instructions checked successfully. Use Wave window for waveform evidence." SEVERITY NOTE;
        STOP;
    END PROCESS;

END ARCHITECTURE sim;
