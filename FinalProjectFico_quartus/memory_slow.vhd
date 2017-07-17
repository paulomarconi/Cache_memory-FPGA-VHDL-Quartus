--------------------------------------------------------
-- SSimple Computer Architecture
--
-- memory 256*16
-- 8 bit address; 16 bit data
-- memory.vhd
--------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;   
USE ieee.numeric_std.all;
use work.MP_lib.all;

entity memory_slow is
generic(
		data_width	: natural := 16;
		block_size 	: natural := 2; -- word = 2 bits
		line_size 	: natural := 3; -- line = 3 bits
		tag_size 	: natural := 6  -- tag  = 7 bits
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
end memory_slow;

architecture behv of memory_slow is
type state_type is (Sinit,Sdly,Sread_delayed,Swait);
subtype data is std_logic_vector((data_width*(2**block_size))-1 downto 0);
type ram_type is array (0 to 2**(line_size+tag_size)-1) of data;
signal tmp_ram: ram_type;

begin
	process(clock, rst, SM_rw_enable, old_address, new_address, old_data)
	begin				-- nxn matrix multiplication	 
		if rst='1' then		
			tmp_ram <= (						
						-- Matrix multiplication A*B=C
						4 => x"3064" & x"3B64" & x"31C8" & x"3CC8",
						-- 16: R0  <- #x=100	:pA	
						-- 17: R11 <- #x=100		
						-- 18: R1  <- #x=200	:pB
						-- 19: R12 <- #x=200
						5 => x"C210" & x"4200" & x"3300" & x"3400",						
						-- 20: R2 <- R1		:#200	  
						-- 21: R2 <- R2+R0	:#200+100=300	:pC						
						-- 22: R3 <- #0		:i=0
						-- 23: R4 <- #0		:j=0						
						6 => x"3500" & x"360A" & x"3700" & x"3800",
						-- 24: R5 <- #0		:k=0
						-- 25: R6 <- #10		:n=10, column number		
						-- 26: R7 <- #0		:m=0
						-- 27: R8 <- #0		:p=0						
						7 => x"3F1D" & x"9090" & x"91A0" & x"89A0",
						-- 28: R15 <- #29   	:jp (#alpha)						
						-- 29: R9  <- M[R0] 	:a												
						-- 30: R10 <- M[R1] 	:b												
						-- 31: R9 <- R9*R10 	:a=a*b										
						8 => x"4890" & x"B000" & x"4160" & x"B300",
						-- 32: R8 <- R8+R9  	:p=p+a										
						-- 33: R0 <- R0+1  	:pA=pA+1									
						-- 34: R1 <- R1+R6 	:pB=pB+n											
						-- 35: R3 <- R3+1  	:i=i+1											
						9 => x"A63F" & x"2280" & x"B200" & x"3800",
						-- 36: R6~=R3:PC<-[R15]  goto([R15]) if R6~=R3	:n~=i									
						-- 37: M[R2] <- R8	:M[pC]=p, store final product						
						-- 38: R2 <- R2+1		:pC=pC+1											
						-- 39: R8 <- #0		:i=0												
						10 => x"3300" & x"C0B0" & x"C1C0" & x"B400",
						-- 40: R3 <- #0		:p=0											
						-- 41: R0 <- R11		:Restore init pos of pA					
						-- 42: R1 <- R12		:Restore init pos of pB						
						-- 43: R4 <- R4+1		:j=j+1											
						11 => x"4140" & x"4070" & x"A64F" & x"3400",
						-- 44: R1 <- R1+R4	:pB=pB+j												
						-- 45: R0 <- R0+R7	:pA=pA+m												
						-- 46: R6~=R4:PC<-[R15]  goto([R15]) if R6~=R4	:n~=j						
						-- 47: R4 <- #0		:j=0
						12 => x"C0B0" & x"C1C0" & x"B500" & x"4760",
						-- 48: R0 <- R11		:Restore init pos of pA						
						-- 49: R1 <- R12		:Restore init pos of pB
						-- 50: R5 <- R5+1		:k=k+1, inc row counter
						-- 51: R7 <- R7+R6	:m=m+n
						13 => x"4140" & x"4070" & x"A65F" & x"3200",
						-- 52: R1 <- R1+R4	:pB=pB+j						
						-- 53: R0 <- R0+R7	:pA=pA+m						
						-- 54: R6~=R5:PC<-[R15]  goto([R15]) if R6~=R5	:n~=k						
						-- 55: R2 <- #0			:i=0
						
						-- Output matrix C
						14 => x"3364" & x"343D" & x"3564" & x"30C8",												
						-- 56: R3 <- #100			:n=100, total matrix elements
						-- 57: R4 <- #61(jump position)
						-- 58: R5 <- #100	
						-- 59: R0 <- #200 				
						15 => x"4050" & x"D000" & x"B000" & x"B200",						
						-- 60: R0 <- R0+R5		:#300	pA=300
						-- 61: output<- M[R0]
						-- 62: R0 <- R0+1			:pA=pA+1
						-- 63: R2 <- R2+1			:i=i+1
						16 => x"A234" & x"F000" & x"0000" & x"0000",						
						-- 64: R2~=R3:PC<-[R4]  goto([R4]) if R2~=R3
						-- 65: halt			
									

						others => x"0000000000000000");
		else
			if (clock'event and clock = '1') then
				if (SM_rw_enable = '1') then
					tmp_ram(conv_integer(old_address)) <= old_data;
					new_data <= tmp_ram(conv_integer(new_address));
				end if;
			end if;
		end if;
	end process;
end behv;
