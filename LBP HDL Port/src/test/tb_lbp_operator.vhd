library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
     
library work;
    use work.pm_lib.all;

entity tb_lbp_operator is 
end tb_lbp_operator;

architecture tb of tb_lbp_operator is 
    constant clk_period : time := 10 ns;

    signal clk,  rst        : std_logic := '0';

    signal center          : byte_t;
    signal neighborhood    : byte_array_t(7 downto 0);
    signal dout            : byte_t;
begin

    uut : entity work.lbp_operator 
    port map
    (
        clk             => clk,
        rst             => rst,

        center          => center,
        neighborhood    => neighborhood,
        dout            => dout
    );

    clk_gen : process
    begin
        wait for clk_period / 2;
        clk <= not clk;
    end process;

    main : process
    begin        

        wait until rising_edge(clk);

        rst <= '1';
        wait until rising_edge(clk);
        --assert dout = x"0000" report "reset failed" severity warning;
        rst <= '0';

        -- testcase: all neighbors < center ----------------------------------------        

        wait until rising_edge(clk);

        center <= x"7F"; -- 127
        neighborhood <= 
        (
            0 => x"00",
            1 => x"00",
            2 => x"00",
            3 => x"00",
            4 => x"00",
            5 => x"00",
            6 => x"00",
            7 => x"00"
        );

        wait for 15 ns;
        assert dout = x"00" report "dout should be 0x0";

        -- testcase : all neighbors > center -----------------------------------
        wait until rising_edge(clk);

        center <= x"7F"; -- 127
        neighborhood <= 
        (
            0 => x"FF",
            1 => x"FF",
            2 => x"FF",
            3 => x"FF",
            4 => x"FF",
            5 => x"FF",
            6 => x"FF",
            7 => x"FF"
        );

        wait for 15 ns;
        assert dout = x"FF" report "dout should be 0xFF";

        -- testcase : all neighbors = center -----------------------------------
        wait until rising_edge(clk);

        center <= x"7F"; -- 127
        neighborhood <= 
        (
            0 => x"7F",
            1 => x"7F",
            2 => x"7F",
            3 => x"7F",
            4 => x"7F",
            5 => x"7F",
            6 => x"7F",
            7 => x"7F"
        );

        wait for 15 ns;
        assert dout = x"FF" report "dout should be 0xFF";

        -- testcase : some neighbors > center -----------------------------------
        wait until rising_edge(clk);

        center <= x"7F"; -- 127
        neighborhood <= 
        (
            0 => x"00",
            1 => x"7F",
            2 => x"7F",
            3 => x"7F",
            4 => x"7F",
            5 => x"7F",
            6 => x"7F",
            7 => x"00"
        );

        wait for 15 ns;
        assert dout = x"7E" report "dout should be 0x7E";

        -- testcase :  [0 0 0 ff ff ff 0 0] >= center -----------------------------------
        wait until rising_edge(clk);

        center <= x"FF"; -- 255
        neighborhood <= 
        (
            0 => x"00",
            1 => x"00",
            2 => x"FF",
            3 => x"FF",
            4 => x"FF",
            5 => x"00",
            6 => x"00",
            7 => x"00"
        );

        wait for 15 ns;
        assert dout = x"1C" report "dout should be 0x1C";

    end process;
end tb;