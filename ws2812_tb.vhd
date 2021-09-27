library work;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ws2812b_tb IS
END ws2812b_tb;

ARCHITECTURE testbench OF ws2812b_tb IS
COMPONENT ws2812b IS
	PORT(
		CLK, RST, FLSH 	 : IN STD_LOGIC;			-- Clock, Reset & Flush
		D_OUT	 	 : OUT STD_LOGIC;			-- Data out
		RED, GREEN, BLUE : IN STD_LOGIC_VECTOR(7 DOWNTO 0)	-- Red, Green & Blue inputs
	);
END COMPONENT;

SIGNAL CLK_tb, RST_tb, FLSH_tb	 : STD_LOGIC;
SIGNAL D_OUT_tb			 : STD_LOGIC;
SIGNAL RED_tb, GREEN_tb, BLUE_tb : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN
	led: ws2812b PORT MAP (
		CLK 	=> CLK_tb,
		RST 	=> RST_tb,
		FLSH 	=> FLSH_tb,
		D_OUT 	=> D_OUT_tb,
		RED 	=> RED_tb,
		GREEN 	=> GREEN_tb,
		BLUE 	=> BLUE_tb
	);

	PROCESS BEGIN
		CLK_tb   <= '0';
		GREEN_tb <= "10101010";
		BLUE_tb  <= "00001111";
		RED_tb   <= "11110000";
		FLSH_tb  <= '1';
		FOR cycle IN 0 TO 6000 LOOP
			WAIT FOR 10 ns;
			CLK_tb <= not CLK_tb;
			IF cycle = 2 THEN
				FLSH_tb  <= '0';
			END IF;
		END LOOP;
	WAIT;
	END PROCESS;
END ARCHITECTURE;
