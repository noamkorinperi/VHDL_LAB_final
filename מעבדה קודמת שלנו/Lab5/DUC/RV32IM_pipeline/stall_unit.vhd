LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

entity stall_unit is
	port(
		-- Inputs from the instruction currently in EX (ID/EX register)
		id_ex_memread_i 	: in std_logic;
		id_ex_mulop_i		: in std_logic;
		id_ex_rd_i 			: in std_logic_vector(4 downto 0);

		-- Source-register indexes of the instruction currently in ID (IF/ID register)
		if_id_rs1_i			: in std_logic_vector(4 downto 0);
		if_id_rs2_i			: in std_logic_vector(4 downto 0);

		-- Decoded source-use enables of the instruction currently in ID.
		-- These avoid false stalls for instructions that do not really read rs1/rs2
		-- (for example addi/lw/jalr do not read rs2; lui/auipc/jal read neither rs1 nor rs2).
		if_id_uses_rs1_i	: in std_logic;
		if_id_uses_rs2_i	: in std_logic;
			
		-- Outputs
		PCwrite_o			: out std_logic;
		IFIDWrite_o			: out std_logic;
		Stall_o				: out std_logic
	);
end stall_unit;

ARCHITECTURE behavior OF stall_unit IS
	SIGNAL hazard : STD_LOGIC;
BEGIN

	-- One-cycle interlock for values that are not forwardable from EX/MEM yet:
	--   * load-use
	--   * mul-use, because this design finishes MUL in MEM and forwards it from MEM/WB
	hazard <= '1' WHEN (id_ex_rd_i /= "00000" and
						(id_ex_memread_i = '1' or id_ex_mulop_i = '1') and 
						((if_id_uses_rs1_i = '1' and id_ex_rd_i = if_id_rs1_i) or
						 (if_id_uses_rs2_i = '1' and id_ex_rd_i = if_id_rs2_i)))
				else '0';

	PCwrite_o   <= '0' WHEN hazard = '1' else '1';
	IFIDWrite_o <= '0' WHEN hazard = '1' else '1';
	Stall_o     <= hazard;
	
end behavior;
