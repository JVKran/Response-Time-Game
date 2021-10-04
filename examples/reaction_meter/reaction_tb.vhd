LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY reaction_tb IS
END ENTITY;

architecture testbench of reaction_tb is

COMPONENT reaction IS
GENERIC (
	max_delay	: NATURAL := 50;
	delay_per_led	: NATURAL := 5
);
PORT(
	CLK_50, BTN			: IN STD_LOGIC;
	D_OUT				: OUT STD_LOGIC;
	SSD_0, SSD_1, SSD_2, SSD_3	: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
);
END COMPONENT;

SIGNAL CLK_tb, BTN_tb				: STD_LOGIC;
SIGNAL DOUT_tb					: STD_LOGIC;
SIGNAL SSD_0_tb, SSD_1_tb, SSD_2_tb, SSD_3_tb	: STD_LOGIC_VECTOR(6 downto 0);
 
BEGIN
	test: reaction PORT MAP (
		CLK_50 => CLK_tb,
		BTN => BTN_tb,
		D_OUT => DOUT_tb,
		SSD_0 => SSD_0_tb,
		SSD_1 => SSD_1_tb,
		SSD_2 => SSD_2_tb,
		SSD_3 => SSD_3_tb
	);

	PROCESS
	BEGIN
		-- INIT state
		CLK_tb <= '0';
		BTN_tb <= '1';

		FOR i IN 0 TO 1000000 LOOP
			WAIT FOR 10 ps;
 			CLK_tb <= not CLK_tb;
			
			-- Keep button pressed then release
			IF (i > 500 and i < 600) THEN 
				BTN_tb <= '0'; 
			ELSE 
				BTN_tb <= '1'; 
			END IF;

		END LOOP;
		WAIT;
	END PROCESS;
END ARCHITECTURE;
