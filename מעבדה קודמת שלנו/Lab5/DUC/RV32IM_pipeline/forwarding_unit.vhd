LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

entity forwarding_unit is
	port(
		--inputs
		id_ex_rs1_i			: in std_logic_vector(4 downto 0);
		id_ex_rs2_i			: in std_logic_vector(4 downto 0);
		ex_mem_rd_i			: in std_logic_vector(4 downto 0);
		ex_mem_regwrite_i  : in  std_logic;
        mem_wb_rd_i        : in  std_logic_vector(4 downto 0);
        mem_wb_regwrite_i  : in  std_logic;

        --outputs
        forwardA_o         : out std_logic_vector(1 downto 0);
        forwardB_o         : out std_logic_vector(1 downto 0)
    );
end forwarding_unit;

architecture behavior of forwarding_unit is
begin
	-- forward A
	forwardA_o <= "10" when (ex_mem_regwrite_i = '1' and ex_mem_rd_i /= "00000" and ex_mem_rd_i = id_ex_rs1_i)
	else "01" when (mem_wb_regwrite_i = '1' and mem_wb_rd_i /= "00000" and mem_wb_rd_i = id_ex_rs1_i)
    else "00";
	
	--forward B
	forwardB_o <= "10" when (ex_mem_regwrite_i = '1' and ex_mem_rd_i /= "00000" and ex_mem_rd_i = id_ex_rs2_i)
	else "01" when (mem_wb_regwrite_i = '1' and mem_wb_rd_i /= "00000" and mem_wb_rd_i = id_ex_rs2_i)
    else "00";


end behavior;