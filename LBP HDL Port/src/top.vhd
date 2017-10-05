library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library work;
    use work.pm_lib.all;


entity lbp_standalone is  
generic 
(
    cols        : integer := 256;
	rows        : integer := 256;

	radius 		: integer := 1;
	margin 		: integer := 1;

	kernels_x 	: integer := 1;
	kernels_y 	: integer := 1
);
port 
(
	GCLK : in std_logic;
	RST : in std_logic;

	UART_RX : in std_logic;
	UART_TX : out std_logic
);
end lbp_standalone;


architecture rtl of lbp_standalone is
	-- generic config
--	constant cols : integer := 256;
--	constant rows : integer := 256;
--
--	constant radius 		: integer := 1;
--	constant margin 		: integer := 1;
--
--	constant kernels_x 		: integer := 1;
--	constant kernels_y 		: integer := 1;

	-- host interface ----------------------------------------------------------
	signal host_din 	: byte_t;
	signal host_dout 	: byte_t;
	signal host_we 		: std_logic;
	signal host_davail 	: std_logic;
	signal host_busy	: std_logic;

	-- memory interface --------------------------------------------------------
	signal mem_row    	:  word_t;
    signal mem_col    	:  word_t;

	signal mem_din 		:  byte_t;
	signal mem_dout 	:  byte_t;
	signal mem_we 		:  std_logic; 

	-- processing unit control signals -----------------------------------------
	signal pu_reset		: std_logic;
	signal pu_enable	: std_logic;
	signal pu_busy		: std_logic;

begin

	-- host interface ----------------------------------------------------------
	HIF : entity work.host_interface_uart
	port map
	(
		clk 	=> GCLK,
		rst 	=> RST,

		din 	=> host_dout,
		dout 	=> host_din,
		we 		=> host_we,
		davail 	=> host_davail,
		busy 	=> host_busy,

		rx 		=> UART_RX,
		tx 		=> UART_TX
	);

	-- control unit ------------------------------------------------------------
	CU : entity work.control_unit 
	port map
	(
		clk			=> GCLK,
		rst 		=> RST,

		-- memory interface --------------------------------------------------------
	    row 		=> mem_row,
	    col 		=> mem_col,

	    mem_din 	=> mem_din,
	    mem_dout 	=> mem_dout,
	    mem_we 		=> mem_we,

	    -- host interface ----------------------------------------------------------
	    host_din 	=> host_din,
	    host_dout 	=> host_dout,
	    host_we 	=> host_we,
	    host_davail => host_davail,
	    host_busy 	=> host_busy,

	    -- core control singals ----------------------------------------------------
	    pu_reset 	=> pu_reset,
	    pu_enable 	=> pu_enable,
	    pu_busy 	=> pu_busy
	);

	-- processing unit ---------------------------------------------------------
	PU : entity work.processing_unit 
	generic map
	(
		rows 		=> rows,
		cols 		=> cols,

		radius 		=> radius,
		margin 		=> margin,

		kernels_x 	=> kernels_x,
		kernels_y 	=> kernels_y
	)
	port map
	(
		clk 	=> GCLK,
		rst 	=> RST or pu_reset,

		-- memory interface ----------------------------------------------------
		row 	=> mem_row,
		col 	=> mem_col,

		din 	=> mem_dout,
		dout 	=> mem_din,
		we 		=> mem_we,

		-- pu control signals --------------------------------------------------
		enable 	=> pu_enable,
		busy 	=> pu_busy
	);

	
end architecture rtl;