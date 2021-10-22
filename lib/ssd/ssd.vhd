LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL; 

ENTITY ssd IS 
	PORT(
		INP	: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		EN		: IN STD_LOGIC;
		SEG	: OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	);
END ssd;

ARCHITECTURE driver OF ssd IS
BEGIN

	PROCESS(INP, EN)
	BEGIN
		IF EN = '1' THEN
			CASE TO_INTEGER(UNSIGNED(INP)) IS
				WHEN 0 => SEG <= "1000000";	-- 0
				WHEN 1 => SEG <= "1111001";	-- 1
				WHEN 2 => SEG <= "0100100";	-- 2
				WHEN 3 => SEG <= "0110000";	-- 3
				WHEN 4 => SEG <= "0011001";	-- 4
				WHEN 5 => SEG <= "0010010";	-- 5
				WHEN 6 => SEG <= "0000010";	-- 6
				WHEN 7 => SEG <= "1111000";	-- 7
				WHEN 8 => SEG <= "0000000";	-- 8
				WHEN 9 => SEG <= "0011000";  	-- 9
				WHEN 10 => SEG <= "0001000";	-- A
				WHEN 11 => SEG <= "0000011";	-- b
				WHEN 12 => SEG <= "1000110";	-- C
				WHEN 13 => SEG <= "0100001";	-- d
				WHEN 14 => SEG <= "0000110";	-- E
				WHEN 15 => SEG <= "0001110";	-- F
				WHEN others => SEG <= "0111111";	-- -
			END CASE;
		ELSE
			SEG <= "1111111";						-- Turn segments off.
		END IF;
	END PROCESS;
END driver;