library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
     
library work;
    use work.pm_lib.all;

entity tb_lbp_kernel is 
end tb_lbp_kernel;

architecture tb of tb_lbp_kernel is 
    constant clk_period : time := 10 ns;

    constant kernel_col, kernel_row     : natural := 0;
    constant kernel_cols, kernel_rows   : positive := 3;

    constant radius                     : positive := 1;

    constant mem_w      : positive := 3;
    constant mem_w_b    : positive := mem_w + 2 * radius;

    signal clk,  rst        : std_logic := '0';    

    signal col, row         : word_t;
    signal icol, irow    : integer := 0;

    signal din         : byte_array_t(8 downto 0);
    signal dout        : byte_t;

    signal busy, enable : std_logic;

    -- input memory with margin (3x3 data => 5x5 data + margin)
    signal mem_in : byte_array_t(0 to 24);
    -- output memory (3x3 + 1 data)
    signal mem_out : byte_array_t(0 to 9);  
    
    constant mem_out_ref : byte_array_t(0 to 8) := 
    (
        0 => x"1C",
        1 => x"1C",
        2 => x"10",

        3 => x"1E",
        4 => x"16",
        5 => x"00",

        6 => x"06",
        7 => x"02",
        8 => x"FF"
    );
begin

    uut : entity work.kernel 
    generic map
    (
        kernel_col => kernel_col,
        kernel_row => kernel_row,

        kernel_cols => kernel_cols,
        kernel_rows => kernel_rows,

        radius => radius
    )
    port map
    (
        clk  => clk,
        rst  => rst,

        col  => col,
        row  => row,

        din  => din,
        dout => dout,
        busy => busy,

        enable => enable
    );

    -- store current address 
    icol <= to_integer(unsigned(col));
    irow <= to_integer(unsigned(row));

    clk_gen : process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;

    main : process
    begin        

        wait until rising_edge(clk);

        -- 00 00 00 00 00
        -- 00 01 02 03 00
        -- 00 04 05 06 00
        -- 00 07 08 00 00
        -- 00 00 00 00 00

        mem_in <= 
        (
            0 => x"00",
            1 => x"00",
            2 => x"00",
            3 => x"00",
            4 => x"00",

            5 => x"00",
            6 => x"01",
            7 => x"04",
            8 => x"07",
            9 => x"00",

            10 => x"00",
            11 => x"02",
            12 => x"05",
            13 => x"08",
            14 => x"00",

            15 => x"00",
            16 => x"03",
            17 => x"06",
            18 => x"00",
            19 => x"00",

            20 => x"00",
            21 => x"00",
            22 => x"00",
            23 => x"00",
            24 => x"00"
        );

        -- 00 00 00 
        -- 00 00 00 
        -- 00 00 00 
        mem_out <= (others => (others => '0'));

        rst <= '1';
        wait until rising_edge(clk);
        rst <= '0';

        -- enable kernel
        enable <= '1';

        for y in 0 to 2 loop
            for x in 0 to 2 loop 
                -- wait for address
                wait until rising_edge(clk);                
                -- verify address
                assert busy = '1'   report "kernel should be busy when processing";
                assert icol = x     report "column address does not match, expected: " & integer'image(x) & " actual: " & integer'image(icol);
                assert irow = y     report "row address does not match, expected: " & integer'image(y) & " actual: " & integer'image(irow);
               
                -- write data
                -- center 
                din(0) <= mem_in((irow + radius) * mem_w_b + (icol + radius));

                 -- top left
                din(8) <= mem_in((irow + radius * (-1 + 1)) * mem_w_b + (icol + radius *(-1 + 1)));
                -- top center
                din(7) <= mem_in((irow + radius * ( 0 + 1)) * mem_w_b + (icol + radius *(-1 + 1)));
                 -- top right
                din(6) <= mem_in((irow + radius * ( 1 + 1)) * mem_w_b + (icol + radius *(-1 + 1)));

                 -- center right
                din(5) <= mem_in((irow + radius * ( 1 + 1)) * mem_w_b + (icol + radius *( 0 + 1)));

                -- bottom right
                din(4) <= mem_in((irow + radius * ( 1 + 1)) * mem_w_b + (icol + radius *( 1 + 1)));
                 -- bottom center 
                din(3) <= mem_in((irow + radius * ( 0 + 1)) * mem_w_b + (icol + radius *( 1 + 1)));
                 -- bottom left
                din(2) <= mem_in((irow + radius * (-1 + 1)) * mem_w_b + (icol + radius *( 1 + 1)));


                -- center left
                din(1) <= mem_in((irow + radius * (-1 + 1)) * mem_w_b + (icol + radius *( 0 + 1))); 
                
                -- store result                
                mem_out(irow * mem_w + icol) <= dout;
            end loop;
        end loop;

        wait until rising_edge(clk);

        -- store last element (offset 1)
        mem_out((irow) * mem_w + (icol + 1)) <= dout;

        wait until rising_edge(clk);
        assert busy = '0' report "kernel should not be busy when idle";

        if mem_out(1 to 9) /= mem_out_ref then
        for i in mem_out_ref'range loop
            report "index: "
                & integer'image(i)
                & " out: "  
                & integer'image(to_integer(unsigned(mem_out(1 + i))))
                & " ref: "    
                & integer'image(to_integer(unsigned(mem_out_ref(i))));

        end loop;
        report "output does not match" severity error;
        end if;

        enable <= '0';
    end process;
end tb;