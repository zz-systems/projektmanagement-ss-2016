library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    
library work;
    use work.pm_lib.all;

entity qsys_lbp is  
generic 
(
    cols        : positive := 256;
	rows        : positive := 256;

	radius 		: positive := 1;

	kernels_x 	: positive := 1;
	kernels_y 	: positive := 1
);
port 
(
	clk, rst   : in std_logic;
    read, write, chipselect  : in std_logic;

    writedata   : in std_logic_vector(31 downto 0);
    byteenable  : in std_logic_vector(3 downto 0);
    
    readdata    : out std_logic_vector(31 downto 0);
    
    irq : out std_logic
);
end qsys_lbp;


architecture rtl of qsys_lbp is
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
    host_davail     <= write and chipselect and byteenable(0);
    irq             <= host_we;
    
    host_din        <= writedata(7 downto 0);
    readdata        <= (31 downto 8 => '0') & std_logic_vector(host_dout) when read else 
                       (others => '0');
    
    host_busy       <= '0';
    
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
		margin 		=> radius,

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
    
end rtl;