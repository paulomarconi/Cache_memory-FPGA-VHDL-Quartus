library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Deco4bit7segment is
	port (
		clock			: in std_logic;
		rst			: in std_logic;
		en				: in std_logic;
		in4bit		: in std_logic_vector(3 downto 0);  -- 4 bit input
		out7segment : out std_logic_vector(6 downto 0)  -- 7 bit decoded output.
	);
end Deco4bit7segment;

--'a' corresponds to MSB and 'g' corresponds to LSB of common anode 7segment
architecture Deco4bit7segment_arq of Deco4bit7segment is
begin
	process (clock, rst, en, in4bit)		
	begin	
		if rst='1' then
			out7segment <= "0000000";
		elsif (clock'event and clock='1') then
			if en = '1' then 	
				case  in4bit is
					when "0000" => out7segment <= "0000001";  -- '0'
					when "0001" => out7segment <= "1001111";  -- '1'
					when "0010" => out7segment <= "0010010";  -- '2'
					when "0011" => out7segment <= "0000110";  -- '3'
					when "0100" => out7segment <= "1001100";  -- '4'
					when "0101" => out7segment <= "0100100";  -- '5'
					when "0110" => out7segment <= "0100000";  -- '6'
					when "0111" => out7segment <= "0001111";  -- '7'
					when "1000" => out7segment <= "0000000";  -- '8'
					when "1001" => out7segment <= "0000100";  -- '9'
					when "1010" => out7segment <= "0001000";  -- 'A'
					when "1011" => out7segment <= "0000000";  -- 'B'
					when "1100" => out7segment <= "0110001";  -- 'C'
					when "1101" => out7segment <= "0000001";  -- 'D'
					when "1110" => out7segment <= "0110000";  -- 'E'
					when "1111" => out7segment <= "0111000";  -- 'F'
					when others => out7segment <= "0000000";	-- 'on'
				end case;
			end if;
		end if;	
	end process;
end Deco4bit7segment_arq;