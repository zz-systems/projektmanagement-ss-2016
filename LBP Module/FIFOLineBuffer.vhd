PACKAGE TYPES IS 
	SUBTYPE SMALL_INTEGER IS integer RANGE 0 TO 639;
END PACKAGE;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
USE work.TYPES.ALL;

ENTITY FIFOLineBuffer IS GENERIC 
 (
	DATA_WIDTH	: integer := 8;
	NO_OF_COLS	: integer := 640
 );
 PORT
 (
	clock 		      : IN std_logic;
	framesync   		: IN std_logic;
	rowsync			   : IN std_logic;
	pixeldata_input 	: IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	pixeldata_output	: BUFFER std_logic_vector(DATA_WIDTH-1 DOWNTO 0)
	);
END FIFOLineBuffer;

ARCHITECTURE behavioral OF FIFOLineBuffer IS

	TYPE ram_type IS ARRAY (NO_OF_COLS-1 DOWNTO 0) OF std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	SIGNAL ram_array	 : ram_type;
	SIGNAL clock2 		 : std_logic;
	SIGNAL ColsCounter : SMALL_INTEGER := 0;
	
	BEGIN
		clock2 <= not clock;	
		
		read_from_memory : PROCESS(clock)
		BEGIN
			IF (clock'EVENT and clock = '1') THEN
				IF framesync = '1' THEN
					IF rowsync = '1' THEN
						pixeldata_output <= ram_array(ColsCounter);
					END IF;
				END IF;
			END IF; 
		END PROCESS read_from_memory;
			
		write_to_memory : PROCESS (clock2)
		BEGIN
			IF clock2'EVENT and clock2='1' THEN
				IF framesync = '1' THEN
					IF rowsync = '1' THEN
						ram_array(ColsCounter) <= pixeldata_input;
							IF ColsCounter < 639 THEN
							ColsCounter	<= ColsCounter+1;
						ELSE
							ColsCounter	<= 0;
						END IF;
					ELSE
						ColsCounter	<= 0;
					END IF; -- rowsync
				END IF; -- framesync
			END IF; -- clk2
		END PROCESS write_to_memory;

END behavioral;

