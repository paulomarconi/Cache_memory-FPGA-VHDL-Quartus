-- Simple Microprocessor Design (ESD Book Chapter 3),
-- originally created by Weijun Zhang, Copyright 2001 
-- http://esd.cs.ucr.edu/labs/tutorial/

-- Modified as a:
-- "Simple Computer Architecture using direct mapped cache" 
-- University of New Brunswick, Universidad Mayor de San Andrés - UMSA
-- Course: ECE6733 - "Computer Architecture Performance +"
-- Prof: Eduardo Castillo Guerra


-- by: Paulo Loma Marconi 			prlomarconi(arroba)gmail.com 
-- 	 César Claros Olivares   	cesar.claros(arroba)outlook.com 
-- 	 Abel Claros Olivares		abel.claros(arroba)gmail.com
-- Project stored at: https://github.com/zurits/FinalProjectFico_EC67333


-- System composed of CPU, memory(cache), slow memory, simple memory,
-- output buffer and output to 7segment display 
-- Signals with the prefix "D_" are set for Debugging purpose only
-- 
-- SimpleCompArch.vhd
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;  
use ieee.numeric_std.all;			   
use work.MP_lib.all;

entity SimpleCompArch is
port( 
	sys_clk							: in std_logic;
	sys_rst							: in std_logic;
	sys_button						: in std_logic;
	sys_output						: out std_logic_vector(15 downto 0);
	
	fout0	: out std_logic_vector(3 downto 0);	-- LSB
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
	out7segment5 : out std_logic_vector(6 downto 0);  -- 7 bit decoded output	MSB	5
	
	-- Debug signals from CPU: output for simulation purpose only	
	D_rfout_bus						: out std_logic_vector(15 downto 0);  
	D_RFwa, D_RFr1a, D_RFr2a	: out std_logic_vector(3 downto 0);
	D_RFwe, D_RFr1e, D_RFr2e	: out std_logic;
	D_RFs								: out std_logic_vector(1 downto 0);
	D_ALUs							: out std_logic_vector(2 downto 0);
	D_PCld,D_jpz					: out std_logic;
	D_oe								: out std_logic;
	-- end debug variables	

	-- Debug signals from Memory: output for simulation purpose only	
	D_mdout_bus,D_mdin_bus		: out std_logic_vector(15 downto 0); 
	D_mem_addr						: out std_logic_vector(10 downto 0); 
	D_Mre,D_Mwe						: out std_logic; 
	D_data_ready					: out std_logic
	-- end debug variables	
);
end SimpleCompArch;

architecture rtl of SimpleCompArch is
	--Memory local variables												  							      (ORIGIN	-> DEST)
	signal mdout_bus					: std_logic_vector(15 downto 0);  -- Mem data output 		(MEM  	-> CTLU)
	signal mdin_bus					: std_logic_vector(15 downto 0);  -- Mem data bus input 	(CTRLER	-> Mem)
	signal mem_addr					: std_logic_vector(10 downto 0);  -- Const. operand addr.(CTRLER	-> MEM)
	signal Mre							: std_logic;							 -- Mem. read enable  	(CTRLER	-> Mem) 
	signal Mwe							: std_logic;							 -- Mem. write enable 	(CTRLER	-> Mem)
	signal data_ready					: std_logic;
	--System local variables
	signal oe							: std_logic;	
begin

Unit1: CPU port map (sys_clk,sys_rst,sys_button,mdout_bus,mdin_bus,mem_addr,Mre,Mwe,oe,
										D_rfout_bus,D_RFwa, D_RFr1a, D_RFr2a,D_RFwe, 			 	--Debug signals
										D_RFr1e,D_RFr2e,D_RFs,D_ALUs,D_PCld,D_jpz,data_ready);	--Debug signals
																					
Unit2: memory port map(sys_clk,sys_rst,Mre,Mwe,mem_addr,mdin_bus,mdout_bus,data_ready);  				-- cache memory
--Unit5: memory_simple port map(sys_clk,sys_rst,Mre,Mwe,mem_addr,mdin_bus,mdout_bus,data_ready);	-- simple memory	

Unit3: obuf port map(oe,mdout_bus,sys_output);
Unit4: hextodec port map(sys_clk,sys_rst,oe,mdout_bus,fout0,fout1,fout2,fout3,fout4,fout5,
									out7segment0,out7segment1,out7segment2,out7segment3,out7segment4,out7segment5);							

-- Debug signals: output to upper level for simulation purpose only
	D_mdout_bus <= mdout_bus;	
	D_mdin_bus <= mdin_bus;
	D_mem_addr <= mem_addr; 
	D_Mre <= Mre;
	D_Mwe <= Mwe;
	D_data_ready <= data_ready;
	D_oe <= oe;
-- end debug variables		
		
end rtl;