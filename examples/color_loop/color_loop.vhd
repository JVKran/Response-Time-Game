LIBRARY ieee;
USE ieee.numeric_std.ALL; 
USE ieee.std_logic_1164.ALL;

ENTITY color_loop IS
	GENERIC(
		PERIOD  	: natural := 500000;	-- 10 Milliseconds
		LED_AMT 	: integer := 24			-- 24 Leds on ring
	);
	PORT(
		CLK_50	: IN STD_LOGIC;
		LED		: OUT STD_LOGIC
	);
END color_loop;

ARCHITECTURE driver OF color_loop IS

	COMPONENT ws2812b IS
		GENERIC(
			LED_AMT 	: integer := 24
		);
		PORT(
			CLK, UPD, FLSH 	 : IN STD_LOGIC;			-- Clock, Update & Flush
			D_OUT	 	 : OUT STD_LOGIC;			-- Data out
			IDX		 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- Index of led to update; optional todo, scale on LED_AMT.
			RED, GREEN, BLUE : IN STD_LOGIC_VECTOR(7 DOWNTO 0)	-- Red, Green & Blue inputs
		);
	END COMPONENT;

	SIGNAL FLSH, UPD : STD_LOGIC := '0';
	SIGNAL IDX	 : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00000";
	SIGNAL RED 	 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	SIGNAL GREEN 	 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	SIGNAL BLUE	 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');

BEGIN

	pixel: ws2812b PORT MAP(CLK => CLK_50, UPD => UPD, FLSH => FLSH, D_OUT => LED, IDX => IDX, RED => RED, GREEN => GREEN, BLUE => BLUE);

	PROCESS(CLK_50) IS
		VARIABLE tick : NATURAL RANGE 0 TO PERIOD := 0;
		VARIABLE dir  : INTEGER RANGE -1 TO 1 := 0;
	BEGIN IF RISING_EDGE(CLK_50) THEN
		tick := tick + 1;
		IF tick = PERIOD THEN
			tick := 0;
			
			-- Flip direction when bounds are reached.
			IF UNSIGNED(RED) = 255 THEN
				dir := -1;
			ELSIF UNSIGNED(RED) = 0 THEN
				dir := 1;
			END IF;

			-- Increment or decrement RED value based on direction.
			IF dir = 1 THEN
				RED <= STD_LOGIC_VECTOR(UNSIGNED(RED) + 1);
			ELSE
				RED <= STD_LOGIC_VECTOR(UNSIGNED(RED) - 1);
			END IF;

			-- Circularly update leds; creates loop effect.
			IF UNSIGNED(IDX) = LED_AMT - 1 THEN
				IDX <= "00000";
			ELSE
				IDX   <= STD_LOGIC_VECTOR(UNSIGNED(IDX) + 1);
			END IF;
			
			-- Update leds and flush changes.
			UPD   <= '1';
			FLSH  <= '1';
		ELSE
			UPD   <= '0';
			FLSH  <= '0';
		END IF;

	END IF; END PROCESS;
END driver;

