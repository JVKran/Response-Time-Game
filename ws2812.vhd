library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY ws2812b IS
	--GENERIC(
	--	F_CLK 		 : natural := 50000000;			-- 50Mhz
	--	T0H   		 : real    := 0.00000040;		-- 400 ns
	--	T1H   		 : real    := 0.00000080;		-- 800 ns
	--	T0L   		 : real    := 0.00000085;		-- 850 ns
	--	T1L   		 : real    := 0.00000045;		-- 450 ns
	--	RES   		 : real    := 0.00005000		-- Above 50 us
	--);
	GENERIC(
		F_CLK 		 : natural := 5;			-- 50Mhz
		T0H   		 : real    := 0.40;			-- 400 ns
		T1H   		 : real    := 0.80;			-- 800 ns
		T0L   		 : real    := 0.85;			-- 850 ns
		T1L   		 : real    := 0.45;			-- 450 ns
		RES   		 : real    := 1.0				-- Above 50 us
	);
	PORT(
		CLK, RST, FLSH 	 : IN STD_LOGIC;			-- Clock, Reset & Flush
		D_OUT	 	 : OUT STD_LOGIC;			-- Data out
		RED, GREEN, BLUE : IN STD_LOGIC_VECTOR(7 DOWNTO 0)	-- Red, Green & Blue inputs
	);
END ENTITY ws2812b;

ARCHITECTURE driver OF ws2812b IS
	-- Convert timings to cycles.
	constant CYC_T0H : natural := natural(T0H / (real(1) / real(f_clk)));
	constant CYC_T1H : natural := natural(T1H / (real(1) / real(f_clk)));
	constant CYC_T0L : natural := natural(T0L / (real(1) / real(f_clk)));
	constant CYC_T1L : natural := natural(T1L / (real(1) / real(f_clk)));
	constant CYC_RES : natural := natural(RES / (real(1) / real(f_clk)));

	-- States of Finite State Machine (FSM); IDLE, Prepare and Write High and Low and Reset.
	type state_t is (IDLE, PREP_H, WRITE_H, PREP_L, WRITE_L, RESET);
	SIGNAL state : state_t := IDLE;

	-- Signals for transmission.
	SIGNAL bit_idx 	: INTEGER RANGE 23 DOWNTO 0 := 23;		-- Bit index in rgb values.
	SIGNAL grb      : STD_LOGIC_VECTOR(23 DOWNTO 0);		-- Vector containing green, red and blue byts.
	SIGNAL counter  : unsigned(15 DOWNTO 0);			-- Maintaining of timings.

BEGIN
	PROCESS(CLK, FLSH, RST) IS
	BEGIN IF RISING_EDGE(CLK) THEN			-- Begin if rising edge on clock.
		CASE state IS
			WHEN IDLE =>
				D_OUT <= '0';
				IF FLSH = '1' THEN
					state 	<= PREP_H;
					grb 	<= GREEN & RED & BLUE;
					bit_idx <= 23;
				END IF;
			WHEN PREP_H =>
				IF grb(bit_idx) = '1' THEN
					counter <= TO_UNSIGNED(CYC_T1H, counter'length);
				ELSE
					counter <= TO_UNSIGNED(CYC_T0H, counter'length);
				END IF;
				state <= WRITE_H;
			WHEN WRITE_H =>
				D_OUT <= '1';
				counter <= counter - 1;
				IF counter = 0 THEN
					state <= PREP_L;
				END IF;
			WHEN PREP_L =>
				IF grb(bit_idx) = '1' THEN
					counter <= TO_UNSIGNED(CYC_T1L, counter'length);
				ELSE
					counter <= TO_UNSIGNED(CYC_T0L, counter'length);
				END IF;
				state <= WRITE_L;
			WHEN WRITE_L =>
				D_OUT <= '0';
				counter <= counter - 1;
				IF counter = 0 AND bit_idx = 0 THEN
					state <= IDLE;
				ELSIF counter = 0 THEN
					bit_idx <= bit_idx - 1;
					state <= PREP_H;
				END IF;
			WHEN OTHERS => null;
		END CASE;
	END IF; END PROCESS;
END ARCHITECTURE driver;
