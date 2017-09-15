library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library work;
    use work.pm_lib.all;


entity lbp_top_level is  
port 
(
	clk : in std_logic;
	rst : in std_logic;

	rx : in std_logic;
	tx : out std_logic
);
end lbp_top_level;


architecture rtl of lbp_top_level is
	-- generic config
	constant cols : integer := 256;
	constant rows : integer := 256;

	constant radius 		: integer := 1;
	constant margin 		: integer := 1;

	constant kernels_x 		: integer := 1;
	constant kernels_y 		: integer := 1;

	-- host interface ----------------------------------------------------------
	signal host_din 	: byte_t;
	signal host_dout 	: byte_t;
	signal host_we 		: boolean;
	signal host_davail 	: boolean;
	signal host_busy	: boolean;

	-- memory interface --------------------------------------------------------
	signal mem_row    	:  word_t;
    signal mem_col    	:  word_t;

	signal mem_din 		:  byte_t;
	signal mem_dout 	:  byte_t;
	signal mem_we 		:  boolean; 

	-- processing unit control signals -----------------------------------------
	signal pu_reset		: boolean;
	signal pu_enable	: boolean;
	signal pu_busy		: boolean;

begin

	-- host interface ----------------------------------------------------------
	HIF : host_interface_uart
	port map
	(
		clk 	=> clk,
		rst 	=> rst,

		din 	=> host_din,
		dout 	=> host_dout,
		we 		=> host_we,
		davail 	=> host_davail,
		busy 	=> host_busy,

		rx 		=> rx,
		tx 		=> tx
	);

	-- control unit ------------------------------------------------------------
	CU : control_unit 
	port map
	(
		clk			=> clk,
		rst 		=> rst,

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
	PU : processing_unit 
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
		clk 	=> clk,
		rst 	=> rst or pu_reset,

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