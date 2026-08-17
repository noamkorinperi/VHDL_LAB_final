library ieee;
use ieee.std_logic_1164.all;

use work.cond_compilation_package.all;

entity RV32IMscMCU is
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(3 downto 0);
        SW       : in  std_logic_vector(9 downto 0);
        LEDR     : out std_logic_vector(9 downto 0);
        HEX0     : out std_logic_vector(6 downto 0);
        HEX1     : out std_logic_vector(6 downto 0);
        HEX2     : out std_logic_vector(6 downto 0);
        HEX3     : out std_logic_vector(6 downto 0);
        HEX4     : out std_logic_vector(6 downto 0);
        HEX5     : out std_logic_vector(6 downto 0)
    );
end entity;

architecture structural of RV32IMscMCU is
    signal sysclk_w, pll_locked_w, reset_w : std_logic;

    signal cpu_addr_w, cpu_wdata_w, cpu_rdata_w, bus_rdata_w : std_logic_vector(31 downto 0);
    signal cpu_read_w, cpu_write_w : std_logic;
    signal intr_w, inta_w, gie_w, irq_active_w : std_logic;
    signal interrupt_type_w, interrupt_ie_w, interrupt_ifg_w : std_logic_vector(7 downto 0);
    signal cpu_irq_type_w : std_logic_vector(7 downto 0);

    signal dtcm_addr_w : std_logic_vector(G_ADDRWIDTH-1 downto 0);
    signal dtcm_wdata_w, dtcm_rdata_w : std_logic_vector(31 downto 0);
    signal dtcm_read_w, dtcm_write_w : std_logic;

    signal mmio_addr_w, mmio_wdata_w, mmio_rdata_w : std_logic_vector(31 downto 0);
    signal mmio_read_w, mmio_write_w, mmio_hit_w, unmapped_w : std_logic;
    signal gpio_ledr_w : std_logic_vector(7 downto 0);
    signal pwm_w, timer_event_w : std_logic;
    signal key_event_w, button_state_w : std_logic_vector(2 downto 0);
    signal timer_count_w, timer_capture_w : std_logic_vector(31 downto 0);

    attribute keep : boolean;
    attribute keep of cpu_addr_w, cpu_wdata_w, cpu_rdata_w : signal is true;
    attribute keep of cpu_read_w, cpu_write_w, unmapped_w : signal is true;
    attribute keep of timer_event_w, key_event_w : signal is true;
    attribute keep of timer_count_w, timer_capture_w : signal is true;
    attribute keep of intr_w, inta_w, gie_w, irq_active_w : signal is true;
    attribute keep of interrupt_type_w, interrupt_ie_w, interrupt_ifg_w : signal is true;
begin
    -- The core runs at 20 MHz and the iterative divider at the board's 50 MHz.
    -- 20 MHz meets the falling-edge DTCM timing and matches benchmark constants.
    -- oscillator.  The CDC handshake in divider_accelerator separates domains.
    clock_pll : entity work.PLL
        port map (
            areset => not KEY(0),
            inclk0 => CLOCK_50,
            c0     => sysclk_w,
            locked => pll_locked_w
        );

    reset_w <= (not KEY(0)) or (not pll_locked_w);

    cpu : entity work.RV32I_CORE
        generic map (
            WORD_GRANULARITY => true,
            MODELSIM         => 0,
            DATA_BUS_WIDTH   => 32,
            ITCM_ADDR_WIDTH  => G_ADDRWIDTH,
            DTCM_ADDR_WIDTH  => G_ADDRWIDTH,
            PC_WIDTH         => G_PC_WIDTH,
            MA_WIDTH         => G_MA_WIDTH,
            DATA_WORDS_NUM   => G_DATA_WORDSNUM,
            CLK_CNT_WIDTH    => 16,
            -- Board smoke-test image for the stage-5.5 lab procedure.
            ITCM_INIT_FILE   => "ITCM_stage5_5.hex",
            DTCM_INIT_FILE   => "DTCM.hex"
        )
        port map (
            rst_i            => reset_w,
            clk_i            => sysclk_w,
            divclk_i         => CLOCK_50,
            intr_i           => intr_w,
            dbus_rdata_i     => cpu_rdata_w,
            dbus_addr_o      => cpu_addr_w,
            dbus_wdata_o     => cpu_wdata_w,
            dbus_read_o      => cpu_read_w,
            dbus_write_o     => cpu_write_w,
            inta_o           => inta_w,
            gie_o            => gie_w,
            pc_o             => open,
            instruction_o    => open,
            RegWrite_ctrl_o  => open,
            MemWrite_ctrl_o  => open,
            Branch_ctrl_o    => open,
            read_data1_o     => open,
            read_data2_o     => open,
            write_data_o     => open,
            alu_res_o        => open,
            brTaken_o        => open,
            dtcm_addr_o      => open,
            dtcm_data_wr_o   => open,
            dtcm_data_rd_o   => open,
            div_busy_o       => open,
            div_done_o       => open,
            div_result_o     => open,
            irq_active_o     => irq_active_w,
            irq_type_o       => cpu_irq_type_w,
            mclk_cnt_o       => open
        );

    -- During INTA the controller places TYPE directly on the CPU data bus;
    -- no address-bus transaction is used in the capture cycle.
    cpu_rdata_w <= (31 downto 8 => '0') & interrupt_type_w when inta_w = '1'
                   else bus_rdata_w;

    bus_fabric : entity work.mcu_interconnect
        generic map (DTCM_ADDR_WIDTH => G_ADDRWIDTH)
        port map (
            cpu_addr_i   => cpu_addr_w,
            cpu_wdata_i  => cpu_wdata_w,
            cpu_read_i   => cpu_read_w,
            cpu_write_i  => cpu_write_w,
            cpu_rdata_o  => bus_rdata_w,
            dtcm_addr_o  => dtcm_addr_w,
            dtcm_wdata_o => dtcm_wdata_w,
            dtcm_read_o  => dtcm_read_w,
            dtcm_write_o => dtcm_write_w,
            dtcm_rdata_i => dtcm_rdata_w,
            mmio_addr_o  => mmio_addr_w,
            mmio_wdata_o => mmio_wdata_w,
            mmio_read_o  => mmio_read_w,
            mmio_write_o => mmio_write_w,
            mmio_rdata_i => mmio_rdata_w,
            mmio_hit_i   => mmio_hit_w,
            unmapped_o   => unmapped_w
        );

    data_memory : entity work.dmemory
        generic map (
            DATA_BUS_WIDTH  => 32,
            DTCM_ADDR_WIDTH => G_ADDRWIDTH,
            WORDS_NUM       => G_DATA_WORDSNUM,
            INIT_FILE       => "DTCM.hex"
        )
        port map (
            clk_i           => sysclk_w,
            rst_i           => reset_w,
            dtcm_addr_i     => dtcm_addr_w,
            dtcm_data_wr_i  => dtcm_wdata_w,
            MemRead_ctrl_i  => dtcm_read_w,
            MemWrite_ctrl_i => dtcm_write_w,
            dtcm_data_rd_o  => dtcm_rdata_w
        );

    peripherals : entity work.mcu_peripherals
        port map (
            clk_i        => sysclk_w,
            reset_i      => reset_w,
            address_i    => mmio_addr_w,
            write_data_i => mmio_wdata_w,
            read_i       => mmio_read_w,
            write_i      => mmio_write_w,
            read_data_o  => mmio_rdata_w,
            hit_o        => mmio_hit_w,
            switches_i   => SW(7 downto 0),
            keys_n_i     => KEY(3 downto 1),
            capin1_i     => SW(8),
            capin2_i     => SW(9),
            gie_i        => gie_w,
            inta_i       => inta_w,
            ledr_o       => gpio_ledr_w,
            hex0_o       => HEX0,
            hex1_o       => HEX1,
            hex2_o       => HEX2,
            hex3_o       => HEX3,
            hex4_o       => HEX4,
            hex5_o       => HEX5,
            pwm_o         => pwm_w,
            timer_event_o => timer_event_w,
            key_event_o   => key_event_w,
            button_state_o => button_state_w,
            timer_count_o   => timer_count_w,
            timer_capture_o => timer_capture_w,
            intr_o           => intr_w,
            interrupt_type_o => interrupt_type_w,
            interrupt_ie_o   => interrupt_ie_w,
            interrupt_ifg_o  => interrupt_ifg_w
        );

    LEDR(7 downto 0) <= gpio_ledr_w;
    -- Stage-5.5 board observability: PWM is visible on LEDR8 and LEDR9
    -- lights while any debounced pushbutton is held. Interrupt events remain
    -- internal until the stage-6 interrupt controller consumes them.
    LEDR(8) <= pwm_w;
    LEDR(9) <= button_state_w(0) or button_state_w(1) or button_state_w(2);
end architecture;
