library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library work;
    use work.pm_lib.all;

entity lbp_operator is
    port
    (
        clk : in std_logic;
        rst : in std_logic;

        center          : in byte_t;
        neighborhood    : in byte_array_t(7 downto 0);
        dout            : out byte_t
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
        lbp_s(i) <= neighborhood(i) >= center;
    end generate;

    dout <= lbp;

end RTL;
