library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
library UNISIM;
    use UNISIM.vcomponents.all;
    
entity ram is 
    port
    (
        clk         : in std_logic;
        enable      : in std_logic;
        we          : in std_logic;
        address     : in std_logic_vector(10 downto 0);
        data_write  : in std_logic_vector(7 downto 0);
        data_read   : out std_logic_vector(7 downto 0)
    );
end ram;

architecture rtl of ram is
begin
    ram_block : RAMB16_S9
    port map
    (
        DO   => data_read,
        DOP  => open, 
        ADDR => address,
        CLK  => clk, 
        DI   => data_write,
        DIP  => "0",
        EN   => enable,
        SSR  => '0',
        WE   => we
    );
end;