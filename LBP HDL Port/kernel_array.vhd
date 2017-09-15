library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library work;
    use work.pm_lib.all;

entity kernel_array is
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
end kernel_array;

architecture rtl of kernel_array is

    constant kernels : natural := kernels_x * kernels_y;

    constant kernel_cols    : natural := cols / kernels_x;
    constant kernel_rows    : natural := rows / kernels_y;

    signal kbusy            : unsigned(kernels - 1 downto 0);
begin
    -- generate N kernels ------------------------------------------------------
    for kx in 0 to kernels_x - 1 generate
        for ky in 0 to kernels_y - 1 generate
            -- kernel index
            constant ki : natural := kx * kernels_x + ky; 
        begin

            KERNEL : kernel 
            generic map
            (
                kernel_col  => kx,
                kernel_row  => ky,

                kernel_cols => kernel_cols,
                kernel_rows => kernel_rows,

                radius      => radius
            )
            port map
            (
                clk         => clk,
                rst         => rst,

                row         => row_addr(ki),
                col         => col_addr(ki),

                din         => din(ki),
                dout        => dout(ki),

                busy        => kbusy(ki)
            );

        end generate;
    end generate;

    busy <= kbusy /= 0;
end rtl;
