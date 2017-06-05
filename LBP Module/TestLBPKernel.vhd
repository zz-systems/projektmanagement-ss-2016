LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std;
 
ENTITY TestLBPKernel IS
END TestLBPKernel;
 
ARCHITECTURE behavioral OF TestLBPKernel IS 
    COMPONENT LBPKernel
	 GENERIC 
	 (
		DATA_WIDTH	: integer := 8 
	 );
    PORT 
	 ( 
		clock            : IN  std_logic;
		framesync_input  : IN  std_logic;
		rowsync_input    : IN  std_logic;
		pixeldata_input  : IN  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
		framesync_output : OUT std_logic;
		rowsync_output   : OUT std_logic;
		pixeldata_output : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0)
	 );
    END COMPONENT;
    
   --Inputs
   SIGNAL clock      	  : std_logic := '0';
   SIGNAL framesync_input : std_logic := '0';
   SIGNAL rowsync_input   : std_logic := '0';
   SIGNAL pixeldata_input : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL reset    		  : std_logic := '0';

 	--Outputs
   SIGNAL framesync_output : std_logic;
   SIGNAL rowsync_output   : std_logic;
   SIGNAL pixeldata_output : std_logic_vector(7 DOWNTO 0);

   -- Clock period definitions
   CONSTANT clock_period : time := 10 ns;
 
   BEGIN
 
	aggregate : LBPKernel PORT MAP ( clock => clock, framesync_input => framesync_input, rowsync_input => rowsync_input, pixeldata_input => pixeldata_input,
													 framesync_output => framesync_output, rowsync_output => rowsync_output, pixeldata_output => pixeldata_output);

   img_read  : ENTITY work.ImageTestBench PORT MAP ( pixelclock_input => clock, resetclock_input => reset, framesync_input => framesync_output, rowsync_input => rowsync_output,		
																	pixeldata_input => pixeldata_output, columnsrgb_output => OPEN, rowsrgb_output => OPEN, columnsgray_output => OPEN, rowsgray_output => OPEN,
																	framesync_output => framesync_input, rowsync_output => rowsync_input, pixeldata_output => pixeldata_input);

	clock_generate : PROCESS (clock)
	CONSTANT T_pw : time := 50 ns;     
	BEGIN  
	IF clock = '0' THEN clock <= '1' AFTER T_pw, '0' AFTER 2*T_pw;
	END IF;
	END PROCESS clock_generate;
	reset <= '1', '0' AFTER 60 ns;

END;
