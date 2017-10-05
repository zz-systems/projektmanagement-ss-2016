LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY CacheSystem IS GENERIC 
 (
	DATA_WIDTH	: integer := 8;
	WINDOW_SIZE	: integer := 3;
	ROW_BITS	   : integer := 9;
	COL_BITS	   : integer := 10;
	NO_OF_ROWS	: integer := 480;
	NO_OF_COLS	: integer := 640 
 );
 PORT
 (
	clock 		     : IN std_logic;
	framesync_input  : IN std_logic;
	rowsync_input	  : IN std_logic;
	pixeldata_input  : IN std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	framesync_output : OUT std_logic;
	rowsync_output   : OUT std_logic;
	centerpixel      : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	npixel1  		  : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	npixel2  		  : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	npixel3          : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	npixel4          : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	npixel5          : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	npixel6          : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	npixel7          : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	npixel8          : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0)
 );
END CacheSystem;

ARCHITECTURE behavioral OF CacheSystem IS

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

	COMPONENT DoubleFIFOLineBuffer IS GENERIC
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
	END COMPONENT;

	COMPONENT SyncSignalsDelayer IS GENERIC
	 (
		ROW_BITS	: integer := 9
    );
	PORT
	( 
		clock            : IN  std_logic;
		framesync_input  : IN  std_logic;
		rowsync_input    : IN  std_logic;
		framesync_output : OUT  std_logic;
		rowsync_output   : OUT  std_logic
	);
	END COMPONENT;

	SIGNAL RowCounterOutput    : std_logic_vector(ROW_BITS-1 DOWNTO 0);
	SIGNAL ColumnCounterOutput : std_logic_vector(COL_BITS-1 DOWNTO 0);
	SIGNAL DataOutput1	      : std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	SIGNAL DataOutput2	      : std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	SIGNAL DataOutput3	      : std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	SIGNAL framesync_temp 		: std_logic;
   SIGNAL rowsync_temp 			: std_logic;
	
	-- pixel elements cache
	-- |---------------------------------------------------------------------------------|
	-- | npixel8-npixel5-npixel2 | npixel7-npixel4-npixel1 | npixel6-npixel3-centerpixel |
	-- |---------------------------------------------------------------------------------|
	-- 23                      16|15                      8|7                            0
	
	SHARED VARIABLE cache1 : std_logic_vector((WINDOW_SIZE*DATA_WIDTH)-1 DOWNTO 0);
	SHARED VARIABLE cache2 : std_logic_vector((WINDOW_SIZE*DATA_WIDTH)-1 DOWNTO 0);
	SHARED VARIABLE cache3 : std_logic_vector((WINDOW_SIZE*DATA_WIDTH)-1 DOWNTO 0);
	
	BEGIN

		DoubleLineBuffer: DoubleFIFOLineBuffer GENERIC MAP (DATA_WIDTH => DATA_WIDTH,	NO_OF_COLS => NO_OF_COLS)
														   PORT MAP (clock => clock, framesync => framesync_input, rowsync => rowsync_input,
																		 pixeldata_input => pixeldata_input, pixeldata_output1 => DataOutput1,
																		 pixeldata_output2 => DataOutput2, pixeldata_output3 => DataOutput3 );
			  
		Delayer: SyncSignalsDelayer GENERIC MAP (ROW_BITS => ROW_BITS)
											 PORT MAP (clock => clock, framesync_input => framesync_input, rowsync_input => rowsync_input,
														  framesync_output => framesync_temp, rowsync_output => rowsync_temp);
			  
		RowsCounter : Counter GENERIC MAP(9) PORT MAP(rowsync_temp, framesync_temp,framesync_temp,RowCounterOutput);
		ColumnsCounter : Counter GENERIC MAP(10) PORT MAP(clock, rowsync_temp,rowsync_temp,ColumnCounterOutput);
			  
		framesync_output <= framesync_temp;
		rowsync_output <= rowsync_temp;
		
		ShiftingProcess : PROCESS (clock)
		BEGIN
			IF (clock'EVENT and clock = '1') THEN
					-- the pixel in the central layer is copied into the lower layer
					cache1(DATA_WIDTH-1 DOWNTO 0):= cache1(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-2)*DATA_WIDTH));
					cache2(DATA_WIDTH-1 DOWNTO 0):= cache2(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-2)*DATA_WIDTH));
					cache3(DATA_WIDTH-1 DOWNTO 0):= cache3(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-2)*DATA_WIDTH));
					-- the pixel in the higher layer is copied into the central layer
					cache1(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-2)*DATA_WIDTH)):= cache1((WINDOW_SIZE*DATA_WIDTH)-1 DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					cache2(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-2)*DATA_WIDTH)):= cache2((WINDOW_SIZE*DATA_WIDTH)-1 DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					cache3(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-2)*DATA_WIDTH)):= cache3((WINDOW_SIZE*DATA_WIDTH)-1 DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					-- the output of the RAM is assigned to the higher layer of the variable
					cache1((WINDOW_SIZE*DATA_WIDTH)-1 DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH)):= DataOutput1;
					cache2((WINDOW_SIZE*DATA_WIDTH)-1 DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH)):= DataOutput2;
					cache3((WINDOW_SIZE*DATA_WIDTH)-1 DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH)):= DataOutput3;			
			END IF; -- clock
		END PROCESS ShiftingProcess;
		
		EmittingProcess : PROCESS (RowCounterOutput,ColumnCounterOutput,framesync_temp)
		BEGIN
			IF framesync_temp = '1' THEN 
	
				IF RowCounterOutput="000000000" and ColumnCounterOutput="0000000000" THEN --1
					centerpixel <= (OTHERS => '0');
					npixel1 		<= (OTHERS => '0');
					npixel2	 	<= (OTHERS => '0');
					npixel3 		<= (OTHERS => '0');
					npixel4 		<= cache2(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-2)*DATA_WIDTH));
					npixel5 		<= cache2(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH)); 
					npixel6 		<= (OTHERS => '0');
					npixel7 		<= cache1(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-2)*DATA_WIDTH));
					npixel8 		<= cache1(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					
				-- column > 0 and column < 639
				ELSIF RowCounterOutput="000000000" and ColumnCounterOutput>"0000000000" and ColumnCounterOutput<"1001111111" THEN 
					centerpixel <= (OTHERS => '0');	
					npixel1     <= (OTHERS => '0');
					npixel2		<= (OTHERS => '0');
					npixel3		<= cache2((DATA_WIDTH-1) DOWNTO 0); 
					npixel4		<= cache2(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel5		<= cache2(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					npixel6		<= cache1((DATA_WIDTH-1) DOWNTO 0);
					npixel7		<= cache1(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel8		<= cache1(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					
					
				-- column = 639
				ELSIF RowCounterOutput="000000000" and ColumnCounterOutput="1001111111" THEN 
					centerpixel <= (OTHERS => '0');	
					npixel1		<= (OTHERS => '0');	
					npixel2		<= (OTHERS => '0');	
					npixel3		<= cache2((DATA_WIDTH-1) DOWNTO 0); 
					npixel4		<= cache2(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel5		<= (OTHERS => '0');	
					npixel6		<= cache1((DATA_WIDTH-1) DOWNTO 0);
					npixel7		<= cache1(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel8		<= (OTHERS => '0');
					
				-- row > 0 and row < 479
				ELSIF RowCounterOutput>"000000000" and RowCounterOutput<"111011111" and ColumnCounterOutput="0000000000" THEN 
					centerpixel <= (OTHERS => '0');	
					npixel1	<= cache3(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel2	<= cache3(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					npixel3	<= (OTHERS => '0');	
					npixel4	<= cache2(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel5	<= cache2(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					npixel6	<= (OTHERS => '0');	
					npixel7	<= cache1(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel8	<= cache1(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					
				-- row > 0 and row < 479 and column > 0 and column < 639
				ELSIF RowCounterOutput>"000000000" and RowCounterOutput<"111011111" and ColumnCounterOutput>"0000000000" and ColumnCounterOutput<"1001111111" THEN
					centerpixel <= cache3((DATA_WIDTH-1) DOWNTO 0);	
					npixel1		<= cache3(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel2		<= cache3(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					npixel3		<= cache2((DATA_WIDTH-1) DOWNTO 0);
					npixel4		<= cache2(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel5		<= cache2(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					npixel6		<= cache1((DATA_WIDTH-1) DOWNTO 0);	
					npixel7		<= cache1(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel8		<= cache1(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					
				-- row > 0 and row < 479 and column > 0 and column = 639
				ELSIF RowCounterOutput>"000000000" and RowCounterOutput<"111011111" and ColumnCounterOutput="1001111111" THEN 
					centerpixel <= cache3((DATA_WIDTH-1) DOWNTO 0);
					npixel1		<= cache3(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel2		<= (OTHERS => '0');
					npixel3		<= cache2((DATA_WIDTH-1) DOWNTO 0);
					npixel4		<= cache2(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel5		<= (OTHERS => '0');
					npixel6		<= cache1((DATA_WIDTH-1) DOWNTO 0);
					npixel7		<= cache1(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel8		<= (OTHERS => '0');
					
				-- row = 479 and column = 0
				ELSIF RowCounterOutput="111011111" and ColumnCounterOutput="0000000000" THEN
					centerpixel	<= (OTHERS => '0');
					npixel1		<= cache3(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel2		<= cache3(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					npixel3		<= (OTHERS => '0');
					npixel4		<= cache2(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel5		<= cache2(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					npixel6		<= (OTHERS => '0');	
					npixel7		<= (OTHERS => '0');
					npixel8		<= (OTHERS => '0');
					
				-- row = 479 and column > 0 and column < 639
				ELSIF RowCounterOutput="111011111" and ColumnCounterOutput>"0000000000" and ColumnCounterOutput<"1001111111" THEN 
					centerpixel <= cache3((DATA_WIDTH-1) DOWNTO 0);
					npixel1		<= cache3(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel2		<= cache3(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					npixel3		<= cache2((DATA_WIDTH-1) DOWNTO 0);
					npixel4		<= cache2(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel5		<= cache2(((WINDOW_SIZE)*DATA_WIDTH-1) DOWNTO ((WINDOW_SIZE-1)*DATA_WIDTH));
					npixel6		<= (OTHERS => '0');
					npixel7		<= (OTHERS => '0');
					npixel8		<= (OTHERS => '0');
					
				-- row = 479 and column = 639
				ELSIF RowCounterOutput="111011111" and ColumnCounterOutput="1001111111" THEN 
					centerpixel <= cache3((DATA_WIDTH-1) DOWNTO 0);
					npixel1		<= cache3(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel2		<= (OTHERS => '0');
					npixel3		<= cache2((DATA_WIDTH-1) DOWNTO 0);
					npixel4		<= cache2(((WINDOW_SIZE-1)*DATA_WIDTH-1) DOWNTO DATA_WIDTH);
					npixel5		<= (OTHERS => '0');
					npixel6		<= (OTHERS => '0');
					npixel7		<= (OTHERS => '0');
					npixel8		<= (OTHERS => '0');
					
				END IF; -- RowCounterOutput and ColumnCounterOutput
			END IF; --rowsync_temp	
		END PROCESS EmittingProcess;
END behavioral;