LIBRARY ieee;
USE ieee.numeric_std.all; 
USE ieee.std_logic_1164.all;

ENTITY reaction IS
GENERIC (
	max_delay	: NATURAL := 150_000_000;
	delay_per_led	: NATURAL := 1_000_000
);
PORT(
	CLK_50, BTN			: IN STD_LOGIC;
	D_OUT				: OUT STD_LOGIC;
	SSD_0, SSD_1, SSD_2, SSD_3	: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
);
END reaction;

ARCHITECTURE driver OF reaction IS

COMPONENT ssd IS 
	PORT(
		INP		: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		EN		: IN STD_LOGIC;
		SEG		: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	);
END COMPONENT;

COMPONENT prng IS
	PORT ( 
		CLK, RST, EN 	: IN STD_LOGIC;
       		NUM 		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END COMPONENT;

COMPONENT ws2812b IS
	GENERIC(		 -- For FPGA
		LED_AMT		 : integer := 24;			-- 24 Leds on ring
		F_CLK 		 : natural := 50000000			-- 50Mhz
	);
	PORT(
		CLK, UPD, FLSH 	 : IN STD_LOGIC;			-- Clock, Update & Flush
		D_OUT	 	 : OUT STD_LOGIC;			-- Data out
		IDX		 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- Index of led to update; optional todo, scale on LED_AMT.
		RED, GREEN, BLUE : IN STD_LOGIC_VECTOR(7 DOWNTO 0)	-- Red, Green & Blue inputs
	);
END COMPONENT;


TYPE state IS (IDLE, BTN_WAIT_1, DELAY, COUNTING, BTN_WAIT_2);
SIGNAL pr_state, nx_state : state := IDLE;

SIGNAL rng_en, ssd_en, led_upd, led_flsh 			: STD_LOGIC; 
SIGNAL thousands, hundreds, tens, ones	: STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL rnd_delay, green, blue		: STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL red				: STD_LOGIC_VECTOR (7 DOWNTO 0) := (others => '1');
SIGNAL led_idx				: STD_LOGIC_VECTOR(4 DOWNTO 0);

BEGIN

	thousands_ssd: ssd PORT MAP (INP => thousands, EN => ssd_en, SEG => SSD_3);
	hundreds_ssd: ssd PORT MAP (INP => hundreds, EN => ssd_en, SEG => SSD_2);
	tens_ssd: ssd PORT MAP (INP => tens, EN => ssd_en, SEG => SSD_1);
	ones_ssd: ssd PORT MAP (INP => ones, EN => ssd_en, SEG => SSD_0);

	rng: prng PORT MAP (CLK => CLK_50, RST => '0', EN => rng_en, NUM => rnd_delay);
	leds: ws2812b PORT MAP (CLK => CLK_50, UPD => led_upd, FLSH => led_flsh, D_OUT => D_OUT, IDX => led_idx, RED => red, GREEN => green, BLUE => blue);
		

PROCESS(CLK_50)
BEGIN
	IF (rising_edge(CLK_50)) THEN
		pr_state <= nx_state;
	END IF;
END PROCESS;

PROCESS(pr_state, BTN, CLK_50)
	VARIABLE tick: NATURAL RANGE 0 TO max_delay + 1 := 0;
	VARIABLE response_time : INTEGER RANGE 0 TO 1000 := 0;
BEGIN
	CASE pr_state IS
		WHEN IDLE =>
			ssd_en <= '0';
			rng_en <= '0';
			IF BTN = '0' THEN
				nx_state <= BTN_WAIT_1;
			ELSE
				nx_state <= pr_state;
			END IF;
		WHEN BTN_WAIT_1 =>
			rng_en <= '1';
			IF BTN = '1' THEN
				nx_state <= DELAY;
				tick := 0;
			ELSE
				nx_state <= pr_state;
			END IF;
		WHEN DELAY =>
			rng_en <= '0';
			tick := tick + 1;
			IF tick = max_delay THEN
				nx_state <= COUNTING;
				tick := 0;
				response_time := 0;
			ELSE
				nx_state <= pr_state;
			END IF;
		WHEN COUNTING =>
			tick := tick + 1;
			IF tick = delay_per_led THEN
				response_time := response_time + delay_per_led;
				tick := 0;
				led_idx   <= STD_LOGIC_VECTOR(UNSIGNED(led_idx) + 1);
				led_upd   <= '1';
				led_flsh  <= '1';
			ELSE
				led_upd   <= '0';
				led_flsh  <= '0';
			END IF;
		  	IF BTN = '0' THEN
				nx_state <= BTN_WAIT_2;
				response_time := response_time + tick;
			ELSE
				nx_state <= pr_state;
			END IF;
		WHEN BTN_WAIT_2 =>
			ssd_en <=  '1';
			ones <=  STD_LOGIC_VECTOR(TO_UNSIGNED(response_time mod 10, ones'length));
			tens <=  STD_LOGIC_VECTOR(TO_UNSIGNED((response_time / 10) mod 10, tens'length));
			hundreds <=  STD_LOGIC_VECTOR(TO_UNSIGNED((response_time / 100) mod 10, hundreds'length));
			thousands <=  STD_LOGIC_VECTOR(TO_UNSIGNED(response_time / 1000, thousands'length));

			IF BTN = '1' THEN
				nx_state <= IDLE;
			ELSE
				nx_state <= pr_state;
			END IF;
		WHEN OTHERS =>
			
	END CASE;
END PROCESS;
END driver;
