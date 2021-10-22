LIBRARY ieee;
USE ieee.numeric_std.all; 
USE ieee.std_logic_1164.all;

ENTITY reaction IS
	GENERIC (
		MAX_DELAY						: INTEGER := 150_000_000;				-- Maximum delay in cycles; 3 seconds.
		DELAY_PER_LED					: INTEGER := 1_000_000;					-- Delay per extra led; 20 milliseconds.
		LED_AMT							: INTEGER := 24;							-- Amount of leds on ring.
		F_CLK								: INTEGER := 50_000_000					-- Clock frequency in Hz.
	);
	PORT(
		CLK_50, STRT_BTN, RESP_BTN	: IN STD_LOGIC;
		HLF_SW, DIR_SW					: IN STD_LOGIC;
		LED_0								: OUT STD_LOGIC;
		SSD_0, SSD_1, SSD_2, SSD_3	: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	);
END reaction;

ARCHITECTURE driver OF reaction IS

	-- Returns 1 if bit is asserted. 0 if otherwise.
	FUNCTION TO_INTEGER(s : STD_LOGIC) RETURN NATURAL IS
	BEGIN
		IF s = '1' THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	END FUNCTION;

	COMPONENT prng IS
		PORT ( 
			CLK, RST, EN	: IN STD_LOGIC;
       	NUM 				: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT ssd IS 
		PORT(
			INP				: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			EN					: IN STD_LOGIC;
			SEG				: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT ws2812b IS
		GENERIC(
			LED_AMT		 				 : INTEGER := LED_AMT					-- 24 Leds on ring
		);
		PORT(
			CLK, UPD, FLSH, RST	: IN STD_LOGIC;							-- Clock, Update, Flush & Reset
			D_OUT, RDY 				: OUT STD_LOGIC;							-- Data out & Ready
			LSHFT, RSHFT			: IN STD_LOGIC;							-- Left & Right Shift
			IDX		 				: IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- Index of led to update.
			RED, GREEN, BLUE 		: IN STD_LOGIC_VECTOR(7 DOWNTO 0)	-- Red, Green & Blue inputs
		);
	END COMPONENT;

	-- State machine
	TYPE state_t IS (IDLE, BTN_WAIT_1, DELAY, COUNTING, BTN_WAIT_2);
	SIGNAL state : state_t := IDLE;

	-- Random number generation
	SIGNAL rng_en		: STD_LOGIC := '0'; 
	SIGNAL rnd_delay	: STD_LOGIC_VECTOR (7 DOWNTO 0);

	-- Response time visualization
	SIGNAL ssd_en, led_upd, led_flsh					: STD_LOGIC := '0';
	SIGNAL led_rst, led_lsft, led_rsft, led_rdy	: STD_LOGIC := '0';
	SIGNAL thousands, hundreds, tens, ones			: STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL red, green, blue								: STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '0');
	SIGNAL led_idx											: STD_LOGIC_VECTOR(4 DOWNTO 0);

BEGIN

	-- Random number generation and realtime response visualization.
	rng	: prng PORT MAP (CLK => CLK_50, RST => '0', EN => rng_en, NUM => rnd_delay);
	leds	: ws2812b PORT MAP (CLK => CLK_50, UPD => led_upd, FLSH => led_flsh, RST => led_rst, RDY => led_rdy,
										LSHFT => led_lsft, RSHFT => led_rsft, D_OUT => LED_0, IDX => led_idx, RED => red, GREEN => green, BLUE => blue);

	-- Response time visualization.
	thousands_ssd	: ssd PORT MAP (INP => thousands, EN => ssd_en, SEG => SSD_3);
	hundreds_ssd	: ssd PORT MAP (INP => hundreds, EN => ssd_en, SEG => SSD_2);
	tens_ssd			: ssd PORT MAP (INP => tens, EN => ssd_en, SEG => SSD_1);
	ones_ssd			: ssd PORT MAP (INP => ones, EN => ssd_en, SEG => SSD_0);

PROCESS(CLK_50, RESP_BTN, STRT_BTN)

	-- Timekeeping variables
	VARIABLE tick, wait_ticks, resp_time 	: NATURAL RANGE 0 TO MAX_DELAY * 2 := 0;
	VARIABLE dir									: INTEGER RANGE 0 TO 1 := 0;
	VARIABLE high_score							: NATURAL RANGE 0 TO MAX_DELAY * 2 := MAX_DELAY * 2;

	BEGIN IF RISING_EDGE(CLK_50) THEN
		CASE state IS
			WHEN IDLE =>
				-- Dont't update, flush or reset leds and wait for Start Button.
				led_upd 	<= '0';
				led_flsh <= '0';
				led_rst 	<= '0';
				IF STRT_BTN = '0' THEN
					state <= BTN_WAIT_1;
				END IF;

			WHEN BTN_WAIT_1 =>
				-- Duration until button press determines cycles of Pseudo-Random Number Generator.
				rng_en <= '1';
				IF STRT_BTN = '1' THEN
					rng_en 	<= '0';
					tick 		:= 0;
					state 	<= DELAY;
				END IF;

			WHEN DELAY =>
				wait_ticks := TO_INTEGER(UNSIGNED(rnd_delay));
				tick := tick + 1;
				
				-- Random delay of range (MAX_DELAY * 2) +- MAX_DELAY
				IF tick = (MAX_DELAY * 2) - (MAX_DELAY / wait_ticks * wait_ticks) THEN
					IF DIR_SW = '1' THEN 
						led_idx 	<= STD_LOGIC_VECTOR(TO_UNSIGNED(0, led_idx'length));
						dir 		:= 1;
					ELSE
						led_idx  <= STD_LOGIC_VECTOR(TO_UNSIGNED(LED_AMT, led_idx'length));
						dir 		:= 0;
					END IF;
					tick 		 	:= 0;
					green   		<= STD_LOGIC_VECTOR(TO_UNSIGNED(255, green'length));
					red   		<= STD_LOGIC_VECTOR(TO_UNSIGNED(0, red'length));
					
					IF RESP_BTN = '1' THEN			-- Only continue if response button is not pressed.
						state 		<= COUNTING;
					END IF;
				END IF;

			WHEN COUNTING =>
				tick := tick + 1;
				
				IF tick = ((LED_AMT * DELAY_PER_LED) + DELAY_PER_LED) / (1 + TO_INTEGER(HLF_SW)) THEN
					-- Response timed-out; back to IDLE.
					led_rst 	<= '1';
					led_flsh <= '1';
					state 	<= IDLE;
				ELSIF RESP_BTN = '0' THEN
					-- Response button pressed.
					state 	<= BTN_WAIT_2;
					ssd_en 	<=  '1';
					resp_time := tick / (F_CLK / 1000);
					tick 		:= 0;
				END IF;
				
				IF tick mod (DELAY_PER_LED / (1 + TO_INTEGER(HLF_SW)))  = 0 THEN
					-- Increment lit up leds with 1.
					IF dir = 1 THEN
						led_idx   <= STD_LOGIC_VECTOR(UNSIGNED(led_idx) + 1);
					ELSE
						led_idx   <= STD_LOGIC_VECTOR(UNSIGNED(led_idx) - 1);
					END IF;
					
					red   	<= STD_LOGIC_VECTOR(UNSIGNED(red) + 10);
					green   	<= STD_LOGIC_VECTOR(UNSIGNED(green) - 10);
					led_upd  <= '1';
					led_flsh <= '1';
				ELSE
					led_upd  <= '0';
					led_flsh <= '0';
				END IF;

			WHEN BTN_WAIT_2 =>
				-- Clear possibly still asserted bits.
				led_upd 		<= '0';
				led_flsh 	<= '0';
				
				-- Show response time on SSD.
				ones 		 <=  STD_LOGIC_VECTOR(TO_UNSIGNED(resp_time mod 10, ones'length));
				tens 		 <=  STD_LOGIC_VECTOR(TO_UNSIGNED((resp_time / 10) mod 10, tens'length));
				hundreds  <=  STD_LOGIC_VECTOR(TO_UNSIGNED((resp_time / 100) mod 10, hundreds'length));
				thousands <=  STD_LOGIC_VECTOR(TO_UNSIGNED(resp_time / 1000, thousands'length));
				
				-- Shift visualized response time on ring.
				IF resp_time <= high_score THEN
					high_score 	:= resp_time;
					tick 		  	:= tick + 1;
					IF tick >= DELAY_PER_LED THEN
						-- Shift in the right direction.
						IF dir = 0 THEN
							led_lsft <= '1';
						ELSE
							led_rsft <= '1';
						END IF;
						led_flsh <= '1';
						tick 		:= 0;
					ELSE
						led_lsft <= '0';
						led_rsft <= '0';
						led_flsh <= '0';
					END IF;
				END IF;

				-- Go to IDLE when button released and led is ready for shutdown.
				IF RESP_BTN = '1' AND led_rdy = '1' THEN
					state 	<= IDLE;
					led_lsft <= '0';
					led_rsft <= '0';
					led_rst 	<= '1';
					led_flsh <= '1';
					ssd_en 	<=  '0';
				END IF;

			WHEN OTHERS =>
				tick := 0;
		END CASE;
	END IF; END PROCESS;
END driver;
