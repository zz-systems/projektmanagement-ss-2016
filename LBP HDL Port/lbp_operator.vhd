library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library work;
    use work.pm_lib.all;

entity lbp_operator is
    generic
    (
        neighbors_count : integer := 8;
        data_width : integer := 8
    );
    port
    (
        clk : in std_logic;
        rst : in std_logic;

        center : in byte_t(data_width - 1 downto 0);
        neighbors : in byte_array_t(neighbors_count downto 0);

        dout : out byte_t(data_width - 1 downto 0)
    );
end lbp_operator;

architecture RTL of lbp_operator is
    signal lbp, lbp_s : std_logic_vector(dout'range);
begin
    process(clk, reset)
    begin
        if reset then
            lbp <= (others => '0');
        elsif rising_edge(clk) then
            lbp <= lbp_s;
        end if;
    end;

    lbp : for i in lbp'range generate
    begin
        lbp_s(i) <= neighbors(i) >= center;
    end generate;

    dout <= lbp;

end RTL;
