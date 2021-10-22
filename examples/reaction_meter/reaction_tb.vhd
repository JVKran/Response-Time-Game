LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY reaction_tb IS
END ENTITY;

architecture testbench of reaction_tb is

COMPONENT reaction IS
	GENERIC (
		MAX_DELAY		: INTEGER := 1500;				-- Maximum delay in cycles; 3 seconds.
		DELAY_PER_LED		: INTEGER := 10;				-- Delay per extra led; 20 milliseconds.
		LED_AMT			: INTEGER := 24;				-- Amount of leds on ring.
		F_CLK			: INTEGER := 500				-- Clock frequency in Hz.
	);
	PORT(
		CLK_50, STRT_BTN, RESP_BTN	: IN STD_LOGIC;
		HLF_SW, DIR_SW			: IN STD_LOGIC;
		LED_0				: OUT STD_LOGIC;
		SSD_0, SSD_1, SSD_2, SSD_3	: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	);
END COMPONENT;

	SIGNAL CLK_tb, STRT_BTN_tb, RESP_BTN_tb		: STD_LOGIC;
	SIGNAL LED_0_tb					: STD_LOGIC;
	SIGNAL SSD_0_tb, SSD_1_tb, SSD_2_tb, SSD_3_tb	: STD_LOGIC_VECTOR(6 downto 0);
	SIGNAL DIR_SW_tb, HLF_SW_tb			: STD_LOGIC;
 
BEGIN

	test: reaction PORT MAP (
		CLK_50 => CLK_tb,
		STRT_BTN => STRT_BTN_tb,
		RESP_BTN => RESP_BTN_tb,
		DIR_SW	 => DIR_SW_tb,
		HLF_SW	 => HLF_SW_tb,
		LED_0 => LED_0_tb,
		SSD_0 => SSD_0_tb,
		SSD_1 => SSD_1_tb,
		SSD_2 => SSD_2_tb,
		SSD_3 => SSD_3_tb
	);

	PROCESS
	BEGIN
		-- INIT state
		CLK_tb      <= '0';
		RESP_BTN_tb <= '1';
		STRT_BTN_tb <= '1';

		-- Light up leds upwards and use full (500 ms) reaction time.
		DIR_SW_tb <= '0';
		HLF_SW_tb <= '0';

		FOR i IN 0 TO 1000000 LOOP
			WAIT FOR 10 ps;
 			CLK_tb <= not CLK_tb;
			
			-- Keep start button button pressed then release
			IF (i > 5000 and i < 6000) THEN 
				STRT_BTN_tb <= '0'; 
			ELSE 
				STRT_BTN_tb <= '1'; 
			END IF;

			-- Keep response button pressed then release
			IF (i > 60000 and i < 62000) THEN 
				RESP_BTN_tb <= '0'; 
			ELSE 
				RESP_BTN_tb <= '1'; 
			END IF;

		END LOOP;
		WAIT;
	END PROCESS;
END ARCHITECTURE;
