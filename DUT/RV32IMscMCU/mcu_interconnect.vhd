library ieee;
use ieee.std_logic_1164.all;

use work.mcu_memory_map_pkg.all;

entity mcu_interconnect is
    generic (
        DTCM_ADDR_WIDTH : positive := 11
    );
    port (
        cpu_addr_i   : in  std_logic_vector(31 downto 0);
        cpu_wdata_i  : in  std_logic_vector(31 downto 0);
        cpu_read_i   : in  std_logic;
        cpu_write_i  : in  std_logic;
        cpu_rdata_o  : out std_logic_vector(31 downto 0);
        data_bus_io : inout std_logic_vector(31 downto 0);
        inta_i : in std_logic;
        interrupt_type_i : in std_logic_vector(7 downto 0);

        dtcm_addr_o  : out std_logic_vector(DTCM_ADDR_WIDTH-1 downto 0);
        dtcm_wdata_o : out std_logic_vector(31 downto 0);
        dtcm_read_o  : out std_logic;
        dtcm_write_o : out std_logic;
        dtcm_rdata_i : in  std_logic_vector(31 downto 0);

        mmio_addr_o  : out std_logic_vector(31 downto 0);
        mmio_wdata_o : out std_logic_vector(31 downto 0);
        mmio_read_o  : out std_logic;
        mmio_write_o : out std_logic;
        mmio_rdata_i : in  std_logic_vector(31 downto 0);
        mmio_hit_i   : in  std_logic;

        unmapped_o   : out std_logic
    );
end entity;

architecture rtl of mcu_interconnect is
    signal dtcm_selected_w : std_logic;
    signal mmio_selected_w : std_logic;
begin
    dtcm_selected_w <= '1' when is_dtcm_address(cpu_addr_i) else '0';
    mmio_selected_w <= '1' when is_mmio_address(cpu_addr_i) else '0';

    -- DTCM is word-addressed internally, while the CPU/MMIO bus preserves all
    -- byte address bits (required by HEX1/3/5 and later byte registers).
    dtcm_addr_o  <= cpu_addr_i(DTCM_ADDR_WIDTH+1 downto 2);
    dtcm_read_o  <= cpu_read_i and not cpu_write_i and not inta_i and dtcm_selected_w;
    dtcm_write_o <= cpu_write_i and dtcm_selected_w;

    mmio_addr_o  <= cpu_addr_i;
    mmio_read_o  <= cpu_read_i and not cpu_write_i and not inta_i and mmio_selected_w;
    mmio_write_o <= cpu_write_i and mmio_selected_w;

    -- Figure 1/5/15 shared bidirectional DATA BUS. Exactly one source owns the
    -- bus in each transfer; all other sources release it to high impedance.
    data_bus_io <= cpu_wdata_i when cpu_write_i = '1' else (others => 'Z');
    data_bus_io <= dtcm_rdata_i when cpu_read_i = '1' and cpu_write_i = '0' and
                                    inta_i = '0' and dtcm_selected_w = '1'
                   else (others => 'Z');
    data_bus_io <= mmio_rdata_i when cpu_read_i = '1' and cpu_write_i = '0' and
                                    inta_i = '0' and mmio_selected_w = '1' and
                                    mmio_hit_i = '1'
                   else (others => 'Z');
    data_bus_io <= x"000000" & interrupt_type_i
                   when inta_i = '1' and cpu_write_i = '0'
                   else (others => 'Z');

    cpu_rdata_o  <= data_bus_io;
    dtcm_wdata_o <= data_bus_io;
    mmio_wdata_o <= data_bus_io;

    unmapped_o <= (cpu_read_i or cpu_write_i) and not inta_i and not dtcm_selected_w and
                  not (mmio_selected_w and mmio_hit_i);
end architecture;
