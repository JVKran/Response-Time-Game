LIBRARY ieee;
USE ieee.numeric_std.all; 
USE ieee.std_logic_1164.all;

ENTITY color_loop IS
	GENERIC(
		PERIOD 		 : natural := 500000	-- 10 Milliseconds
	);
	PORT(
		CLK_50	: IN STD_LOGIC;
		LED	: OUT STD_LOGIC
	);
END color_loop;

ARCHITECTURE driver OF color_loop IS

COMPONENT ws2812b IS
	PORT(
		CLK, RST, FLSH 	 : IN STD_LOGIC;			-- Clock, Reset & Flush
		D_OUT	 	 : OUT STD_LOGIC;			-- Data out
		RED, GREEN, BLUE : IN STD_LOGIC_VECTOR(7 DOWNTO 0)	-- Red, Green & Blue inputs
	);
END COMPONENT;

	SIGNAL FLUSH	: STD_LOGIC := '0';
	SIGNAL RED 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	SIGNAL GREEN 	: STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	SIGNAL BLUE	: STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');

BEGIN
pixel: ws2812b PORT MAP(CLK => CLK_50, RST => '0', FLSH => FLUSH, D_OUT => LED, RED => RED, GREEN => GREEN, BLUE => BLUE);
PROCESS(CLK_50) IS
	VARIABLE tick : NATURAL RANGE 0 TO PERIOD := 0;
	VARIABLE dir  : INTEGER RANGE -1 TO 1 := 0;
BEGIN IF RISING_EDGE(CLK_50) THEN
	tick := tick + 1;
	IF tick = PERIOD THEN
		tick := 0;
		IF UNSIGNED(RED) = 255 THEN
			dir := -1;
		ELSIF UNSIGNED(RED) = 0 THEN
			dir := 1;
		END IF;
		IF dir = 1 THEN
			RED <= STD_LOGIC_VECTOR(UNSIGNED(RED) + 1);		-- Overflow takes care of going back to 0.
		ELSE
			RED <= STD_LOGIC_VECTOR(UNSIGNED(RED) - 1);
		END IF;
		FLUSH <= '1';						-- Todo; temporarily make high.
	ELSE
		FLUSH <= '0';
	END IF;
END IF; END PROCESS;
END driver;

