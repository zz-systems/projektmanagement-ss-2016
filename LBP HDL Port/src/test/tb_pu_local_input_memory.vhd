library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
     
library work;
    use work.pm_lib.all;

entity tb_pu_local_input_memory is 
end tb_pu_local_input_memory;

architecture tb of tb_pu_local_input_memory is 
    constant clk_period : time := 10 ns;

    constant kernels        : positive := 1;
    constant mem_w, mem_h   : positive := 3;

    constant radius          : positive := 1;

    subtype kernels_range is natural range kernels - 1 downto 0;
    
    signal clk,  rst        : std_logic := '0';

    signal col, row         : word_array_t(kernels_range);
    signal icol, irow       : int_array_t(kernels_range);

    signal we       : std_logic_vector(kernels_range);
    signal din      : byte_array_t(kernels_range);
    signal dout     : byte_array_t(kernels * 9 - 1 downto 0);

    signal davail   : std_logic_vector(kernels_range);

    signal counter : integer := 0;    
begin

    uut : entity work.pu_local_input_memory 
    generic map
    (
        ports => kernels,

        mem_w => mem_w,
        mem_h => mem_h,

        radius => radius
    )
    port map
    (
        clk  => clk,
        rst  => rst,

        col  => col,
        row  => row,

        we => we,

        din  => din,
        dout => dout,

        davail => davail
    );

    -- store current address 
    icol <= to_uint_array(col);
    irow <= to_uint_array(row);

    clk_gen : process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;

    main : process
    begin        

        wait until rising_edge(clk);        

        rst <= '1';
        counter <= 0;
        wait until rising_edge(clk);
        rst <= '0';

        
        -- write data
        for y in 0 to 2 loop
            for x in 0 to 2 loop 
                col(0) <= std_logic_vector(to_unsigned(x, col(0)'length));
                row(0) <= std_logic_vector(to_unsigned(y, row(0)'length));

                din(0)  <= std_logic_vector(to_unsigned(counter, din(0)'length));
                we(0)   <= '1';

                counter <= counter + 1;

                wait until rising_edge(clk);
            end loop;
        end loop;


        counter <= 0;

        wait until rising_edge(clk);

        -- read data
        for y in 0 to 2 loop
            for x in 0 to 2 loop 
                col(0) <= std_logic_vector(to_unsigned(x, col(0)'length));
                row(0) <= std_logic_vector(to_unsigned(y, row(0)'length));                

                counter <= counter + 1;

                wait until rising_edge(clk);

                assert dout(0) = std_logic_vector(to_unsigned(counter, 8)) report " out: "  ;
                    --& integer'image(to_integer(unsigned(dout(0)))
                    --& " ref: "    
                    --& integer'image(counter); 

                wait until rising_edge(clk);
            end loop;
        end loop;

       
    end process;
end tb;