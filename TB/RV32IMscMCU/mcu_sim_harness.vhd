library ieee;
use ieee.std_logic_1164.all;

use work.cond_compilation_package.all;

entity mcu_sim_harness is
    generic (
        ITCM_INIT_FILE : string := "ITCM.hex";
        DTCM_INIT_FILE : string := "DTCM.hex"
    );
    port (
        sys_clk_i : in std_logic;
        div_clk_i : in std_logic;
        reset_i   : in std_logic;
        switches_i : in std_logic_vector(7 downto 0);
        ledr_o : out std_logic_vector(7 downto 0);
        hex0_o, hex1_o, hex2_o, hex3_o, hex4_o, hex5_o : out std_logic_vector(6 downto 0);
        pc_o : out std_logic_vector(G_PC_WIDTH-1 downto 0);
        instruction_o : out std_logic_vector(31 downto 0);
        regwrite_o, memwrite_o : out std_logic;
        read_data1_o, read_data2_o, alu_result_o : out std_logic_vector(31 downto 0);
        bus_addr_o, bus_wdata_o : out std_logic_vector(31 downto 0);
        bus_read_o, bus_write_o : out std_logic;
        div_busy_o, div_done_o : out std_logic;
        div_result_o : out std_logic_vector(31 downto 0)
    );
end entity;

architecture sim of mcu_sim_harness is
    signal cpu_addr_w, cpu_wdata_w, cpu_rdata_w : std_logic_vector(31 downto 0);
    signal cpu_read_w, cpu_write_w : std_logic;
    signal dtcm_addr_w : std_logic_vector(G_ADDRWIDTH-1 downto 0);
    signal dtcm_wdata_w, dtcm_rdata_w : std_logic_vector(31 downto 0);
    signal dtcm_read_w, dtcm_write_w : std_logic;
    signal mmio_addr_w, mmio_wdata_w, mmio_rdata_w : std_logic_vector(31 downto 0);
    signal mmio_read_w, mmio_write_w, mmio_hit_w : std_logic;
begin
    cpu : entity work.RV32I_CORE
        generic map (
            WORD_GRANULARITY => true,
            MODELSIM => 1,
            DATA_BUS_WIDTH => 32,
            ITCM_ADDR_WIDTH => G_ADDRWIDTH,
            DTCM_ADDR_WIDTH => G_ADDRWIDTH,
            PC_WIDTH => G_PC_WIDTH,
            MA_WIDTH => G_MA_WIDTH,
            DATA_WORDS_NUM => G_DATA_WORDSNUM,
            ITCM_INIT_FILE => ITCM_INIT_FILE,
            DTCM_INIT_FILE => DTCM_INIT_FILE
        )
        port map (
            rst_i => reset_i, clk_i => sys_clk_i, divclk_i => div_clk_i,
            dbus_rdata_i => cpu_rdata_w, dbus_addr_o => cpu_addr_w,
            dbus_wdata_o => cpu_wdata_w, dbus_read_o => cpu_read_w,
            dbus_write_o => cpu_write_w,
            pc_o => pc_o, instruction_o => instruction_o,
            RegWrite_ctrl_o => regwrite_o, MemWrite_ctrl_o => memwrite_o,
            Branch_ctrl_o => open, read_data1_o => read_data1_o,
            read_data2_o => read_data2_o, write_data_o => open,
            alu_res_o => alu_result_o, brTaken_o => open,
            dtcm_addr_o => open, dtcm_data_wr_o => open, dtcm_data_rd_o => open,
            div_busy_o => div_busy_o, div_done_o => div_done_o,
            div_result_o => div_result_o, mclk_cnt_o => open
        );

    fabric : entity work.mcu_interconnect
        generic map (DTCM_ADDR_WIDTH => G_ADDRWIDTH)
        port map (
            cpu_addr_i => cpu_addr_w, cpu_wdata_i => cpu_wdata_w,
            cpu_read_i => cpu_read_w, cpu_write_i => cpu_write_w,
            cpu_rdata_o => cpu_rdata_w,
            dtcm_addr_o => dtcm_addr_w, dtcm_wdata_o => dtcm_wdata_w,
            dtcm_read_o => dtcm_read_w, dtcm_write_o => dtcm_write_w,
            dtcm_rdata_i => dtcm_rdata_w,
            mmio_addr_o => mmio_addr_w, mmio_wdata_o => mmio_wdata_w,
            mmio_read_o => mmio_read_w, mmio_write_o => mmio_write_w,
            mmio_rdata_i => mmio_rdata_w, mmio_hit_i => mmio_hit_w,
            unmapped_o => open
        );

    dtcm : entity work.dmemory
        generic map (
            DATA_BUS_WIDTH => 32, DTCM_ADDR_WIDTH => G_ADDRWIDTH,
            WORDS_NUM => G_DATA_WORDSNUM, INIT_FILE => DTCM_INIT_FILE
        )
        port map (
            clk_i => sys_clk_i, rst_i => reset_i,
            dtcm_addr_i => dtcm_addr_w, dtcm_data_wr_i => dtcm_wdata_w,
            MemRead_ctrl_i => dtcm_read_w, MemWrite_ctrl_i => dtcm_write_w,
            dtcm_data_rd_o => dtcm_rdata_w
        );

    peripherals : entity work.mcu_peripherals
        generic map (
            PB_DEBOUNCE_CYCLES => 2
        )
        port map (
            clk_i => sys_clk_i, reset_i => reset_i,
            address_i => mmio_addr_w, write_data_i => mmio_wdata_w,
            read_i => mmio_read_w, write_i => mmio_write_w,
            read_data_o => mmio_rdata_w, hit_o => mmio_hit_w,
            switches_i => switches_i, ledr_o => ledr_o,
            keys_n_i => (others => '1'), capin1_i => '0', capin2_i => '0',
            hex0_o => hex0_o, hex1_o => hex1_o, hex2_o => hex2_o,
            hex3_o => hex3_o, hex4_o => hex4_o, hex5_o => hex5_o,
            pwm_o => open, timer_event_o => open, key_event_o => open,
            button_state_o => open, timer_count_o => open,
            timer_capture_o => open
        );

    bus_addr_o  <= cpu_addr_w;
    bus_wdata_o <= cpu_wdata_w;
    bus_read_o  <= cpu_read_w;
    bus_write_o <= cpu_write_w;
end architecture;
