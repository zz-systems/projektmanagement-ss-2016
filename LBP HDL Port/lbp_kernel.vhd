library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library work;
    use work.pm_lib.all;

entity lbp_kernel is
    generic
    (
        neighbors_count : integer := 8;
        x, y            : integer := 0;
        area_size_x     : integer := 128;
        area_size_y     : integer := 128
    );
    port
    (
        clk : in std_logic;
        rst : in std_logic;

        addr : out word_t;
        din : in byte_t;
        dout : out byte_t
    );
end lbp_kernel;

architecture RTL of lbp_kernel is
begin

end RTL;
