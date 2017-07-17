--------------------------------------------------------
-- Simple Computer Architecture

-- 11 bit address; 16 bit data
-- memory.vhd (cache memory + cache controller)
--------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;   
use work.MP_lib.all;

entity memory is
generic(
		data_width	: natural := 16;
		block_size 	: natural := 2; -- word = 2 bits
		line_size 	: natural := 3; -- line = 3 bits
		tag_size 	: natural := 6  -- tag = 6 bits
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
end memory;

architecture behv of memory is
-- Finite State Machine definitions
type state_type is (Sinit,Sdly,Sread_delayed,Swait);
-- Cache definition			
subtype data is std_logic_vector(data_width-1 downto 0);
subtype tag is std_logic_vector(tag_size-1 downto 0);
type ram_type is array (0 to (2**line_size)-1, 0 to (2**block_size)-1) of data;
type tag_type is array (0 to (2**line_size)-1) of tag;
-- Instances of cache memory
signal tmp_ram: ram_type;
signal cache_tag: tag_type;
-- Cache controller states when reading
signal state: state_type;
signal delaystate: state_type;
-- Cache controller states when writing
signal state_w: state_type;
signal delaystate_w: state_type;
-- Slow memory signals
signal SM_rw_enable: std_logic;			
signal new_address: std_logic_vector((line_size+tag_size)-1 downto 0);
signal old_address: std_logic_vector((line_size+tag_size)-1 downto 0);
signal new_data: std_logic_vector((data_width*(2**block_size))-1 downto 0);
signal old_data: std_logic_vector((data_width*(2**block_size))-1 downto 0);

constant memdelay: integer := 8;

begin
	
	process(clock, rst, Mwe, Mre, address, data_in, state)
	
	variable word_tmp: std_logic_vector((block_size)-1 downto 0);	
	variable line_tmp:std_logic_vector((line_size)-1 downto 0);
	variable tag_tmp: std_logic_vector((tag_size)-1 downto 0);
	variable maccesdelay: integer;
	 
	begin
		if rst='1' then				
--			------------------------------------------------
--			-- A&B nxn matrix generator
--			0 => x"3064" & x"31C8" & x"3200" & x"3364",
--			-- 0:	 R0 <- #100 	:pA = 100
--			--	1:	 R1 <- #200 	:pB = 200
--			-- 2:	 R2 <- #0		:i = 0
--			-- 3:  R3 <- #100		:n = 100, total matrix elements
--			1 => x"3400" & x"3501" & x"3602" & x"3708", 
--			-- 4:	 R4 <- #0		:x = 0
--			-- 5:	 R5 <- #1		:y = 1
--			-- 6:	 R6 <- #2		:p = 2
--			-- 7:	 R7 <- #8(jump position)
--			2 => x"2040" & x"2150" & x"4460" & x"4560",
--			-- 8:	 M[R0] <- R4 	:M[pA] = x
--			-- 9:	 M[R1] <- R5 	:M[pb] = y
--			-- 10: R4 <- R4 + R6	:x = x + p
--			-- 11: R5 <- R5 + R6	:y = y + p
--			3 => x"4060" & x"4160" & x"4260" & x"A237",
--			-- 12: R0 <- R0 + R6	:pA = pA + p
--			-- 13: R1 <- R1 + R6	:pB = pB + p
--			-- 14: R2 <- R2 + R6	:i = i + p
--			-- 15: R2~=R3:PC<-[R7]  goto([R7]) if R2~=R3		
--			
			------------------------------------------------
			-- A&B nxn matrix generator
			-- tag 0							-- line 0, words 0-3
			cache_tag(0) <= "000000";	tmp_ram(0,0) <= x"3064";tmp_ram(0,1) <= x"31C8";tmp_ram(0,2) <= x"3200";tmp_ram(0,3) <= x"3364";						
			-- tag 1							-- line 1, words 4-7
			cache_tag(1) <= "000000";	tmp_ram(1,0) <= x"3400";tmp_ram(1,1) <= x"3501";tmp_ram(1,2) <= x"3602";tmp_ram(1,3) <= x"3708";			
			-- tag 2							-- line 2, words 8-11
			cache_tag(2) <= "000000";	tmp_ram(2,0) <= x"2040";tmp_ram(2,1) <= x"2150";tmp_ram(2,2) <= x"4460";tmp_ram(2,3) <= x"4560";			
			-- tag 3							-- line 3, words 12-15
			cache_tag(3) <= "000000";	tmp_ram(3,0) <= x"4060";tmp_ram(3,1) <= x"4160";tmp_ram(3,2) <= x"4260";tmp_ram(3,3) <= x"A237";						
			-- tag 4							-- line 4, words 16-19
			cache_tag(4) <= "111111";			
			-- tag 5							-- line 5, words 20-23
			cache_tag(5) <= "111111";			
			-- tag 6							-- line 6, words 24-27
			cache_tag(6) <= "111111";			
			-- tag 7							-- line 7, words 28-31
			cache_tag(7) <= "111111";			
			
			data_out <= ZERO;
			state <= Sinit;
			state_W <= Sinit;
		elsif (clock'event and clock = '1') then
			word_tmp := address(block_size-1 downto 0);
			line_tmp := address((block_size+line_size)-1 downto block_size);
			tag_tmp := address((block_size+line_size+tag_size)-1 downto (block_size+line_size));
			
			-- Reading directly from Cache memory
			if (Mre ='1' and Mwe ='0' and tag_tmp = cache_tag(conv_integer(line_tmp))) then
				data_ready <= '1';		
				data_out <= tmp_ram(conv_integer(line_tmp),conv_integer(word_tmp));
				
			-- Reading from slow memory
			elsif (Mre ='1' and Mwe ='0' and tag_tmp /= cache_tag(conv_integer(line_tmp))) then
			
				case state is
					when Sinit =>
						data_ready <= '0';
						SM_rw_enable <= '1';
						new_address((tag_size+line_size)-1 downto (line_size)) <= tag_tmp;
						new_address((line_size-1) downto 0) <= line_tmp;
						old_address((tag_size+line_size)-1 downto (line_size)) <= cache_tag(conv_integer(line_tmp));
						old_address((line_size-1) downto 0) <= line_tmp;
						old_data <= tmp_ram(conv_integer(line_tmp),0) & tmp_ram(conv_integer(line_tmp),1) & tmp_ram(conv_integer(line_tmp),2) & tmp_ram(conv_integer(line_tmp),3);
						maccesdelay:=memdelay;
						delaystate <= Sread_delayed;
						state <= Sdly;
					when Sdly =>								-- Delay State	
						maccesdelay := maccesdelay-1;
						if maccesdelay = 0 then 
							tmp_ram(conv_integer(line_tmp),0) <= new_data((data_width*(2**block_size))-1 downto (data_width*(2**block_size-1)));
							tmp_ram(conv_integer(line_tmp),1) <= new_data((data_width*(2**block_size-1))-1 downto (data_width*(2**block_size-2)));
							tmp_ram(conv_integer(line_tmp),2) <= new_data((data_width*(2**block_size-2))-1 downto (data_width*(2**block_size-3)));
							tmp_ram(conv_integer(line_tmp),3) <= new_data((data_width*(2**block_size-3))-1 downto 0);
							state <= delaystate;
						else 
							state <= Sdly ;
						end if;
					when Sread_delayed =>
						data_ready <= '1';
						SM_rw_enable <= '0';
						data_out <= tmp_ram(conv_integer(line_tmp),conv_integer(word_tmp));
						state <= Swait;
					when Swait =>
						cache_tag(conv_integer(line_tmp)) <= tag_tmp;
						state <= Sinit;
				end case;
				
			-- Writing into cache memory	
			elsif (Mwe ='1' and Mre = '0' and tag_tmp = cache_tag(conv_integer(line_tmp))) then
				data_ready <= '1';
				tmp_ram(conv_integer(line_tmp),conv_integer(word_tmp)) <= data_in;
			elsif (Mwe ='1' and Mre = '0' and tag_tmp /= cache_tag(conv_integer(line_tmp))) then
			
				case state_w is
					when Sinit =>
						data_ready <= '0';
						SM_rw_enable <= '1';
						new_address((tag_size+line_size)-1 downto (line_size)) <= tag_tmp;
						new_address((line_size-1) downto 0) <= line_tmp;
						old_address((tag_size+line_size)-1 downto (line_size)) <= cache_tag(conv_integer(line_tmp));
						old_address((line_size-1) downto 0) <= line_tmp;
						old_data <= tmp_ram(conv_integer(line_tmp),0) & tmp_ram(conv_integer(line_tmp),1) & tmp_ram(conv_integer(line_tmp),2) & tmp_ram(conv_integer(line_tmp),3);
						maccesdelay:=memdelay;
						delaystate_w <= Sread_delayed;
						state_w <= Sdly;
					when Sdly =>								-- Delay State	
						maccesdelay := maccesdelay-1;
						if maccesdelay = 0 then 
							tmp_ram(conv_integer(line_tmp),0) <= new_data((data_width*(2**block_size))-1 downto (data_width*(2**block_size-1)));
							tmp_ram(conv_integer(line_tmp),1) <= new_data((data_width*(2**block_size-1))-1 downto (data_width*(2**block_size-2)));
							tmp_ram(conv_integer(line_tmp),2) <= new_data((data_width*(2**block_size-2))-1 downto (data_width*(2**block_size-3)));
							tmp_ram(conv_integer(line_tmp),3) <= new_data((data_width*(2**block_size-3))-1 downto 0);
							state_w <= delaystate_w;
						else 
							state_w <= Sdly ;
						end if;
					when Sread_delayed =>
						data_ready <= '1';
						SM_rw_enable <= '0';
						tmp_ram(conv_integer(line_tmp),conv_integer(word_tmp)) <= data_in;
						state_w <= Swait;
					when Swait =>
						cache_tag(conv_integer(line_tmp)) <= tag_tmp;
						state_w <= Sinit;
				end case;
				
			else
				data_ready <= '0';
				
			end if;
		end if;
		D_word_tmp 	<= word_tmp;	
		D_line_tmp 	<= line_tmp;
		D_tag_tmp 	<= tag_tmp;
	end process;
	Unit: memory_slow port map(clock,rst,SM_rw_enable,old_address,new_address,old_data,new_data);
	D_SM_rw_enable <= SM_rw_enable;
	D_new_address	<= new_address;
	D_old_address	<= old_address;
	D_new_data		<= new_data;
	D_old_data		<= old_data;
	
end behv;



