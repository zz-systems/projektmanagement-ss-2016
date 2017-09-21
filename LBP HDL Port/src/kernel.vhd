library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.pm_lib.all;

entity kernel is
    generic
    (
        kernel_col, kernel_row      : natural := 0;
        kernel_cols, kernel_rows    : positive := 64;

        radius                      : positive := 1
    );
    port
    (
        clk, rst    : in std_logic;

        col, row    : out word_t;

        din         : in byte_array_t(8 downto 0);
        dout        : out byte_t;

        busy        : out std_logic;

        enable      : in std_logic
    );
end kernel;

architecture RTL of kernel is
    signal neighborhood : byte_array_t(7 downto 0);
    signal center       : byte_t;

    signal cur_col, cur_row : integer;

    signal halt : std_logic := '0';
begin
    process(clk, rst)
    begin
        if rst = '1' then

            cur_col     <= 0;
            cur_row     <= 0;
            halt        <= '0';

        elsif rising_edge(clk) then

            if enable = '1' and halt = '0' then
                if cur_col < kernel_cols - 1 then
                    cur_col     <= cur_col + 1;
                elsif cur_row < kernel_rows - 1 then 
                    cur_row     <= cur_row + 1;
                    cur_col     <= 0;
                else 
                    halt        <= '1';
                end if;
            end if;
            
        end if;
    end process;

    busy    <= enable and not halt;

    col     <= std_logic_vector(to_unsigned(kernel_col * kernel_cols + cur_col, col'length));
    row     <= std_logic_vector(to_unsigned(kernel_row * kernel_rows + cur_row, row'length));

    --R1 : if radius = 1 generate
    --    center          <= din(0)(0); 

    --    neighborhood(0) <= din(-1)(-1); -- top left
    --    neighborhood(1) <= din( 0)(-1); -- top center
    --    neighborhood(2) <= din( 1)(-1); -- top right

    --    neighborhood(3) <= din( 1)( 0); -- center right

    --    neighborhood(4) <= din( 1)( 1); -- bottom right
    --    neighborhood(5) <= din( 0)( 1); -- bottom center
    --    neighborhood(6) <= din(-1)( 1); -- bottom left

    --    neighborhood(7) <= din(-1)( 0); -- center left
    --end generate;

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

    LBPO : entity work.lbp_operator
    port map
    (
        clk             => clk,
        rst             => rst,

        center          => din(0),
        neighborhood    => din(8 downto 1),
        dout            => dout
    );

end RTL;
