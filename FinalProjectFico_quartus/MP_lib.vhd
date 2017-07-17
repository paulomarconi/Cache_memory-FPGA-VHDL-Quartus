-- Library for Microprocessor example
library	ieee;
use ieee.std_logic_1164.all;  
use ieee.std_logic_arith.all;
USE ieee.numeric_std.all;

package MP_lib is

constant ZERO 	: std_logic_vector(15 downto 0) := "0000000000000000";
constant HIRES	: std_logic_vector(15 downto 0) := "ZZZZZZZZZZZZZZZZ";
constant mov1 	: std_logic_vector(3 downto 0) := "0000"; --0
constant mov2 	: std_logic_vector(3 downto 0) := "0001"; --1
constant mov3 	: std_logic_vector(3 downto 0) := "0010"; --2
constant mov4 	: std_logic_vector(3 downto 0) := "0011"; --3
constant add  	: std_logic_vector(3 downto 0) := "0100"; --4
constant subt 	: std_logic_vector(3 downto 0) := "0101"; --5
constant jz   	: std_logic_vector(3 downto 0) := "0110"; --6
constant readm	: std_logic_vector(3 downto 0) := "0111"; --7
constant mult 	: std_logic_vector(3 downto 0) := "1000"; --8 RF[rn] <- RF[rn] * RF[rm]
constant mov5 	: std_logic_vector(3 downto 0) := "1001"; --9 RF[rm] <- mem[RF[rn]]
constant jne  	: std_logic_vector(3 downto 0) := "1010"; --A RF[rn] ~= RF[rm] : PC[RF[ro]]  
constant inc  	: std_logic_vector(3 downto 0) := "1011"; --B RF[rn] <- RF[rn] + 1
constant mov6 	: std_logic_vector(3 downto 0) := "1100"; --C RF[rn] <- RF[rm]
constant outRF : std_logic_vector(3 downto 0) := "1101"; --D out <- mem[RF[rn]]
constant halt 	: std_logic_vector(3 downto 0) := "1111"; --F

component CPU is
port (	
	cpu_clk					: in std_logic;
	cpu_rst					: in std_logic;
	cpu_button				: in std_logic;
	mdout_bus				: in std_logic_vector(15 downto 0); 
	mdin_bus					: out std_logic_vector(15 downto 0); 
	mem_addr					: out std_logic_vector(10 downto 0);
	Mre_s						: out std_logic;
	Mwe_s						: out std_logic;	
	oe_s						: out std_logic;
	-- Debug variables: output to upper level for simulation purpose only
	D_rfout_bus				: out std_logic_vector(15 downto 0);  
	D_RFwa_s, D_RFr1a_s, D_RFr2a_s: out std_logic_vector(3 downto 0);
	D_RFwe_s, D_RFr1e_s, D_RFr2e_s: out std_logic;
	D_RFs_s					: out std_logic_vector(1 downto 0);
	D_ALUs_s					: out std_logic_vector(2 downto 0);
	D_PCld_s, D_jpz_s		: out std_logic;
	-- end debug variables		
	data_ready				: in std_logic
);
end component;

component alu is
port (	
	num_A		: in std_logic_vector(15 downto 0);
	num_B		: in std_logic_vector(15 downto 0);
	jpsign	: in std_logic;
	ALUs		: in std_logic_vector(2 downto 0);
	ALUz		: out std_logic;
	ALUout	: out std_logic_vector(15 downto 0)
);
end component;

component bigmux is
port( 	
	Ia		: in std_logic_vector(15 downto 0);
	Ib		: in std_logic_vector(15 downto 0);	  
	Ic		: in std_logic_vector(15 downto 0);
	Id		: in std_logic_vector(15 downto 0);
	Option: in std_logic_vector(1 downto 0);
	Muxout: out std_logic_vector(15 downto 0)
);
end component;

component controller is
port(	
	clock			: in std_logic;
	rst			: in std_logic;
	button		: in std_logic;
	IR_word		: in std_logic_vector(15 downto 0);
	RFs_ctrl		: out std_logic_vector(1 downto 0);
	RFwa_ctrl	: out std_logic_vector(3 downto 0);
	RFr1a_ctrl	: out std_logic_vector(3 downto 0);
	RFr2a_ctrl	: out std_logic_vector(3 downto 0);
	RFwe_ctrl	: out std_logic;
	RFr1e_ctrl	: out std_logic;
	RFr2e_ctrl	: out std_logic;						 
	ALUs_ctrl	: out std_logic_vector(2 downto 0);	 
	jmpen_ctrl	: out std_logic;
	PCinc_ctrl	: out std_logic;
	PCclr_ctrl	: out std_logic;
	IRld_ctrl	: out std_logic;
	Ms_ctrl		: out std_logic_vector(1 downto 0);
	Mre_ctrl		: out std_logic;
	Mwe_ctrl		: out std_logic;
	oe_ctrl		: out std_logic;
	data_ready	: in std_logic;
	RFr3a_ctrl	: out std_logic_vector(3 downto 0);
	RFr3e_ctrl	: out std_logic;
	jmux_ctrl	: out std_logic
);
end component;

component IR is
port(	
	IRin		: in std_logic_vector(15 downto 0);
	IRld		: in std_logic;
	dir_addr	: out std_logic_vector(15 downto 0);
	IRout		: out std_logic_vector(15 downto 0)
);
end component;

component memory is
generic(
	data_width	: natural := 16;
	block_size 	: natural := 2; -- word = 2 bits
	line_size 	: natural := 3; -- line = 3 bits
	tag_size 	: natural := 6  -- tag = 7 bits
);
port (
	clock				: in std_logic;
	rst				: in std_logic;
	Mre				: in std_logic;
	Mwe				: in std_logic;
	address			: in std_logic_vector((tag_size+line_size+block_size)-1 downto 0);
	data_in			: in std_logic_vector((data_width-1) downto 0);
	data_out			: out std_logic_vector((data_width-1) downto 0);
	data_ready  	: out std_logic;
	D_SM_rw_enable	: out std_logic;			
	D_new_address	: out std_logic_vector((line_size+tag_size)-1 downto 0);
	D_old_address	: out std_logic_vector((line_size+tag_size)-1 downto 0);
	D_new_data		: out std_logic_vector((data_width*(2**block_size))-1 downto 0);
	D_old_data		: out std_logic_vector((data_width*(2**block_size))-1 downto 0);
	D_word_tmp		: out std_logic_vector((block_size)-1 downto 0);	
	D_line_tmp		: out std_logic_vector((line_size)-1 downto 0);
	D_tag_tmp		: out std_logic_vector((tag_size)-1 downto 0)
);
end component;

component memory_slow is
generic(
	data_width	: natural := 16;
	block_size 	: natural := 2; -- word = 2 bits
	line_size 	: natural := 3; -- line = 3 bits
	tag_size 	: natural := 6  -- tag = 7 bits
);
port (
	clock			: in std_logic;
	rst			: in std_logic;
	SM_rw_enable: in std_logic;
	old_address	: in std_logic_vector((line_size+tag_size)-1 downto 0);
	new_address	: in std_logic_vector((line_size+tag_size)-1 downto 0);
	old_data		: in std_logic_vector((data_width*(2**block_size))-1 downto 0);
	new_data		: out std_logic_vector((data_width*(2**block_size))-1 downto 0)
);
end component;

component memory_simple is
port (	
		clock			: in std_logic;
		rst			: in std_logic;
		Mre			: in std_logic;
		Mwe			: in std_logic;
		address		: in std_logic_vector(10 downto 0);
		data_in		: in std_logic_vector(15 downto 0);
		data_out		: out std_logic_vector(15 downto 0);
		data_ready 	: out std_logic
);
end component;



component obuf is
port(	
	O_en		: in std_logic;
	obuf_in	: in std_logic_vector(15 downto 0);
	obuf_out	: out std_logic_vector(15 downto 0)
);
end component;


component hextodec is
port(
	clock	: in std_logic;
	rst	: in std_logic;
	en		: in std_logic;
	number: in std_logic_vector(15 downto 0);	-- LSB
	fout0	: out std_logic_vector(3 downto 0);
	fout1	: out std_logic_vector(3 downto 0); 
	fout2	: out std_logic_vector(3 downto 0); 
	fout3	: out std_logic_vector(3 downto 0);	
	fout4	: out std_logic_vector(3 downto 0);	
	fout5	: out std_logic_vector(3 downto 0);	-- MSB	
	out7segment0 : out std_logic_vector(6 downto 0);  -- 7 bit decoded output	LSB	0
	out7segment1 : out std_logic_vector(6 downto 0);  -- 7 bit decoded output			6
	out7segment2 : out std_logic_vector(6 downto 0);  -- 7 bit decoded output			5
	out7segment3 : out std_logic_vector(6 downto 0);  -- 7 bit decoded output			5
	out7segment4 : out std_logic_vector(6 downto 0);  -- 7 bit decoded output			3
	out7segment5 : out std_logic_vector(6 downto 0)   -- 7 bit decoded output	MSB	5
);
end component; 

component Deco4bit7segment is
port (
	clock			: in std_logic;
	rst			: in std_logic;
	en				: in std_logic;
	in4bit		: in std_logic_vector(3 downto 0);  --4 bit input
	out7segment : out std_logic_vector(6 downto 0)  -- 7 bit decoded output.
);
end component;


component PC is
port(	
	clock		: in std_logic;
	PCld		: in std_logic;
	PCinc		: in std_logic;
	PCclr		: in std_logic;
	PCin		: in std_logic_vector(15 downto 0);
	PCout		: out std_logic_vector(15 downto 0);
	PCld_jmp	: in std_logic	
);
end component;

component reg_file is
port (
	clock	: in std_logic; 	
	rst	: in std_logic;
	RFwe	: in std_logic;
	RFr1e	: in std_logic;
	RFr2e	: in std_logic;	
	RFwa	: in std_logic_vector(3 downto 0);  
	RFr1a	: in std_logic_vector(3 downto 0);
	RFr2a	: in std_logic_vector(3 downto 0);
	RFw	: in std_logic_vector(15 downto 0);
	RFr1	: out std_logic_vector(15 downto 0);
	RFr2	: out std_logic_vector(15 downto 0);
	RFr3e	: in std_logic;
	RFr3a	: in std_logic_vector(3 downto 0);
	RFr3	: out std_logic_vector(15 downto 0)
);
end component;

component smallmux is
port(
	I0	: in std_logic_vector(15 downto 0);
	I1	: in std_logic_vector(15 downto 0);	  
	I2	: in std_logic_vector(15 downto 0);
	Sel: in std_logic_vector(1 downto 0);
	O	: out std_logic_vector(15 downto 0)
	);
end component;

component jumpmux is
port( 	
	I0		: in std_logic_vector(15 downto 0);
	I1		: in std_logic_vector(15 downto 0);	  
	Sel	: in std_logic;
	Output: out std_logic_vector(15 downto 0)
);
end component;


component ctrl_unit is
port(
	clock_cu			: in 	std_logic;
	rst_cu			: in 	std_logic;
	button_cu		: in 	std_logic;
	PCld_cu			: in 	std_logic;
	mdata_out		: in 	std_logic_vector(15 downto 0);
	dpdata_out		: in 	std_logic_vector(15 downto 0);
	maddr_in			: out	std_logic_vector(15 downto 0);		  
	immdata			: out	std_logic_vector(15 downto 0);
	RFs_cu			: out	std_logic_vector(1 downto 0);
	RFwa_cu			: out	std_logic_vector(3 downto 0);
	RFr1a_cu			: out	std_logic_vector(3 downto 0);
	RFr2a_cu			: out	std_logic_vector(3 downto 0);
	RFwe_cu			: out	std_logic;
	RFr1e_cu			: out	std_logic;
	RFr2e_cu			: out	std_logic;
	jpen_cu			: out	std_logic;
	ALUs_cu			: out	std_logic_vector(2 downto 0);	
	Mre_cu			: out	std_logic;
	Mwe_cu			: out	std_logic;
	oe_cu				: out	std_logic;
	data_ready_cu	: in std_logic;
	RFr3a_cu			: out	std_logic_vector(3 downto 0);
	RFr3e_cu			: out	std_logic;
	RF3add_dp		: in std_logic_vector(15 downto 0)
);
end component;

component datapath is				
port(
	clock_dp		: in 	std_logic;
	rst_dp		: in 	std_logic;
	imm_data		: in 	std_logic_vector(15 downto 0);
	mem_data		: in 	std_logic_vector(15 downto 0);
	RFs_dp		: in 	std_logic_vector(1 downto 0);
	RFwa_dp		: in 	std_logic_vector(3 downto 0);
	RFr1a_dp		: in 	std_logic_vector(3 downto 0);
	RFr2a_dp		: in 	std_logic_vector(3 downto 0);
	RFwe_dp		: in 	std_logic;
	RFr1e_dp		: in 	std_logic;
	RFr2e_dp		: in 	std_logic;
	jp_en			: in 	std_logic;
	ALUs_dp		: in 	std_logic_vector(2 downto 0);
	ALUz_dp		: out std_logic;
	RF1out_dp	: out std_logic_vector(15 downto 0);
	ALUout_dp	: out std_logic_vector(15 downto 0);
	RFr3a_dp		: in 	std_logic_vector(3 downto 0);
	RFr3e_dp		: in 	std_logic;
	RF3add_dp	: out std_logic_vector(15 downto 0)
);
end component;

end MP_lib;



package body MP_lib is

	-- Procedure Body (optional)

end MP_lib;
