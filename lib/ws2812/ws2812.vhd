LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- WS2812B User-Guide
-- On assertion of 'UPD' the color of the currently selected LED 'IDX' is
-- set to the color present on the 'RED', 'GREEN' and 'BLUE' buses. This can
-- be done for as many leds as wanted. When one desires to flush the changes
-- to the led-strip/ring, all one has to do is assert the 'FLSH' line.
-- The leds can also be shifted left by asserting the 'SFT' bit and cleared
-- by asserting 'RST'. In both cases, the leds will only be updated after
-- asserting 'FLSH'.

ENTITY ws2812b IS
	GENERIC(		 											-- For FPGA
		LED_AMT		 : integer := 24;					-- 24 Leds on ring
		F_CLK 		 : natural := 50000000;			-- 50Mhz
		T0H   		 : real    := 0.00000040;		-- 400 ns
		T1H   		 : real    := 0.00000080;		-- 800 ns
		T0L   		 : real    := 0.00000085;		-- 850 ns
		T1L   		 : real    := 0.00000045;		-- 450 ns
		RES   		 : real    := 0.00005000		-- Above 50 us
	);
	PORT(
		CLK, UPD, FLSH, RST	: IN STD_LOGIC;							-- Clock, Update, Flush & Reset
		LSHFT, RSHFT			: IN STD_LOGIC;							-- Left & Right Shift
		D_OUT, RDY 				: OUT STD_LOGIC;							-- Data out & Ready
		IDX		 				: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- Index of led to update.
		RED, GREEN, BLUE 		: IN STD_LOGIC_VECTOR(7 DOWNTO 0)	-- Red, Green & Blue inputs
	);
END ENTITY ws2812b;

ARCHITECTURE driver OF ws2812b IS
	-- Convert timings to cycles.
	CONSTANT CYC_T0H : natural := natural(T0H / (real(1) / real(f_clk)));
	CONSTANT CYC_T1H : natural := natural(T1H / (real(1) / real(f_clk)));
	CONSTANT CYC_T0L : natural := natural(T0L / (real(1) / real(f_clk)));
	CONSTANT CYC_T1L : natural := natural(T1L / (real(1) / real(f_clk)));
	CONSTANT CYC_RES : natural := natural(RES / (real(1) / real(f_clk)));

	-- States of Finite State Machine (FSM); IDLE, Prepare and Write High and Low and Reset.
	TYPE state_t IS (IDLE, PREP_H, WRITE_H, PREP_L, WRITE_L, RESET);
	SIGNAL state : state_t := IDLE;

	-- Support for multi-color ring
	TYPE memory_t IS ARRAY (0 TO LED_AMT - 1) OF STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL memory : memory_t := (others=>(others=>'0'));

	-- Signals for transmission.
	SIGNAL bit_idx 	: INTEGER RANGE 23 DOWNTO 0 		:= 23;	-- Bit index in rgb values.
	SIGNAL led_idx	: INTEGER RANGE LED_AMT DOWNTO 0 	:= 0;		-- Index of lastly updated led.
	SIGNAL counter  : unsigned(15 DOWNTO 0);							-- Maintaining of timings.

BEGIN
	PROCESS(CLK, FLSH, UPD, RST) IS
	BEGIN IF RISING_EDGE(CLK) THEN
		CASE state IS
			WHEN IDLE =>
				D_OUT <= '0';
				RDY 	<= '1';
				
				-- Flush changes to leds.
				IF FLSH = '1' THEN
					state 	<= PREP_H;
					RDY 		<= '0';
					bit_idx 	<= 23;
					led_idx 	<= 0;
				END IF;
				
				IF RST = '1' THEN
					-- Turn off leds when RST is asserted.
					memory <= (others=>(others=>'0'));
				END IF;
				
				-- Update color in memory at selected index.
				IF UPD = '1' THEN
					memory(TO_INTEGER(UNSIGNED(IDX))) <= GREEN & RED & BLUE;
				END IF;
				
				-- Shift colors left by concatenating array and element.
				IF LSHFT = '1' THEN
					memory <= memory(1 to memory'high) & memory(0);
				ELSIF RSHFT = '1' THEN 
					memory <= memory(memory'high) & memory(0 to memory'high - 1);
				END IF;
				
			WHEN PREP_H =>
				-- Determine Logic-High duration.
				IF memory(led_idx)(bit_idx) = '1' THEN
					counter <= TO_UNSIGNED(CYC_T1H, counter'length);
				ELSE
					counter <= TO_UNSIGNED(CYC_T0H, counter'length);
				END IF;
				state <= WRITE_H;

			WHEN WRITE_H =>
				-- Logic-High
				D_OUT <= '1';
				counter <= counter - 1;
				IF counter = 0 THEN
					state <= PREP_L;
				END IF;

			WHEN PREP_L =>
				-- Determine Logic-Low duration.
				IF memory(led_idx)(bit_idx) = '1' THEN
					counter <= TO_UNSIGNED(CYC_T1L, counter'length);
				ELSE
					counter <= TO_UNSIGNED(CYC_T0L, counter'length);
				END IF;
				state <= WRITE_L;

			WHEN WRITE_L =>
				-- Logic Low and determine next state.
				D_OUT <= '0';
				counter <= counter - 1;
				
				IF counter = 0 AND bit_idx = 0 AND led_idx = LED_AMT - 1 THEN
					-- All bits of all leds have been sent; back to IDLE.
					state <= IDLE;
				ELSIF counter = 0 AND bit_idx > 0 THEN
					-- Not all bits of led at current index have been sent; next bit.
					bit_idx <= bit_idx - 1;
					state 	<= PREP_H;
				ELSIF counter = 0 THEN
					-- All bits of current led have been sent; next led.
					bit_idx <= 23;
					led_idx <= led_idx + 1;
					state 	<= PREP_H;
				END IF;
				
			WHEN OTHERS => null;
			
		END CASE;
	END IF; END PROCESS;
END ARCHITECTURE driver;
