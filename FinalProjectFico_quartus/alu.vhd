
--------------------------------------------------------
-- Simple Microprocessor Design 
--
-- alu has functions of bypass, addition and subtraction
-- alu.vhd
--------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;  
use ieee.numeric_std.all;
use work.MP_lib.all;

entity alu is
port (	
		num_A		: in std_logic_vector(15 downto 0);
		num_B		: in std_logic_vector(15 downto 0);
		jpsign	: in std_logic;						 		-- JMP?	
		ALUs		: in std_logic_vector(2 downto 0);     -- OP selector
		ALUz		: out std_logic;                       -- Reached 0!   
		ALUout	: out std_logic_vector(15 downto 0)    -- final calc value
);
end alu;

architecture behv of alu is

signal alu_tmp: std_logic_vector(15 downto 0);
signal Z_tmp: std_logic;
--signal A_tmp: std_logic_vector(15 downto 0);
--signal B_tmp: std_logic_vector(15 downto 0);

begin

	process(num_A, num_B, ALUs)
	begin			
		case ALUs is
			when "000" => alu_tmp <= num_A;
			when "001" => alu_tmp <= num_B;
			when "010" => alu_tmp <= num_A + num_B;
			when "011" => alu_tmp <= num_A - num_B;
			when "100" => alu_tmp <= num_A + 1;
			when "101" => alu_tmp <= num_A(7 downto 0) * num_B(7 downto 0);	
							--A_tmp <= num_A;
							--B_tmp <= num_B;
		  when others => alu_tmp <= HIRES;
	    end case; 					  
	end process;
	
	process(jpsign, alu_tmp, num_A, num_B)
	begin
		if (jpsign = '1' and num_A /= num_B) then
			Z_tmp <= '1';
		elsif (jpsign = '1' and num_A = num_B) then
			Z_tmp <= '0';
--		elsif (jpsign = '1' and alu_tmp = ZERO) then
--			Z_tmp <= '1';
--		elsif (jpsign = '1' and alu_tmp /= ZERO) then
--			Z_tmp <= '0';
		else
			Z_tmp <= '0';
		end if;
	end process;					
	
	ALUout <= alu_tmp;
	ALUz <= Z_tmp;
end behv;




