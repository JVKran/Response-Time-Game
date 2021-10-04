library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity prng_tb is
end prng_tb;

architecture tb of prng_tb is

COMPONENT prng
PORT ( 
	CLK, RST, EN 		: IN STD_LOGIC;
       	NUM 			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
);
END COMPONENT;

SIGNAL CLK_tb, RST_tb, EN_tb 	: STD_LOGIC;
SIGNAL NUM_tb 			: STD_LOGIC_VECTOR (7 DOWNTO 0);

begin

	pseudo_rng: prng PORT MAP(
		CLK => CLK_tb,
		RST => RST_tb,
		EN => EN_tb,
		NUM => NUM_tb
	);

	PROCESS BEGIN
		CLK_tb <= '0';
		

		FOR cycle IN 0 TO 14000 LOOP
			WAIT FOR 50 ns;
			CLK_tb <= not CLK_tb;
		END LOOP;
	WAIT;
	END PROCESS;

reset: PROCESS
BEGIN
   RST_tb <= '0';
   EN_tb  <= '1';
   WAIT FOR 900 ns;
END PROCESS;

end ARCHITECTURE;