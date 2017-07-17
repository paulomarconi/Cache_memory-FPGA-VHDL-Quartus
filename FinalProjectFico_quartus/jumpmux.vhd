library ieee;
use ieee.std_logic_1164.all;
use work.MP_lib.all;

entity jumpmux is
port( 	
		I0		: in std_logic_vector(15 downto 0);
		I1		: in std_logic_vector(15 downto 0);	  
		Sel	: in std_logic;
		Output: out std_logic_vector(15 downto 0)
	);
end jumpmux;

architecture behv of jumpmux is

begin
	process(I0, I1, Sel)
    begin
        case Sel is
            when '0' =>	Output <= I0;
            when '1' =>   Output <= I1;
				when others => Output <= x"FFFF";
        end case;
    end process;
end behv;

