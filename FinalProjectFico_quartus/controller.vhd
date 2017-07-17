----------------------------------------------------------------------------
-- Controller (control logic plus state register)
-- VHDL FSM modeling
-- controller.vhd
----------------------------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
use work.MP_lib.all;

entity controller is
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
end controller;

architecture fsm of controller is

  type state_type is (S0,Sdly,S1,S1a,S1b,S2,S3,S3a,S3b,S3c,S4,S4a,S4b,S4c,S5,S5a,S5b,S5c,
			S6,S6a,S7,S7a,S7b,S8,S8a,S8b,S9,S9a,S9b,S10,S11,S11a,S11b,S11c,S11d,S12,S12a,S12b,
			S13,S13a,S13b,S13c,S14,S14a,S14b,S14c,S15,S15a,S15b,S16,S16a,S16b,S16c,
			S17,S17a,S17b,S17c,S17d,S17e);
  signal state: state_type;
  signal delaystate: state_type; -- auxiliar state
  constant memdelay: integer := 8;
  constant outdelay: integer := 50000000; -- 50000000 = 1sec for implementation, 14 for simulation
  signal usedelay: boolean := false; 		-- false for cache memory, true for memory_slow 
  
begin
	process(clock, rst, IR_word)
		variable OPCODE: std_logic_vector(3 downto 0);
		variable maccesdelay: integer;
		begin
		if rst='1' then	-- Reset State		   
			Ms_ctrl <= "10";
			PCclr_ctrl 	<= '1';	  	
			PCinc_ctrl 	<= '0';
			IRld_ctrl 	<= '0';
			RFs_ctrl 	<= "00";		
			Rfwe_ctrl 	<= '0';
			Mre_ctrl 	<= '0';
			Mwe_ctrl 	<= '0';					
			jmpen_ctrl 	<= '0';		
			oe_ctrl 		<= '0';
			jmux_ctrl	<= '0';
			state <= S0;
		elsif (clock'event and clock='1') then
			case state is 
				when S0 =>	-- Reset State	
					PCclr_ctrl <= '0';	
					state <= S1;	
		-------------------------------------------------------------------------------------------
				when Sdly => -- Delay State	
					maccesdelay := maccesdelay-1;
					if maccesdelay = 0 then 
						state <= delaystate;
					else state <= Sdly ;
					end if;
		-------------------------------------------------------------------------------------------			
				when S1 =>	-- Fetch Instruction
					PCinc_ctrl 	<= '0';	
					IRld_ctrl  	<= '1'; 
					Mre_ctrl   	<= '1';  
					RFwe_ctrl  	<= '0'; 
					RFr1e_ctrl 	<= '0'; 
					RFr2e_ctrl 	<= '0'; 
					Ms_ctrl 		<= "10";
					Mwe_ctrl 	<= '0';
					jmpen_ctrl 	<= '0';
					oe_ctrl 		<= '0';
					jmux_ctrl	<= '0';
					state <= S1a;
					if usedelay = false then 
						state <= S1a;
					else 
						maccesdelay := memdelay;
						delaystate <= S1a;
						state <= Sdly;
					end if;
				when S1a => 	
					  state <= S1b;		--One memory access delay	
				when S1b => 
					if data_ready = '1' then
					  Mre_ctrl <= '0';
					  IRld_ctrl <= '0';
					  PCinc_ctrl <= '1';
					  state <= S2;			-- Fetch end ...
					elsif data_ready = '0' then
						maccesdelay := memdelay;
						delaystate <= S1b;
						state <= Sdly;
					end if;
		-------------------------------------------------------------------------------------------	  				
				when S2 =>	
					PCinc_ctrl <= '0';
					OPCODE := IR_word(15 downto 12);
					case OPCODE is
						when mov1 	=> state <= S3;
						when mov2 	=> state <= S4;
						when mov3 	=> state <= S5;
						when mov4 	=> state <= S6;
						when add		=> state <= S7;
						when subt 	=>	state <= S8;
						when jz 		=>	state <= S9;
						when halt 	=>	state <= S10; 
						when readm 	=> state <= S11;
						when mult  	=> state <= S12;
						when mov5  	=> state <= S13;
						when jne 	=> state <= S14;
						when inc 	=> state <= S15;
						when mov6 	=> state <= S16;
						when outRF  => state <= S17;
						when others	=>	state <= S1;
					end case;
		-------------------------------------------------------------------------------------------					
				when S3 =>	-- RF[rn] <- mem[direct]
					RFwa_ctrl <= IR_word(11 downto 8);	
					RFs_ctrl <= "01";  
					Ms_ctrl <= "01";
					Mre_ctrl <= '1';
					Mwe_ctrl <= '0';		  
					if usedelay = false then 
						state <= S3a;
					else 
						maccesdelay := memdelay;
						delaystate <= S3a;
						state <= Sdly;
					end if;
				when S3a => 
					state <= S3b;
				when S3b =>
					if data_ready = '1' then
						RFwe_ctrl <= '1'; 
						Mre_ctrl <= '0'; 
						state <= S3c;
					elsif data_ready = '0' then
						maccesdelay := memdelay;
						delaystate <= S3b;
						state <= Sdly;
					end if;
				when S3c => 	
					RFwe_ctrl <= '0';
					state <= S1;
		-------------------------------------------------------------------------------------------	    
				when S4 =>	-- mem[direct] <- RF[rn]			
					RFr1a_ctrl <= IR_word(11 downto 8);	
					RFr1e_ctrl <= '1'; 
					Ms_ctrl <= "01";
					ALUs_ctrl <= "000";	  
					IRld_ctrl <= '0';
					state <= S4a;			-- read value from RF
				when S4a =>   
					Mre_ctrl <= '0';
					Mwe_ctrl <= '1';		-- write into memory				
					if usedelay = false then 
						state <= S4b;
					else 
						maccesdelay := memdelay;
						delaystate <= S4b;
						state <= Sdly;
					end if;
				when S4b => 
					state <= S4c;			-- read value from RF
				when S4c =>
					if data_ready = '1' then
						Ms_ctrl <= "10";				  
						Mwe_ctrl <= '0';
						state <= S1;
					elsif data_ready = '0' then
						maccesdelay := memdelay;
						delaystate <= S4c;
						state <= Sdly;
					end if;
		-------------------------------------------------------------------------------------------		
				when S5 =>	-- mem[RF[rn]] <- RF[rm]
					RFr1a_ctrl <= IR_word(11 downto 8);	
					RFr1e_ctrl <= '1'; 
					Ms_ctrl <= "00";
					ALUs_ctrl <= "001";
					RFr2a_ctrl <= IR_word(7 downto 4); 
					RFr2e_ctrl <= '1'; -- set addr.& data
					state <= S5a;
				when S5a =>   
					Mre_ctrl <= '0';			
					Mwe_ctrl <= '1'; -- write into memory
					if usedelay = false then 
						state <= S5b;
					else 
						maccesdelay := memdelay;
						delaystate <= S5b;
						state <= Sdly;
					end if;			
				when S5b => 	
					state <= S5c;
				when S5c => 
					if data_ready = '1' then
						Ms_ctrl <= "10";-- return
						Mwe_ctrl <= '0';
						state <= S1;
					elsif data_ready = '0' then
						maccesdelay := memdelay;
						delaystate <= S5c;
						state <= Sdly;
					end if;
		-------------------------------------------------------------------------------------------							
				when S6 =>	-- RF[rn] <- imm.
					RFwa_ctrl <= IR_word(11 downto 8);	
					RFwe_ctrl <= '1'; 
					RFs_ctrl <= "10";
					IRld_ctrl <= '0';
					state <= S6a;
				when S6a =>   state <= S1;
		-------------------------------------------------------------------------------------------								    
				when S7 =>	-- RF[rn] <- RF[rn] + RF[rm]
					RFr1a_ctrl <= IR_word(11 downto 8);	
					RFr1e_ctrl <= '1'; 
					RFr2e_ctrl <= '1'; 
					RFr2a_ctrl <= IR_word(7 downto 4);
					ALUs_ctrl <= "010";
					state <= S7a;
				when S7a =>   
					RFr1e_ctrl <= '0';
					RFr2e_ctrl <= '0';
					RFs_ctrl <= "00";
					RFwa_ctrl <= IR_word(11 downto 8);
					RFwe_ctrl <= '1';
					state <= S7b;
				when S7b =>   
					state <= S1;
		-------------------------------------------------------------------------------------------												
				when S8 =>	-- RF[rn] <- RF[rn] - RF[rm]
					RFr1a_ctrl <= IR_word(11 downto 8);	
					RFr1e_ctrl <= '1'; 
					RFr2a_ctrl <= IR_word(7 downto 4);
					RFr2e_ctrl <= '1';  
					ALUs_ctrl <= "011";
					state <= S8a;
				when S8a =>   
					RFr1e_ctrl <= '0';
					RFr2e_ctrl <= '0';
					RFs_ctrl <= "00";
					RFwa_ctrl <= IR_word(11 downto 8);
					RFwe_ctrl <= '1';
					state <= S8b;
				when S8b =>  
					state <= S1;
		-------------------------------------------------------------------------------------------												
				when S12 =>	-- RF[rn] <- RF[rn] * RF[rm]
					RFr1a_ctrl <= IR_word(11 downto 8);	
					RFr1e_ctrl <= '1'; 
					RFr2a_ctrl <= IR_word(7 downto 4);
					RFr2e_ctrl <= '1';  
					ALUs_ctrl <= "101";
					state <= S12a;
				when S12a =>   
					RFr1e_ctrl <= '0';
					RFr2e_ctrl <= '0';
					RFs_ctrl <= "00";
					RFwa_ctrl <= IR_word(11 downto 8);
					RFwe_ctrl <= '1';
					state <= S12b;
				when S12b =>  
					state <= S1;			
		-------------------------------------------------------------------------------------------									
				when S9 =>	-- jz if RF[rn] = 0
					jmpen_ctrl <= '1';
					RFr1a_ctrl <= IR_word(11 downto 8);	
					RFr1e_ctrl <= '1'; 
					ALUs_ctrl <= "000";
					state <= S9a;
				when S9a =>   
					state <= S9b;
				when S9b =>   
					jmpen_ctrl <= '0';
					state <= S1;
		-------------------------------------------------------------------------------------------							
				when S10 =>	-- halt
					state <= S10; 
		-------------------------------------------------------------------------------------------									
				when S11 =>  -- output <- M[xx] 
					Ms_ctrl <= "01";
					Mre_ctrl <= '1'; -- read memory
					Mwe_ctrl <= '0';		  
					if usedelay = false then 
						state <= S11a;
					else 
						maccesdelay := memdelay;
						delaystate <= S11a;
						state <= Sdly;
					end if;			
				when S11a => 					
					state <= S11b;
				when S11b =>
					if data_ready = '1' then
						Ms_ctrl <= "10";
						oe_ctrl <= '1'; 
						Mre_ctrl <= '0';
						state <= S11c;
					elsif data_ready = '0' then
						maccesdelay := memdelay;
						delaystate <= S11b;
						state <= Sdly;
					end if;
				when S11c =>
						maccesdelay:=outdelay;
						delaystate <= S11d;
						state <= Sdly;
				when S11d => 
					state <= S1;
		-------------------------------------------------------------------------------------------							
				when S17 => -- output <- mem[RF[rn]]   
					RFr1a_ctrl <= IR_word(11 downto 8);	
					RFr1e_ctrl <= '1';  
					Ms_ctrl <= "00"; -- selecting content of RFr1 for address memory					
					state <= S17a;				
				when S17a => 
					Mre_ctrl <= '1'; -- read memory
					Mwe_ctrl <= '0';
					if usedelay = false then 
						state <= S17b;
					else 
						maccesdelay := memdelay;
						delaystate <= S17b;
						state <= Sdly;
					end if;
				when S17b =>					
					state <= S17c;
				when S17c =>
					if data_ready = '1' then
						oe_ctrl <= '1';
						Ms_ctrl <= "10"; -- return				
						Mre_ctrl <= '0';
						state <= S17d;
					elsif data_ready = '0' then
						maccesdelay:=memdelay;
						delaystate <= S17c;
						state <= Sdly;
					end if;
				when S17d =>
						maccesdelay:=outdelay;
						delaystate <= S17e;
						state <= Sdly;
				when S17e => 
					state <= S1;
		-------------------------------------------------------------------------------------------									
				when S14 =>  -- jne, RF[rn] ~= RF[rm] : PC[RF[ro]] 
					RFr1a_ctrl <= IR_word(11 downto 8);	
					RFr1e_ctrl <= '1'; 
					RFr2a_ctrl <= IR_word(7 downto 4);	
					RFr2e_ctrl <= '1'; 					
					jmpen_ctrl <= '1';
					state <= S14a;
				when S14a =>   
					RFr3a_ctrl <= IR_word(3 downto 0);	
					RFr3e_ctrl <= '1'; 
					jmux_ctrl	<= '1';
					state <= S14b;
				when S14b =>   
					state <= S14c;
				when S14c =>   
					jmpen_ctrl <= '0';
					jmux_ctrl	<= '0';
					state <= S1;
		-------------------------------------------------------------------------------------------	
				when S15 =>	-- inc, RF[rn] <- RF[rn] + 1
					RFr1a_ctrl <= IR_word(11 downto 8);	
					RFr1e_ctrl <= '1'; 
					ALUs_ctrl <= "100";
					state <= S15a;
				when S15a =>   
					RFr1e_ctrl <= '0';
					RFr2e_ctrl <= '0';
					RFs_ctrl <= "00";
					RFwa_ctrl <= IR_word(11 downto 8);
					RFwe_ctrl <= '1';
					state <= S15b;
				when S15b =>  
					state <= S1;
		-------------------------------------------------------------------------------------------									
				when S13 =>	-- RF[rm] <- mem[RF[rn]]  		 			
					RFr1a_ctrl <= IR_word(11 downto 8);	
					RFr1e_ctrl <= '1';  
					Ms_ctrl <= "00"; -- fetching content of RF[rn] for address memory			
					state <= S13a;
				when S13a =>	
					Mre_ctrl <= '1';			
					Mwe_ctrl <= '0';
					RFwa_ctrl <= IR_word(7 downto 4); -- RF[rm]
					RFwe_ctrl <= '1';
					RFs_ctrl <= "01"; -- save mem_data
					if usedelay = false then 
						state <= S13b;
					else 
						maccesdelay := memdelay;
						delaystate <= S13b;
						state <= Sdly;
					end if;										
				when S13b => 	
					state <= S13c;
				when S13c => 	
					if data_ready = '1' then
						Ms_ctrl <= "10";-- return				
						state <= S1;
					elsif data_ready = '0' then
						maccesdelay := memdelay;
						delaystate <= S13c;
						state <= Sdly;
					end if;
		-------------------------------------------------------------------------------------------	
				when S16 =>	-- RF[rn] <- RF[rm] 							 
					RFr2a_ctrl <= IR_word(7 downto 4);
					RFr2e_ctrl <= '1';
					ALUs_ctrl <= "001";
					state <= S16a;
				when S16a =>
					RFs_ctrl <= "00";				
					state <= S16b;
				when S16b =>
					RFwa_ctrl <= IR_word(11 downto 8);
					RFwe_ctrl <= '1';			
					state <= S16c;
				when S16c =>
					state <= S1;								
		-------------------------------------------------------------------------------------------		
				when others =>
			end case;
		end if;
	end process;
end fsm;