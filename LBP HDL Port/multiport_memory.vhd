library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

entity multiport_memory is
generic(
    ports_count : integer := 1;
    mem_size : integer := 256
);
port(
    clk     : in std_logic;
    rst     : in std_logic;

    addr    : in word_array_t(ports_count - 1 downto 0);
    re      : in std_logic_vector(ports_count - 1 downto 0);
    we      : in std_logic_vector(ports_count - 1 downto 0);
    din     : in word_array_t(ports_count - 1 downto 0);
    dout    : out word_array_t(ports_count - 1 downto 0)
);
end multiport_memory;

architecture rtl of multiport_memory is
    signal mem : byte_array_t(mem_size);
begin

    process(clk, rst)
    begin
        if rst then
        elsif rising_edge(clk) then

            for i in ports_count - 1 downto 0 loop
            begin
                if we(i) then
                    mem(addr(i)) <= din(i);
                end if;

                dout(i) <= mem(addr(i));
            end loop;

        end if;
    end process;
end rtl;
