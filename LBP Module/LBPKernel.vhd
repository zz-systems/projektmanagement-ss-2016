LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std;

ENTITY LBPKernel IS GENERIC 
 (
	DATA_WIDTH	: integer := 8 
 );
 PORT 
 ( 
   clock           : IN  std_logic;
	framesync_input : IN  std_logic;
	rowsync_input   : IN  std_logic;
	pixeldata_input : IN  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	framesync_output : OUT std_logic;
	rowsync_output   : OUT std_logic;
	pixeldata_output : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0)
 );
END LBPKernel;

ARCHITECTURE behavioral OF LBPKernel IS

	SIGNAL centerpixel			 :  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);	
	SIGNAL npixel1 	 			 :  std_logic_vector(DATA_WIDTH-1 DOWNTO 0); 
	SIGNAL npixel2 				 :  std_logic_vector(DATA_WIDTH-1 DOWNTO 0); 
	SIGNAL npixel3 				 :  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);  
	SIGNAL npixel4 				 :  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	SIGNAL npixel5 				 :  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	SIGNAL npixel6 				 :  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	SIGNAL npixel7 				 :  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	SIGNAL npixel8 				 :  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
	SIGNAL framesync_integrated :  std_logic;
	SIGNAL rowsync_integrated   :  std_logic; 
	
	BEGIN

	CacheSystem : ENTITY work.CacheSystem GENERIC MAP ( DATA_WIDTH => DATA_WIDTH, WINDOW_SIZE	=> 3, ROW_BITS => 9,
																		 COL_BITS => 10, NO_OF_ROWS => 480, NO_OF_COLS => 640 )
													  
													  PORT MAP( clock => clock, framesync_input => framesync_input, rowsync_input => rowsync_input, pixeldata_input => pixeldata_input, 
		                                             framesync_output => framesync_integrated, rowsync_output => rowsync_integrated, centerpixel => centerpixel, 
		                                             npixel1 => npixel1, npixel2 => npixel2, npixel3 => npixel3, npixel4 => npixel4, npixel5 => npixel5, npixel6 => npixel6, 
																	npixel7 => npixel7, npixel8 => npixel8	);
	
	Kernel: ENTITY work.LBPoperator GENERIC MAP ( DATA_WIDTH => DATA_WIDTH)
	
	                                PORT MAP( pixelclock_input => clock, framesync_input => framesync_integrated, rowsync_input => rowsync_integrated,
												         centerpixel => centerpixel, npixel1 => npixel1, npixel2 => npixel2, npixel3 => npixel3, npixel4 => npixel4,
															npixel5 => npixel5, npixel6 => npixel6, npixel7 => npixel7, npixel8 => npixel8, framesync_output => framesync_output,
															rowsync_output => rowsync_output, pixeldata_output => pixeldata_output );

end behavioral;
