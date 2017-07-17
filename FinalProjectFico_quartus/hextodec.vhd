library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.MP_lib.all;

entity hextodec is
	port(
		clock	: in std_logic;
		rst	: in std_logic;
		en		: in std_logic;
		number: in std_logic_vector(15 downto 0);
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
		out7segment5 : out std_logic_vector(6 downto 0)   -- 7 bit decoded output	MSB	5
		
	);
end entity; 

architecture hextodec_arq of hextodec is
	type state_type is (S1,S2,S3,S4);
	signal state: state_type;
	signal aux_number	: unsigned(15 downto 0);
	signal quotient1,quotient2,quotient3,quotient4,quotient5	: unsigned(15 downto 0);	
	signal reminder1,reminder2,reminder3,reminder4,reminder5	: unsigned(15 downto 0);
	signal aux_fout0,aux_fout1,aux_fout2,aux_fout3,aux_fout4,aux_fout5 : std_logic_vector(3 downto 0);
	
begin
	process(clock, rst, en, number, aux_number)
	begin	
		if rst='1' then
			fout0 <= "0000";
			fout1 <= "0000";
			fout2 <= "0000";
			fout3 <= "0000";
			fout4 <= "0000";
			fout5 <= "0000";				
		elsif (clock'event and clock='1')  then				
			if en = '1' then
				aux_number <= unsigned(number);
				state <= S1;	
				case state is	
					when S1 =>					
						quotient1 <= aux_number/10;					
						reminder1 <= aux_number rem 10;
						aux_fout5 <= std_logic_vector(reminder1(3 downto 0));
						fout5 <= aux_fout5;						
						state <= S2;
					when S2 =>
						quotient2 <= quotient1/10;					
						reminder2 <= quotient1 rem 10;
						aux_fout4 <= std_logic_vector(reminder2(3 downto 0));	
						fout4 <= aux_fout4;					
						state <= S3;
					when S3 =>
						quotient3 <= quotient2/10;					
						reminder3 <= quotient2 rem 10;
						aux_fout3 <= std_logic_vector(reminder3(3 downto 0));
						fout3 <= aux_fout3;						
						state <= S4;
					when S4 =>
						quotient4 <= quotient3/10;					
						reminder4 <= quotient3 rem 10;
						aux_fout2 <= std_logic_vector(reminder4(3 downto 0));
						fout2 <= aux_fout2;
						aux_fout1 <= std_logic_vector(quotient4(3 downto 0));					
						fout1 <= aux_fout1;
						aux_fout0 <= "0000";
						fout0 <= aux_fout0;	
					when others =>
				end case;
			end if;	
		end if;			
	end process;
	

	display5: Deco4bit7segment port map(clock,rst,en,aux_fout5,out7segment5);
	display4: Deco4bit7segment port map(clock,rst,en,aux_fout4,out7segment4);
	display3: Deco4bit7segment port map(clock,rst,en,aux_fout3,out7segment3);
	display2: Deco4bit7segment port map(clock,rst,en,aux_fout2,out7segment2);
	display1: Deco4bit7segment port map(clock,rst,en,aux_fout1,out7segment1);
	display0: Deco4bit7segment port map(clock,rst,en,aux_fout0,out7segment0);		

	
end hextodec_arq;