LIBRARY ieee;
USE ieee.numeric_std.all; 
USE ieee.std_logic_1164.all;

ENTITY reaction IS
GENERIC (
	max_delay	: INTEGER := 150_000_000;
	delay_per_led	: INTEGER := 1_000_000;
	f_clk		: INTEGER := 50_000_000
);
PORT(
	CLK_50, STRT_BTN, RESP_BTN	: IN STD_LOGIC;
	LED_0				: OUT STD_LOGIC;
	SSD_0, SSD_1, SSD_2, SSD_3	: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
);
END reaction;

ARCHITECTURE driver OF reaction IS

	COMPONENT prng IS
		PORT ( 
			CLK, RST, EN 	: IN STD_LOGIC;
       			NUM 		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT ssd IS 
		PORT(
			INP		: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			EN		: IN STD_LOGIC;
			SEG		: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
		);
	END COMPONENT;
	
	COMPONENT ws2812b IS
		PORT(
			CLK, UPD, FLSH 	 : IN STD_LOGIC;			-- Clock, Update & Flush
			D_OUT	 	 : OUT STD_LOGIC;			-- Data out
			IDX		 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- Index of led to update; optional todo, scale on LED_AMT.
			RED, GREEN, BLUE : IN STD_LOGIC_VECTOR(7 DOWNTO 0)	-- Red, Green & Blue inputs
		);
	END COMPONENT;

	-- State machine
	TYPE state_t IS (IDLE, BTN_WAIT_1, DELAY, COUNTING, BTN_WAIT_2);
	SIGNAL state : state_t := IDLE;

	-- Random number generation
	SIGNAL rng_en		: STD_LOGIC; 
	SIGNAL rnd_delay	: STD_LOGIC_VECTOR (7 DOWNTO 0);

	-- Response time visualization
	SIGNAL ssd_en, led_upd, led_flsh			: STD_LOGIC; 
	SIGNAL thousands, hundreds, tens, ones	: STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL red, green, blue						: STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '1');
	SIGNAL led_idx									: STD_LOGIC_VECTOR(4 DOWNTO 0);

BEGIN

	rng: prng PORT MAP (CLK => CLK_50, RST => '0', EN => rng_en, NUM => rnd_delay);
	leds: ws2812b PORT MAP (CLK => CLK_50, UPD => led_upd, FLSH => led_flsh, D_OUT => LED_0, IDX => led_idx, RED => red, GREEN => green, BLUE => blue);

	thousands_ssd: ssd PORT MAP (INP => thousands, EN => ssd_en, SEG => SSD_3);
	hundreds_ssd: ssd PORT MAP (INP => hundreds, EN => ssd_en, SEG => SSD_2);
	tens_ssd: ssd PORT MAP (INP => tens, EN => ssd_en, SEG => SSD_1);
	ones_ssd: ssd PORT MAP (INP => ones, EN => ssd_en, SEG => SSD_0);

PROCESS(CLK_50, RESP_BTN, STRT_BTN)
	VARIABLE tick: NATURAL RANGE 0 TO max_delay * 2 := 0;
	VARIABLE wait_ticks : INTEGER RANGE 0 TO max_delay * 2 := 0;
	VARIABLE response_time : INTEGER RANGE 0 TO max_delay * 2 := 0;
BEGIN IF RISING_EDGE(CLK_50) THEN
	CASE state IS
		WHEN IDLE =>
			rng_en <= '0';
			ssd_en <=  '0';
			led_upd <= '0';
			led_flsh <= '0';
			IF STRT_BTN = '0' THEN
				state <= BTN_WAIT_1;
			END IF;
		WHEN BTN_WAIT_1 =>
			rng_en <= '1';
			IF STRT_BTN = '1' THEN
				state <= DELAY;
				tick := 0;
			END IF;
		WHEN DELAY =>
			rng_en <= '0';
			wait_ticks := TO_INTEGER(UNSIGNED(rnd_delay));
			tick := tick + 1;
			IF tick = (max_delay * 2) - (max_delay / wait_ticks * wait_ticks) THEN
				state <= COUNTING;
				led_idx <= "00000";
				tick := 0;
				response_time := 0;
			END IF;
		WHEN COUNTING =>
			tick := tick + 1;
			IF tick = max_delay THEN
				state <= IDLE;
			ELSIF RESP_BTN = '0' THEN
				state <= BTN_WAIT_2;
				response_time := tick / (f_clk / 1000);
			END IF;
			IF tick mod delay_per_led = 0 THEN
				led_idx   <= STD_LOGIC_VECTOR(UNSIGNED(led_idx) + 1);
				led_upd   <= '1';
				led_flsh  <= '1';
			ELSE
				led_upd   <= '0';
				led_flsh  <= '0';
			END IF;
		WHEN BTN_WAIT_2 =>
			ssd_en <=  '1';
			led_upd <= '0';
			led_flsh <= '0';
			
			ones <=  STD_LOGIC_VECTOR(TO_UNSIGNED(response_time mod 10, ones'length));
			tens <=  STD_LOGIC_VECTOR(TO_UNSIGNED((response_time / 10) mod 10, tens'length));
			hundreds <=  STD_LOGIC_VECTOR(TO_UNSIGNED((response_time / 100) mod 10, hundreds'length));
			thousands <=  STD_LOGIC_VECTOR(TO_UNSIGNED(response_time / 1000, thousands'length));

			IF RESP_BTN = '1' THEN
				state <= IDLE;
			END IF;
		WHEN OTHERS =>
			tick := 0;
	END CASE;
END IF;
END PROCESS;
END driver;
