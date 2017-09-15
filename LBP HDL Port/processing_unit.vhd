library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library work;
    use work.pm_lib.all;


entity processing_unit is  
generic
(
	constant cols : integer := 256;
	constant rows : integer := 256;

	constant radius 		: integer := 1;
	constant margin 		: integer := 1;

	constant kernels_x 		: integer := 1;
	constant kernels_y 		: integer := 1
);
port 
(
	clk : in std_logic;
	rst : in std_logic;

	-- memory interface --------------------------------------------------------
	row    : in word_t;
    col    : in word_t;

	din 	: in byte_t;
	dout 	: out byte_t;
	we 		: in std_logic;

	-- pu control signals ------------------------------------------------------
	enable  : in std_logic;
	busy	: out std_logic
);
end processing_unit;


architecture rtl of processing_unit is
	-- generic config ----------------------------------------------------------
	constant kernels 		: integer := kernels_x * kernels_y;

	constant kernel_cols 	: integer := cols / kernels_x;
	constant kernel_rows 	: integer := rows / kernels_y;

	subtype kernels_range 	is natural range kernels - 1 downto 0;
	subtype radius_range 	is natural range -radius to radius;

	-- fsm ---------------------------------------------------------------------
	signal state : states := idle;

	-- adressing ---------------------------------------------------------------
	signal row_addr 	: word_array_t(kernels_range);
	signal col_addr 	: word_array_t(kernels_range);
	
	-- shared kernel input memory ----------------------------------------------
	signal kin_mem_we 	: std_logic_vector(kernels_range);

	signal kin_mem_din 	: byte_array_t(kernels_range);
	signal kin_mem_dout : byte_array3d_t(kernels_range, radius_range, radius_range)

	-- shared kernel output ----------------------------------------------------
	signal kout_mem_we 		: std_logic_vector(kernels_range);
	signal kout_mem_din 	: byte_array_t(kernels_range);
	signal kout_mem_dout 	: byte_t;

begin	
	-- bus mux -----------------------------------------------------------------
	if enable then
		row_addr <= krow_addr;
		col_addr <= kcol_addr;
		kin_mem_we <= (others => '0');
	else 
		row_addr(0) 	<= row; 
		col_addr(0) 	<= col;		
		kin_mem_din(0)	<= din; 

		kin_mem_we(0) 	<= we;  
		kin_mem_we(1 to kernels - 1) <= (others => '0');

		dout <= kout_mem_dout;
	end if;

	-- shared kernel input memory ----------------------------------------------
	KIN_MEM : pu_local_input_memory
	generic map
	(
		ports 	=> kernels,

		mem_w 	=> cols,
		mem_h 	=> rows,

		radius 	=> radius,
		margin 	=> margin
	)
	port map
	(
		clk 	=> clk,
		rst 	=> rst,

		row 	=> row_addr,
		col 	=> col_addr,

		we 		=> kin_mem_we,
		din 	=> kin_mem_din,
		dout 	=> kin_mem_dout
	);

	-- kernel array ------------------------------------------------------------
	KERNELS : kernel_array 
	generic map
	(
		kernels_x 	=> kernels_x,
		kernels_y 	=> kernels_y,

		cols 		=> cols,
		rows 		=> rows,

		radius 		=> radius
	)
	port map
	(
		clk 		=> clk,
		rst 		=> rst

		row_addr 	=> krow_addr,
		col_addr 	=> kcol_addr,

		din 		=> kin_mem_dout,
		dout 		=> kout_mem_din,

		busy 		=> busy
	);

	-- shared kernel output memory ---------------------------------------------
	KOUT_MEM : pu_local_output_memory
	generic map
	(
		ports 	=> kernels,

		mem_w 	=> cols,
		mem_h 	=> rows
	)
	port map
	(
		clk 	=> clk,
		rst 	=> rst,

		row 	=> row_addr,
		col 	=> col_addr,

		we 		=> kout_mem_we,
		din 	=> kout_mem_din,
		dout 	=> kout_mem_dout
	);
	
end architecture rtl;