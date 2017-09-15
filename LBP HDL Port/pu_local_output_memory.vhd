library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library work;
    use work.pm_lib.all;

entity pu_local_output_memory is
generic
(
    ports : integer := 1;

    mem_w : integer := 256;
    mem_h : integer := 256
);
port
(
    clk     : in std_logic;
    rst     : in std_logic;

    row     : in word_array_t       (ports - 1 downto 0);
    col     : in word_array_t       (ports - 1 downto 0);
    
    we      : in std_logic_vector   (ports - 1 downto 0);

    din     : in byte_array_t       (ports - 1 downto 0);
    dout    : out byte_array_t      (ports - 1 downto 0)
);
end pu_local_output_memory;

architecture rtl of pu_local_output_memory is
    signal mem : byte_array2d_t(0 to mem_w, 0 to mem_h);
begin

    process(clk, rst)
    begin
        if rst then
            mem     <= (others => '0');
            dout    <= (others => '0');
        elsif rising_edge(clk) then

            for i in ports - 1 downto 0 loop
            begin
                if we(i) then
                    mem(col(i), row(i)) <= din(i);
                end if;

                dout(i) <= mem(col(i), row(i));
            end loop;
        end if;
    end process;
end rtl;
