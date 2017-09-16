library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.pm_lib.all;

entity kernel is
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

        din : in byte_array2d_t(-radius to radius)(-radius to radius);
        dout : out byte_t;

        busy : out std_logic
    );
end kernel;

architecture RTL of kernel is
    signal neighborhood : byte_array_t(7 downto 0);
    signal center       : byte_t;

    signal cur_col, cur_col_s : integer;
    signal cur_row, cur_row_s : integer;


begin
    process(clk, rst)
    begin
        if rst then

            cur_col_s   <= 0;
            cur_row_s   <= 0;

            cur_col     <= 0;
            cur_row     <= 0;

        elsif rising_edge(clk) then

            cur_col <= cur_col_s;
            cur_row <= cur_row_s;

            if cur_col < kernel_cols then
                cur_col_s   <= cur_col + 1;
            elsif cur_row < kernel_rows then 
                cur_row_s   <= cur_row + 1;
            end if;
            
        end if;
    end process;

    busy    <= to_std_logic(cur_col < kernel_cols) and to_std_logic(cur_row < kernel_rows);

    col     <= std_logic_vector(to_unsigned(kernel_col * kernel_cols + cur_col, col'length));
    row     <= std_logic_vector(to_unsigned(kernel_row * kernel_rows + cur_row, row'length));

    R1 : if radius = 1 generate
        center          <= din( 0)( 0);   

        neighborhood(0) <= din(-1)(-1); -- top left
        neighborhood(1) <= din( 0)(-1); -- top center
        neighborhood(2) <= din( 1)(-1); -- top right

        neighborhood(3) <= din( 1)( 0); -- center right

        neighborhood(4) <= din( 1)( 1); -- bottom right
        neighborhood(5) <= din( 0)( 1); -- bottom center
        neighborhood(6) <= din(-1)( 1); -- bottom left

        neighborhood(7) <= din(-1)( 0); -- center left
    end generate;

    --R2 : if radius = 2 generate
    --    center          <= din( 0)( 0);   

    --    neighborhood(0) <= din(-1)(-1); -- top left
    --    neighborhood(1) <= din( 0)(-1); -- top center
    --    neighborhood(2) <= din( 1)(-1); -- top right

    --    neighborhood(3) <= din( 1)( 0); -- center right

    --    neighborhood(4) <= din( 1)( 1); -- bottom right
    --    neighborhood(5) <= din( 0)( 1); -- bottom center
    --    neighborhood(6) <= din(-1)( 1); -- bottom left

    --    neighborhood(7) <= din(-1)( 0); -- center left
    --end generate;

    --R3 : if radius = 3 generate
    --    center          <= din( 0)( 0);   

    --    neighborhood(0) <= din(-1)(-1); -- top left
    --    neighborhood(1) <= din( 0)(-1); -- top center
    --    neighborhood(2) <= din( 1)(-1); -- top right

    --    neighborhood(3) <= din( 1)( 0); -- center right

    --    neighborhood(4) <= din( 1)( 1); -- bottom right
    --    neighborhood(5) <= din( 0)( 1); -- bottom center
    --    neighborhood(6) <= din(-1)( 1); -- bottom left

    --    neighborhood(7) <= din(-1)( 0); -- center left
    --end generate;

    LBPO : lbp_operator
    port map
    (
        clk             => clk,
        rst             => rst,

        center          => center,
        neighborhood    => neighborhood,
        dout            => dout
    );

end RTL;
