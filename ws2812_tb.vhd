library work;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ws2812b_tb IS
END ws2812b_tb;

ARCHITECTURE testbench OF ws2812b_tb IS
COMPONENT ws2812b IS
	GENERIC(		 -- For testbenches
		LED_AMT		 : integer := 24;			-- 24 Leds on ring
		F_CLK 		 : natural := 5;			-- 50Mhz
		T0H   		 : real    := 0.40;			-- 400 ns
		T1H   		 : real    := 0.80;			-- 800 ns
		T0L   		 : real    := 0.85;			-- 850 ns
		T1L   		 : real    := 0.45;			-- 450 ns
		RES   		 : real    := 1.0			-- Above 50 us
	);
	PORT(
		CLK, UPD, FLSH 	 : IN STD_LOGIC;			-- Clock, Update & Flush
		D_OUT	 	 : OUT STD_LOGIC;			-- Data out
		IDX		 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- Index of led to update; optional todo, make dynamic.
		RED, GREEN, BLUE : IN STD_LOGIC_VECTOR(7 DOWNTO 0)	-- Red, Green & Blue inputs
	);
END COMPONENT;

SIGNAL CLK_tb, FLSH_tb, UPD_tb	 : STD_LOGIC;
SIGNAL IDX_tb			 : STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL D_OUT_tb			 : STD_LOGIC;
SIGNAL RED_tb, GREEN_tb, BLUE_tb : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN
	led: ws2812b PORT MAP (
		CLK 	=> CLK_tb,
		UPD 	=> UPD_tb,
		FLSH 	=> FLSH_tb,
		D_OUT 	=> D_OUT_tb,
		IDX 	=> IDX_tb,
		RED 	=> RED_tb,
		GREEN 	=> GREEN_tb,
		BLUE 	=> BLUE_tb
	);

	PROCESS BEGIN
		--ASSERT F_CLK < 30 REPORT "Please select generics for testbench!" severity warning;
		CLK_tb   <= '0';

		-- Use identifying bit patterns for debug purposes.
		GREEN_tb <= "10101010";
		BLUE_tb  <= "00001111";
		RED_tb   <= "11110000";

		-- Set above color to led at index 2.
		IDX_tb	 <= "00000";
		FLSH_tb  <= '0';
		UPD_tb   <= '1';

		FOR cycle IN 0 TO 6000 LOOP
			WAIT FOR 1 ps;
			-- Toggle clock.
			CLK_tb <= not CLK_tb;

			-- Flush changes after 2 cycles.
			IF cycle = 2 THEN
				UPD_tb   <= '0';
				FLSH_tb  <= '1';
			END IF;

			-- Prevent repeated flushes.
			IF cycle = 4 THEN
				FLSH_tb  <= '0';
			END IF;
		END LOOP;
	WAIT;
	END PROCESS;
END ARCHITECTURE;
