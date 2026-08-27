library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

entity tb_stage1_interconnect is end entity;

architecture sim of tb_stage1_interconnect is
    signal cpu_addr, cpu_wdata, cpu_rdata : std_logic_vector(31 downto 0) := (others => '0');
    signal cpu_read, cpu_write : std_logic := '0';
    signal dtcm_addr : std_logic_vector(10 downto 0);
    signal dtcm_wdata, dtcm_rdata : std_logic_vector(31 downto 0) := (others => '0');
    signal dtcm_read, dtcm_write : std_logic;
    signal mmio_addr, mmio_wdata, mmio_rdata : std_logic_vector(31 downto 0) := (others => '0');
    signal mmio_read, mmio_write, mmio_hit, unmapped : std_logic := '0';
    signal data_bus : std_logic_vector(31 downto 0) := (others => 'Z');
    signal inta : std_logic := '0';
    signal interrupt_type : std_logic_vector(7 downto 0) := x"00";
begin
    dut : entity work.mcu_interconnect
        generic map (DTCM_ADDR_WIDTH => 11)
        port map (
            cpu_addr_i => cpu_addr, cpu_wdata_i => cpu_wdata,
            cpu_read_i => cpu_read, cpu_write_i => cpu_write, cpu_rdata_o => cpu_rdata,
            data_bus_io => data_bus, inta_i => inta,
            interrupt_type_i => interrupt_type,
            dtcm_addr_o => dtcm_addr, dtcm_wdata_o => dtcm_wdata,
            dtcm_read_o => dtcm_read, dtcm_write_o => dtcm_write,
            dtcm_rdata_i => dtcm_rdata,
            mmio_addr_o => mmio_addr, mmio_wdata_o => mmio_wdata,
            mmio_read_o => mmio_read, mmio_write_o => mmio_write,
            mmio_rdata_i => mmio_rdata, mmio_hit_i => mmio_hit,
            unmapped_o => unmapped
        );

    stimulus : process
    begin
        -- DTCM byte address 0x10 must become word index 4.
        cpu_addr <= x"00000010"; cpu_read <= '1'; dtcm_rdata <= x"AABBCCDD"; wait for 1 ns;
        assert dtcm_read = '1' and mmio_read = '0' and dtcm_addr = "00000000100"
            report "Stage 1: DTCM decode/address conversion failed" severity failure;
        assert data_bus = x"AABBCCDD" and cpu_rdata = x"AABBCCDD"
            report "Stage 1: DTCM did not own the bidirectional DATA BUS" severity failure;

        -- Preserve low byte address bits for adjacent MMIO byte registers.
        cpu_read <= '0'; cpu_write <= '1'; cpu_addr <= x"00002005";
        cpu_wdata <= x"11223344"; mmio_hit <= '1'; wait for 1 ns;
        assert mmio_write = '1' and dtcm_write = '0'
            report "Stage 1: MMIO write also selected DTCM" severity failure;
        assert mmio_addr = x"00002005" and mmio_wdata = x"11223344"
            report "Stage 1: full MMIO address/data not preserved" severity failure;
        assert data_bus = x"11223344"
            report "Stage 1: CPU did not drive the DATA BUS during write" severity failure;

        cpu_write <= '0'; cpu_read <= '1'; mmio_rdata <= x"0000005A"; wait for 1 ns;
        assert data_bus = x"0000005A" and cpu_rdata = x"0000005A"
            report "Stage 1: MMIO did not own the bidirectional DATA BUS" severity failure;

        mmio_hit <= '0'; wait for 1 ns;
        assert unmapped = '1' and data_bus = (data_bus'range => 'Z')
            report "Stage 1: unimplemented MMIO behavior failed" severity failure;

        -- TYPE is placed directly on DATA BUS during INTA, without an address
        -- transaction and without any competing driver.
        cpu_read <= '0'; inta <= '1'; interrupt_type <= x"1C"; wait for 1 ns;
        assert data_bus = x"0000001C" and cpu_rdata = x"0000001C" and
               dtcm_read = '0' and mmio_read = '0'
            report "Stage 1: INTA/TYPE DATA BUS ownership failed" severity failure;
        inta <= '0'; wait for 1 ns;
        assert data_bus = (data_bus'range => 'Z')
            report "Stage 1: DATA BUS was not released to Hi-Z" severity failure;

        cpu_read <= '1'; cpu_addr <= x"00004000"; wait for 1 ns;
        assert unmapped = '1' and dtcm_read = '0' and mmio_read = '0'
            report "Stage 1: out-of-range decode failed" severity failure;
        report "STAGE 1 INTERCONNECT PASS" severity note;
        stop;
    end process;
end architecture;
