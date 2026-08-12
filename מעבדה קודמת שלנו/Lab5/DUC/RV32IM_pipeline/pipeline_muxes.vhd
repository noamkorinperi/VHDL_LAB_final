library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity pipeline_muxes is
    generic(
        DATA_BUS_WIDTH : integer := 32;
        PC_WIDTH       : integer := 10
    );
    port(
        ------------------------------------------------------------------------
        -- Forwarding mux inputs
        ------------------------------------------------------------------------
        id_ex_read_data1_i      : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        id_ex_read_data2_i      : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        -- Forwarding source from EX/MEM (EX/MEM ALU result).
        ex_mem_alu_res_i        : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        -- Forwarding select signals from forwarding_unit
        -- "00" = use original ID/EX data
        -- "10" = forward from EX/MEM
        -- "01" = forward from MEM/WB writeback data
        -- "11" = unused, treated as original ID/EX data
        forwardA_sel_i          : in  std_logic_vector(1 downto 0);
        forwardB_sel_i          : in  std_logic_vector(1 downto 0);

        ------------------------------------------------------------------------
        -- Writeback mux inputs from MEM/WB register
        ------------------------------------------------------------------------
        mem_wb_alu_res_i        : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        mem_wb_dtcm_data_rd_i   : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        mem_wb_mul_res_i        : in  std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        mem_wb_pc_plus4_i       : in  std_logic_vector(PC_WIDTH-1 downto 0);

        mem_wb_RegDst_ctrl_i    : in  std_logic;
        mem_wb_MemtoReg_ctrl_i  : in  std_logic;
        mem_wb_MULOp_ctrl_i     : in  std_logic;

        ------------------------------------------------------------------------
        -- Outputs
        ------------------------------------------------------------------------
        -- To Execute inputs
        forwarded_data1_o       : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
        forwarded_data2_o       : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        -- To EX/MEM register store-data input (forwarded rs2 value).
        store_data_o            : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

        -- To IDECODE / register-file writeback input
        wb_write_data_o         : out std_logic_vector(DATA_BUS_WIDTH-1 downto 0)
    );
end pipeline_muxes;

architecture behavior of pipeline_muxes is

    signal wb_write_data_w       : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal forwarded_data1_w     : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    signal forwarded_data2_w     : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);

    ------------------------------------------------------------------------
    -- Zero extend PC+4 to DATA_BUS_WIDTH for jal/jalr writeback.
    ------------------------------------------------------------------------
    function zero_extend_pc(
        pc_value : std_logic_vector
    ) return std_logic_vector is
        variable result_v : std_logic_vector(DATA_BUS_WIDTH-1 downto 0);
    begin
        result_v := (others => '0');
        result_v(pc_value'length-1 downto 0) := pc_value;
        return result_v;
    end function;

begin

    ------------------------------------------------------------------------
    -- WB mux
    --
    -- RegDst = 1      -> write PC+4, used for jal/jalr
    -- MemtoReg = 1    -> write DTCM read data, used for load
    -- MULOp = 1       -> write multiplier result (Stage 2, produced in MEM)
    -- otherwise       -> write ALU result
    ------------------------------------------------------------------------
    wb_write_data_w <= zero_extend_pc(mem_wb_pc_plus4_i)
                       when mem_wb_RegDst_ctrl_i = '1' else

                       mem_wb_dtcm_data_rd_i
                       when mem_wb_MemtoReg_ctrl_i = '1' else

                       mem_wb_mul_res_i
                       when mem_wb_MULOp_ctrl_i = '1' else

                       mem_wb_alu_res_i;


    ------------------------------------------------------------------------
    -- Forwarding mux A (operand A into Execute)
    ------------------------------------------------------------------------
    forwarded_data1_w <= ex_mem_alu_res_i
                         when forwardA_sel_i = "10" else

                         wb_write_data_w
                         when forwardA_sel_i = "01" else

                         id_ex_read_data1_i;


    ------------------------------------------------------------------------
    -- Forwarding mux B (operand B / rs2 value; also used as store data)
    ------------------------------------------------------------------------
    forwarded_data2_w <= ex_mem_alu_res_i
                         when forwardB_sel_i = "10" else

                         wb_write_data_w
                         when forwardB_sel_i = "01" else

                         id_ex_read_data2_i;


    ------------------------------------------------------------------------
    -- Output assignments
    ------------------------------------------------------------------------
    forwarded_data1_o <= forwarded_data1_w;
    forwarded_data2_o <= forwarded_data2_w;

    store_data_o      <= forwarded_data2_w;

    wb_write_data_o   <= wb_write_data_w;

end behavior;
