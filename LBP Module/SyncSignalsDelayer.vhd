LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY SyncSignalsDelayer IS GENERIC 
 (
	ROW_BITS	: integer := 9 
 );
 PORT
 (
	clock            : IN std_logic;
	framesync_input  : IN std_logic;
	rowsync_input    : IN std_logic;
	framesync_output : OUT std_logic;
	rowsync_output   : OUT std_logic 
 );
END SyncSignalsDelayer;

ARCHITECTURE behavioral OF SyncSignalsDelayer IS

	SIGNAL RowDelayCounterRisingEdge, RowDelayCounterFallingEdge : std_logic_vector(ROW_BITS-1 DOWNTO 0);
	SIGNAL rowsync2, rowsync1, framesync_temp : std_logic;
	
	COMPONENT Counter IS GENERIC 
	 (
	   n : positive
	 );
	 PORT 
	 ( 
	   clock  : IN  std_logic;
	   enable : IN  std_logic;
	   reset  : IN  std_logic;			
	   output : OUT std_logic_vector(n-1 DOWNTO 0)
    );
	END COMPONENT;

	BEGIN
		
		RowsCounterComponent : Counter GENERIC MAP(ROW_BITS) 
												 PORT MAP(rowsync2, framesync_input,framesync_input,RowDelayCounterRisingEdge);
		rowsync_output   <= rowsync2;
		framesync_output <= framesync_temp;
	
	step1 : PROCESS(clock)
	BEGIN
		IF (clock'EVENT and clock = '1') THEN -- delay of two clock cycles
			rowsync2 <= rowsync1;
			rowsync1 <= rowsync_input;
		END IF;
	END PROCESS step1;

	step2 : PROCESS(RowDelayCounterRisingEdge, RowDelayCounterFallingEdge)
	BEGIN
		IF RowDelayCounterRisingEdge = "000000010" THEN
			framesync_temp <= '1';
		ELSIF RowDelayCounterFallingEdge = "000000000" THEN
			framesync_temp <= '0';
		END IF;
	END PROCESS step2;

	step3 : PROCESS(rowsync2)
	BEGIN
		IF (rowsync2'EVENT and rowsync2 = '0') THEN
			IF framesync_temp = '1' THEN
				IF RowDelayCounterFallingEdge < "111011111" THEN -- row count = 479
					RowDelayCounterFallingEdge <= RowDelayCounterFallingEdge + 1;
				ELSE
					RowDelayCounterFallingEdge <= "000000000";
				END IF;
			ELSE
				RowDelayCounterFallingEdge <= "000000000";
			END IF;
		END IF;
	END PROCESS step3;

END behavioral;

