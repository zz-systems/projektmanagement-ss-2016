LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std;

ENTITY LBPoperator IS GENERIC 
 (
   DATA_WIDTH	: integer := 8
 );
 PORT 
 ( 
		pixelclock_input	: IN std_logic;
		framesync_input	: IN std_logic;
		rowsync_input		: IN std_logic;
		centerpixel			: IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
		npixel1 				: IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
		npixel2 				: IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
		npixel3  			: IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
		npixel4  			: IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
		npixel5 				: IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
		npixel6  			: IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
		npixel7 				: IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
		npixel8  			: IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
		framesync_output	: OUT std_logic;
		rowsync_output		: OUT std_logic;
		pixeldata_output	: OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0)
 );
END LBPoperator;

ARCHITECTURE behavioral OF LBPoperator IS

	BEGIN 
	
	LBPoperator        : PROCESS (pixelclock_input)
	
	VARIABLE lbp       : std_logic_vector(7 DOWNTO 0);
	VARIABLE comp1     : std_logic;
	VARIABLE comp2     : std_logic;
	VARIABLE comp3     : std_logic;
	VARIABLE comp4     : std_logic;
	VARIABLE comp5     : std_logic;
	VARIABLE comp6     : std_logic;
	VARIABLE comp7     : std_logic;
	VARIABLE comp8     : std_logic;
	
	BEGIN
		IF (pixelclock_input'EVENT and pixelclock_input = '1') THEN
			rowsync_output <= rowsync_input;
			framesync_output <= framesync_input;
			
		IF framesync_input = '1' THEN			
			IF rowsync_input = '1' THEN		
		   
		   IF npixel1 < centerpixel THEN
					comp1 := '0';
				ELSE
					comp1 := '1';				
				END IF;	
	      IF npixel2 < centerpixel THEN
					comp2 := '0';
				ELSE
					comp2 := '1';				
				END IF;	
			IF npixel3 < centerpixel THEN
					comp3 := '0';
				ELSE
					comp3 := '1';				
				END IF;	
			IF npixel4 < centerpixel THEN
					comp4 := '0';
				ELSE
					comp4 := '1';				
				END IF;	
			IF npixel5 < centerpixel THEN
					comp5 := '0';
				ELSE
					comp5 := '1';				
				END IF;	
			IF npixel6 < centerpixel THEN
					comp6 := '0';
				ELSE
					comp6 := '1';				
				END IF;	
			IF npixel7 < centerpixel THEN
					comp7 := '0';
				ELSE
					comp7 := '1';				
				END IF;	
			IF npixel8 < centerpixel THEN
					comp8 := '0';
				ELSE
					comp8 := '1';				
				END IF;	

			lbp := comp1 & comp2 & comp3 & comp4 & comp5 & comp6 & comp7 & comp8;
			pixeldata_output <= lbp	;
			END IF;
      END IF;
    END IF;  	
  END PROCESS LBPoperator; 	
END behavioral;