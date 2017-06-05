LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY DoubleFIFOLineBuffer IS GENERIC
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
	pixeldata_output1	: OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	pixeldata_output2	: BUFFER std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	pixeldata_output3	: BUFFER std_logic_vector(DATA_WIDTH-1 DOWNTO 0)
 );
END DoubleFIFOLineBuffer;

ARCHITECTURE behavioral OF DoubleFIFOLineBuffer IS

	COMPONENT FIFOLineBuffer IS GENERIC 
	 (
		DATA_WIDTH	: integer := 8;
		NO_OF_COLS	: integer := 640 
	 );
	 PORT
	 (
		clock 		     : IN std_logic;
		framesync   	  : IN std_logic;
		rowsync			  : IN std_logic;
		pixeldata_input  : IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
		pixeldata_output : BUFFER std_logic_vector(DATA_WIDTH-1 DOWNTO 0)
	 );
	END COMPONENT;
	
	BEGIN

		LineBuffer1 : FIFOLineBuffer GENERIC MAP (DATA_WIDTH => DATA_WIDTH, NO_OF_COLS => NO_OF_COLS) 
											  PORT MAP(clock, framesync, rowsync, pixeldata_input, pixeldata_output2);
											  
		LineBuffer2 : FIFOLineBuffer GENERIC MAP (DATA_WIDTH => DATA_WIDTH, NO_OF_COLS => NO_OF_COLS) 
											  PORT MAP(clock, framesync, rowsync, pixeldata_output2, pixeldata_output3);
											  
		pixeldata_output1 <= pixeldata_input;
	
END behavioral;

