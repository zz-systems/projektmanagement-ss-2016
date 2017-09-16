library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;	
	 use ieee.numeric_std.all;
	 
library work;
    use work.pm_lib.all;

entity pu_local_input_memory is
generic
(
    ports : integer := 1;

    mem_w : integer := 256;
    mem_h : integer := 256;
    radius : integer := 1;
    margin : integer := 1
);
port
(
    clk     : in std_logic;
    rst     : in std_logic;

    row     : in word_array_t       (ports - 1 downto 0);
    col     : in word_array_t       (ports - 1 downto 0);

    we      : in std_logic_vector   (ports - 1 downto 0);

    din     : in byte_array_t       (ports - 1 downto 0);
    dout    : out byte_array3d_t    (ports - 1 downto 0)(-radius to radius)(-radius to radius)
);
end pu_local_input_memory;

architecture rtl of pu_local_input_memory is    
    signal mem : byte_array_t(0 to (mem_w + margin * 2) * (mem_h + margin * 2) - 1);
    
    signal icol : int_array_t(col'range);
    signal irow : int_array_t(row'range);
begin
    icol <= to_uint_array(col);
    irow <= to_uint_array(row);
    
    GPORT : for i in ports - 1 downto 0 generate  
        process(clk, rst)
        begin
            if rst then
                mem     <= (others => (others => '0'));
                dout    <= (others => (others => (others => (others => '0'))));
            elsif rising_edge(clk) then
            
                if we(i) then
                    mem((irow(i) + margin) * mem_w + (icol(i) + margin)) <= din(i);
                end if;

                for x in -radius to radius loop
                    for y in -radius to radius loop
                        dout(i)(x)(y) <= mem((irow(i) + margin + y) * mem_w + (icol(i) + margin + x));
                    end loop;
                end loop;

            end if;
        end process;
    end generate;
end rtl;
