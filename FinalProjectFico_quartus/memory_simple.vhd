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
use work.MP_lib.all;

entity memory_simple is
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
end memory_simple;

architecture behv of memory_simple is			

type ram_type is array (0 to 511) of std_logic_vector(15 downto 0);
signal tmp_ram: ram_type;

begin
	process(clock, rst, Mre, address, data_in)
	begin				
		if rst='1' then
			tmp_ram <= (			
						------------------------------------------------
						-- A&B nxn matrix generator
						0 	=> x"3064",	-- R0 <- #100 		:pA = 100
						1 	=> x"31C8",	--	R1 <- #200 		:pB = 200
						2 	=> x"3200",	--	R2 <- #0			:i = 0
						3 	=> x"3364",	-- R3 <- #100		:n = 100, total matrix elements
						 
						4 	=> x"3400",	-- R4 <- #0			:x = 0
						5 	=> x"3501",	-- R5 <- #1			:y = 1
						6 	=> x"3602",	-- R6 <- #2			:p = 2
						7 	=> x"3708",	-- R7 <- #8(jump position)
						  
						8 	=> x"2040",	-- M[R0] <- R4 	:M[pA] = x
						9 	=> x"2150",	-- M[R1] <- R5 	:M[pb] = y
						10 => x"4460",	-- R4 <- R4 + R6	:x = x + p
						11 => x"4560",	-- R5 <- R5 + R6	:y = y + p
						
						12 => x"4060",	-- R0 <- R0 + R6	:pA = pA + p
						13 => x"4160",	-- R1 <- R1 + R6	:pB = pB + p
						14 => x"4260",	-- R2 <- R2 + R6	:i = i + p
						15 => x"A237",	-- R2~=R3:PC<-[R7]  goto([R7]) if R2~=R3		

						-- Matrix multiplication A*B=C
						16 => x"3064",	-- R0  <- #x=100	:pA	
						17 => x"3B64",	-- R11 <- #x=100		
						18 => x"31C8",	-- R1  <- #x=200	:pB
						19 => x"3CC8",	-- R12 <- #x=200
												 			
						20 => x"C210",	-- R2 <- R1			:#200	  
						21 => x"4200", -- R2 <- R2+R0		:#200+100=300	:pC						
						22 => x"3300",	-- R3 <- #0			:i=0
						23 => x"3400",	-- R4 <- #0			:j=0						
						 
						24 => x"3500",	-- R5 <- #0			:k=0
						25 => x"360A",	-- R6 <- #10		:n=10, column number		
						26 => x"3700",	-- R7 <- #0			:m=0
						27 => x"3800",	-- R8 <- #0			:p=0						
						 
						28 => x"3F1D",	-- R15 <- #29   	:jp (#alpha)						
						29 => x"9090",	-- R9  <- M[R0] 	:a												
						30 => x"91A0",	-- R10 <- M[R1] 	:b												
						31 => x"89A0",	-- R9 <- R9*R10 	:a=a*b										
						 
						32 => x"4890",	-- R8 <- R8+R9  	:p=p+a										
						33 => x"B000",	-- R0 <- R0+1  	:pA=pA+1									
						34 => x"4160",	-- R1 <- R1+R6 	:pB=pB+n											
						35 => x"B300",	-- R3 <- R3+1  	:i=i+1											
						 
						36 => x"A63F",	-- R6~=R3:PC<-[R15]  goto([R15]) if R6~=R3	:n~=i									
						37 => x"2280",	-- M[R2] <- R8		:M[pC]=p, store final product						
						38 => x"B200",	-- R2 <- R2+1		:pC=pC+1											
						39 => x"3800",	-- R8 <- #0			:i=0												
						 
						40 => x"3300",	-- R3 <- #0			:p=0											
						41 => x"C0B0",	-- R0 <- R11		:Restore init pos of pA					
						42 => x"C1C0",	-- R1 <- R12		:Restore init pos of pB						
						43 => x"B400",	-- R4 <- R4+1		:j=j+1											
						 
						44 => x"4140",	-- R1 <- R1+R4		:pB=pB+j												
						45 => x"4070",	-- R0 <- R0+R7		:pA=pA+m												
						46 => x"A64F",	-- R6~=R4:PC<-[R15]  goto([R15]) if R6~=R4	:n~=j						
						47 => x"3400",	-- R4 <- #0			:j=0
						 
						48 => x"C0B0",	-- R0 <- R11		:Restore init pos of pA						
						49 => x"C1C0",	-- R1 <- R12		:Restore init pos of pB
						50 => x"B500",	-- R5 <- R5+1		:k=k+1, inc row counter
						51 => x"4760",	-- R7 <- R7+R6		:m=m+n
						 
						52 => x"4140",	-- R1 <- R1+R4		:pB=pB+j						
						53 => x"4070",	-- R0 <- R0+R7		:pA=pA+m						
						54 => x"A65F",	-- R6~=R5:PC<-[R15]  goto([R15]) if R6~=R5	:n~=k						
						55 => x"3200",	-- R2 <- #0			:i=0
						
						-- Output matrix C						 
						56 => x"3364",	-- R3 <- #100		:n=100, total matrix elements
						57 => x"343D",	-- R4 <- #61(jump position)
						58 => x"3564",	-- R5 <- #100	
						59 => x"30C8",	-- R0 <- #200 				
						 			
						60 => x"4050",	-- R0 <- R0+R5		:#300	pA=300
						61 => x"D000",	-- output<- M[R0]
						62 => x"B000",	-- R0 <- R0+1		:pA=pA+1
						63 => x"B200",	-- R2 <- R2+1		:i=i+1
						 
						64	=> x"A234",	-- R2~=R3:PC<-[R4]  goto([R4]) if R2~=R3
						65 => x"F000",	-- halt																				
			
						others => x"0000");
		elsif (clock'event and clock = '1') then
			if (Mwe ='1' and Mre = '0') then	-- write in memory
				data_ready <= '1';
				tmp_ram(conv_integer(address)) <= data_in;
			elsif (Mre ='1' and Mwe ='0') then	-- read from memory
				data_ready <= '1';
				data_out <= tmp_ram(conv_integer(address));	
			else 
				data_ready <= '0';		
			end if;	
		end if;
	end process;
	
end behv;