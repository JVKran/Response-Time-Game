LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Pseudo Random Number Generator (LFSR)
-- This component implements a PRNG based on the Linear
-- Feedback Shift Register (LFSR). Based on previous 
-- implementation in C.

ENTITY prng IS
   PORT ( 
      CLK, RST, EN 	: IN STD_LOGIC;
      NUM 				: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
   );
END prng;

ARCHITECTURE driver OF prng IS
   SIGNAL LFSR			: STD_LOGIC_VECTOR(7 DOWNTO 0) := x"01";
BEGIN

PROCESS(CLK)
   VARIABLE tmp 		: STD_LOGIC := '0';
   BEGIN

   IF RISING_EDGE(CLK) THEN
      IF (RST='1') THEN
         LFSR <= x"01"; 
      ELSIF EN = '1' THEN
         tmp := LFSR(4) XOR LFSR(3) XOR LFSR(2) XOR LFSR(0);
         LFSR <= tmp & LFSR(7 DOWNTO 1);
      END IF;
   END IF;
END PROCESS;
NUM <= LFSR;

END driver;