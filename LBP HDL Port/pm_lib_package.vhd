library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;


package pm_lib is
begin
    type byte_t is std_logic_vector(7 downto 0);
    type word_t is std_logic_vector(16 downto 0);

    type byte_array_t is array(natural range<>) of byte_t;
    type word_array_t is array(natural range<>) of word_t;

    component lbp_operator
    generic (
        DATA_WIDTH : integer := 8
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        center    : in  byte_t;
        neighbors : in  byte_array_t(7 downto 0);
        dout      : out byte_t
    );
    end component lbp_operator;
end package;
