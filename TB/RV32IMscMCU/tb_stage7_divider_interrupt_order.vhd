library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

use work.cond_compilation_package.all;

entity tb_stage7_divider_interrupt_order is
end entity;

architecture sim of tb_stage7_divider_interrupt_order is
    constant MCLK_PERIOD   : time := 40 ns;
    constant DIVCLK_PERIOD : time := 20 ns;

    signal mclk, divclk, reset, intr : std_logic := '0';
    signal dbus_rdata, dbus_addr, dbus_wdata : std_logic_vector(31 downto 0);
    signal dbus_read, dbus_write, inta, gie : std_logic;
    signal pc : std_logic_vector(G_PC_WIDTH-1 downto 0);
    signal instruction : std_logic_vector(31 downto 0);
    signal reg_write, mem_write, branch : std_logic;
    signal read_data1, read_data2, write_data, alu_result : std_logic_vector(31 downto 0);
    signal branch_taken : std_logic;
    signal dtcm_addr : std_logic_vector(G_ADDRWIDTH-1 downto 0);
    signal dtcm_data_wr, dtcm_data_rd : std_logic_vector(31 downto 0);
    signal div_busy, div_done : std_logic;
    signal div_result : std_logic_vector(31 downto 0);
    signal irq_active : std_logic;
    signal irq_type : std_logic_vector(7 downto 0);
    signal mclk_count : std_logic_vector(15 downto 0);
begin
    mclk   <= not mclk after MCLK_PERIOD/2;
    divclk <= not divclk after DIVCLK_PERIOD/2;

    -- During INTA the interrupt source owns the shared DATA BUS and supplies
    -- TYPE=0x14.  The following CPU read obtains that vector's ISR address.
    dbus_rdata <= x"00000014" when inta = '1' else
                  x"00000018" when dbus_read = '1' and dbus_addr = x"00000014" else
                  (others => '0');

    dut : entity work.RV32I_CORE
        generic map (
            ITCM_INIT_FILE => "../../TB/RV32IMscMCU/stage7_divider_interrupt_order_ITCM.hex",
            DTCM_INIT_FILE => ""
        )
        port map (
            rst_i => reset, clk_i => mclk, divclk_i => divclk, intr_i => intr,
            dbus_rdata_i => dbus_rdata, dbus_addr_o => dbus_addr,
            dbus_wdata_o => dbus_wdata, dbus_read_o => dbus_read,
            dbus_write_o => dbus_write, inta_o => inta, gie_o => gie,
            pc_o => pc, instruction_o => instruction,
            RegWrite_ctrl_o => reg_write, MemWrite_ctrl_o => mem_write,
            Branch_ctrl_o => branch, read_data1_o => read_data1,
            read_data2_o => read_data2, write_data_o => write_data,
            alu_res_o => alu_result, brTaken_o => branch_taken,
            dtcm_addr_o => dtcm_addr, dtcm_data_wr_o => dtcm_data_wr,
            dtcm_data_rd_o => dtcm_data_rd, div_busy_o => div_busy,
            div_done_o => div_done, div_result_o => div_result,
            irq_active_o => irq_active, irq_type_o => irq_type,
            mclk_cnt_o => mclk_count
        );

    stimulus : process
        variable saw_div_done, saw_div_writeback, saw_quotient_store, saw_inta : boolean := false;
        variable saw_isr, saw_return : boolean := false;
    begin
        reset <= '1';
        wait for 5*MCLK_PERIOD;
        wait until rising_edge(mclk);
        reset <= '0';

        for cycle in 0 to 30 loop
            wait until rising_edge(mclk);
            wait for 1 ns;
            exit when gie = '1';
        end loop;
        assert gie = '1' report "Divider/interrupt order: firmware did not enable GIE" severity failure;

        for cycle in 0 to 30 loop
            wait until rising_edge(mclk);
            wait for 1 ns;
            exit when div_busy = '1';
        end loop;
        assert div_busy = '1' report "Divider/interrupt order: DIV did not start" severity failure;

        -- Keep the interrupt pending from the middle of DIV until acceptance.
        intr <= '1';
        for cycle in 0 to 200 loop
            wait until rising_edge(mclk);
            wait for 1 ns;

            if div_done = '1' then
                saw_div_done := true;
                assert div_result = x"00000021"
                    report "Divider/interrupt order: 100 / 3 result is incorrect"
                    severity failure;
            end if;

            if reg_write = '1' and instruction = x"0220C2B3" then
                assert write_data = x"00000021"
                    report "Divider/interrupt order: DIV write-back is incorrect"
                    severity failure;
                saw_div_writeback := true;
            end if;

            if dbus_write = '1' and dbus_addr = x"00000000" then
                assert dbus_wdata = x"00000021"
                    report "Divider/interrupt order: quotient store is incorrect"
                    severity failure;
                saw_quotient_store := true;
            end if;

            if inta = '1' then
                assert saw_div_done
                    report "Divider/interrupt order: INTA preceded DIV completion"
                    severity failure;
                assert saw_div_writeback
                    report "Divider/interrupt order: INTA preceded DIV retirement/write-back"
                    severity failure;
                saw_inta := true;
                intr <= '0';
            end if;

            if pc = std_logic_vector(to_unsigned(16#18#, pc'length)) then
                saw_isr := true;
            end if;
            if saw_isr and gie = '1' and irq_active = '0' then
                saw_return := true;
            end if;
            if saw_return and saw_quotient_store then
                exit;
            end if;
        end loop;

        assert saw_div_done report "Divider/interrupt order: DIV never completed" severity failure;
        assert saw_div_writeback report "Divider/interrupt order: DIV result never retired" severity failure;
        assert saw_inta report "Divider/interrupt order: pending interrupt was never accepted" severity failure;
        assert saw_isr report "Divider/interrupt order: ISR vector was not entered" severity failure;
        assert saw_return report "Divider/interrupt order: ISR did not return and restore GIE" severity failure;
        assert saw_quotient_store
            report "Divider/interrupt order: interrupted flow did not resume and store the quotient"
            severity failure;

        report "STAGE 7 DIVIDER/INTERRUPT ORDER PASS" severity note;
        stop;
        wait;
    end process;
end architecture;
