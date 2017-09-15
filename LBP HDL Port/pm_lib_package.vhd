library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;


package pm_lib is
begin
    -- types -------------------------------------------------------------------
    subtype byte_t is std_logic_vector(7 downto 0);
    subtype word_t is std_logic_vector(16 downto 0);

    type byte_array_t   is array(natural range<>) of byte_t;
    type byte_array2d_t is array(natural range<>, natural range<>) of byte_t;
    type byte_array3d_t is array(natural range<>, natural range<>, natural range<>) of byte_t;

    type word_array_t   is array(natural range<>) of word_t;

    -- commands ----------------------------------------------------------------
    type commands    is (init, ack, ttd, proc, tth, invop);

    function decode_cmd(raw_cmd : byte_t) return commands;
    function encode_cmd(cmd : commands) return byte_t;

    -- components --------------------------------------------------------------    
    component lbp_operator is
    port
    (
        clk : in std_logic;
        rst : in std_logic;

        center          : in byte_t;
        neighborhood    : in byte_array_t(7 downto 0);
        dout            : out byte_t
    );
    end component;

    component kernel is
    generic
    (
        kernel_col, kernel_row      : integer := 0;
        kernel_cols, kernel_rows    : integer := 64;

        radius                      : integer := 1
    );
    port
    (
        clk : in std_logic;
        rst : in std_logic;

        col, row : out word_t;

        din : in byte_array2d_t(-window_size to window_size, -window_size to window_size);
        dout : out byte_t;

        busy : out std_logic
    );
    end component;

    component kernel_array is
    generic
    (
        kernels_x   : natural := 1;
        kernels_y   : natural := 1;

        cols        : natural := 256;
        rows        : natural := 256;

        radius      : natural := 1
    );
    port
    (
        clk         : in std_logic;
        rst         : in std_logic;

        row_addr    : out word_array_t      (kernels_x * kernels_y - 1 downto 0);
        col_addr    : out word_array_t      (kernels_x * kernels_y - 1 downto 0);

        din         : in byte_array_t       (kernels_x * kernels_y - 1 downto 0);
        dout        : out byte_array_t      (kernels_x * kernels_y - 1 downto 0)
    );
    end component;

    component pu_local_input_memory is
    generic
    (
        ports : integer := 1;

        mem_w : integer := 256;
        mem_h : integer := 256;
        radius : integer := 1;
        margin : integer := 1
    );
    port
    (
        clk     : in std_logic;
        rst     : in std_logic;

        row     : in word_array_t       (ports - 1 downto 0);
        col     : in word_array_t       (ports - 1 downto 0);

        we      : in std_logic_vector   (ports - 1 downto 0);

        din     : in byte_array_t       (ports - 1 downto 0);
        dout    : out byte_array3d_t    (ports - 1 downto 0, -radius to radius, -radius to radius)
    );
    end component;

    component pu_local_output_memory is
    generic
    (
        ports : integer := 1;

        mem_w : integer := 256;
        mem_h : integer := 256
    );
    port
    (
        clk     : in std_logic;
        rst     : in std_logic;

        row     : in word_array_t       (ports - 1 downto 0);
        col     : in word_array_t       (ports - 1 downto 0);
        
        we      : in std_logic_vector   (ports - 1 downto 0);

        din     : in byte_array_t       (ports - 1 downto 0);
        dout    : out byte_array_t      (ports - 1 downto 0)
    );
    end component;

    component processing_unit is  
    generic
    (
        constant cols : integer := 256;
        constant rows : integer := 256;

        constant radius         : integer := 1;
        constant margin         : integer := 1;

        constant kernels_x      : integer := 1;
        constant kernels_y      : integer := 1
    );
    port 
    (
        clk : in std_logic;
        rst : in std_logic;

        -- memory interface --------------------------------------------------------
        row    : in word_t;
        col    : in word_t;

        din     : in byte_t;
        dout    : out byte_t;
        we      : in std_logic;

        -- pu control signals ------------------------------------------------------
        enable  : in std_logic;
        busy    : out std_logic
    );
    end component;

    component control_unit is
    port
    (
        clk             : in std_logic;
        rst             : in std_logic;

        -- memory interface --------------------------------------------------------
        row             : out word_t;
        col             : out word_t;

        mem_din         : in byte_t;
        mem_dout        : out byte_t;
        mem_we          : out std_logic;

        -- host interface ----------------------------------------------------------
        host_din        : in std_logic;
        host_dout       : out std_logic;
        host_we         : out std_logic;
        host_davail     : in std_logic;
        host_busy       : in std_logic;

        -- processing unit control signals -----------------------------------------
        pu_reset        : out std_logic;
        pu_enable       : out std_logic;
        pu_busy         : in std_logic
    );
    end component;


    component host_interface_uart is
    port
    (
        clk     : in std_logic;
        rst     : in std_logic;    

        -- device interface --------------------------------------------------------
        din     : in byte_t;
        dout    : out byte_t;
        we      : in std_logic;
        davail  : out std_logic;
        busy    : out std_logic;

        -- uart interface ----------------------------------------------------------
        rx : in std_logic;
        tx : out std_logic
    );
    end component;


end package;

package body pm_lib is 
begin
    function decode_cmd(raw_cmd : byte_t) return commands is     
    begin
        case raw_cmd is 
            when x"0F" => return init;
            when x"0E" => return ack;
            when x"0D" => return ttd;
            when x"0C" => return tth;
            when x"0B" => return proc;

            when others => return invop;
        end case;
    end function;

    function encode_cmd(cmd : commands) return byte_t is
    begin
        case cmd is 
            when init   => return x"0F";
            when ack    => return x"0E";
            when ttd    => return x"0D";
            when tth    => return x"0C";
            when proc   => return x"0B";

            when invop  => return x"00";
        end case;
    end function;
end package body;
