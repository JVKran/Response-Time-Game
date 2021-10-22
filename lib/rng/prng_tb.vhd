LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY prng_tb IS
END prng_tb;

ARCHITECTURE tb of prng_tb IS

	COMPONENT prng
		PORT ( 
			CLK, RST, EN 	: IN STD_LOGIC;
			NUM 		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	END COMPONENT;

	SIGNAL CLK_tb, RST_tb, EN_tb 	: STD_LOGIC;
	SIGNAL NUM_tb 			: STD_LOGIC_VECTOR (7 DOWNTO 0);

BEGIN

	-- Suggested simulation time of 2ms.

	pseudo_rng: prng PORT MAP(
		CLK => CLK_tb,
		RST => RST_tb,
		EN => EN_tb,
		NUM => NUM_tb
	);

	randomize: PROCESS BEGIN
		CLK_tb <= '0';

		FOR cycle IN 0 TO 14000 LOOP
			WAIT FOR 50 ns;
			CLK_tb <= not CLK_tb;
		END LOOP;
	WAIT;
	END PROCESS;

	reset: PROCESS BEGIN
		RST_tb <= '0';
		EN_tb  <= '1';
		WAIT FOR 900 ns;
	END PROCESS;

END ARCHITECTURE;