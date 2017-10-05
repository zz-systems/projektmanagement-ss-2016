library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

entity qsys_lbp_top is  
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
	clk, reset    : in std_logic;
    read, write, chipselect  : in std_logic;

    writedata   : in std_logic_vector(31 downto 0);
    byteenable  : in std_logic_vector(3 downto 0);
    
    readdata    : out std_logic_vector(31 downto 0);
    irq         : out std_logic    
);
end qsys_lbp_top;


architecture rtl of qsys_lbp_top is
    
    component qsys_lbp is  
    generic 
    (
        cols        : integer := 256;
        rows        : integer := 256;

        radius 		: integer := 1;

        kernels_x 	: integer := 1;
        kernels_y 	: integer := 1
    );
    port 
    (
        clk, rst    : in std_logic;
        read, write, chipselect  : in std_logic;

        writedata   : in std_logic_vector(31 downto 0);
        byteenable  : in std_logic_vector(3 downto 0);
        
        readdata    : out std_logic_vector(31 downto 0);
        irq         : out std_logic    
    );
    end component;

begin
    U0 : qsys_lbp
    generic map
    (
        cols => cols,
        rows => rows,
        
        radius => radius,
        
        kernels_x => kernels_x,
        kernels_y => kernels_y
    )
    port map
    (
        clk => clk,
        rst => reset,
        
        read => read,
        write => write,
        chipselect => chipselect,
        
        writedata => writedata,
        byteenable => byteenable,
        
        readdata => readdata,
        irq => irq       
    );
end rtl;