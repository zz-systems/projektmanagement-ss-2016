LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY Counter IS GENERIC
 ( 
	n : positive := 10
 );
 PORT 
 ( 
   clock  : IN  std_logic;
   enable : IN  std_logic;
   reset  : IN  std_logic;			-- Active Low Reset
   output : OUT  std_logic_vector(n-1 DOWNTO 0)
 );
END Counter;

ARCHITECTURE behavioral OF Counter IS

	SIGNAL count : std_logic_vector(n-1 DOWNTO 0);
	BEGIN
		PROCESS (clock, reset)
		BEGIN
			IF(reset = '0') THEN
				count <= (OTHERS => '0');
			ELSIF(clock'EVENT and clock = '1') THEN
				IF (enable = '1') THEN
						count <= count + 1;  
				END IF;
			END IF;
		END PROCESS;
   output <= count;
	
END Behavioral;

