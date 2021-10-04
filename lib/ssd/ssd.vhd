LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all; 

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
			when 0 => SEG <= "1000000";	-- 0
			when 1 => SEG <= "1111001";	-- 1
			when 2 => SEG <= "0100100";	-- 2
			when 3 => SEG <= "0110000";	-- 3
			when 4 => SEG <= "0011001";	-- 4
			when 5 => SEG <= "0010010";	-- 5
			when 6 => SEG <= "0000010";	-- 6
			when 7 => SEG <= "1111000";	-- 7
			when 8 => SEG <= "0000000";	-- 8
			when 9 => SEG <= "0011000";  	-- 9
			when 10 => SEG <= "0001000";	-- A
			when 11 => SEG <= "0000011";	-- b
			when 12 => SEG <= "1000110";	-- C
			when 13 => SEG <= "0100001";	-- d
			when 14 => SEG <= "0000110";	-- E
			when 15 => SEG <= "0001110";	-- F
			when others => SEG <= "0111111";	-- -
		END CASE;
	ELSE
		SEG <= "1111111";
	END IF;
END PROCESS;
		
end driver;