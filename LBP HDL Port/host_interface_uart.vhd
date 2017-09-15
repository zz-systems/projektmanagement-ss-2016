library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library work;
    use work.pm_lib.all;

entity host_interface_uart is
port
(
    clk     : in std_logic;
    rst     : in std_logic;    

    -- device interface --------------------------------------------------------
    din     : in byte_t;
    dout    : out byte_t;
    we      : in std_logic;
    davail  : out std_logic;
    busy    : out std_logic;

    -- uart interface ----------------------------------------------------------
    rx : in std_logic;
    tx : out std_logic
);
end host_interface_uart;

architecture rtl of host_interface_uart is
begin

    UART : uart 
    generic map
    (
        baud                => 115200,
        clock_frequency     => 50 * 1000 * 1000
    )
    port map
    (
        clock               => clk,
        reset               => rst,

        data_stream_in      => din,
        data_stream_in_stb  => we,
        data_stream_in_ack  => busy,

        data_stream_out     => dout,
        data_stream_out_stb => davail,

        tx                  => tx,
        rx                  => rx
    );

end rtl;

