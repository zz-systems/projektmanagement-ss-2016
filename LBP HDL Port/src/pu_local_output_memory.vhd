library ieee;
    use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;


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
    signal icol : int_array_t(col'range);
    signal irow : int_array_t(row'range);
    
    signal address : word_array_t(ports - 1 downto 0);
    
    subtype bank_range      is integer range 0 to (mem_w * mem_h / 2048) - 1;
        
    signal mem_din, mem_dout : byte_array_t(bank_range); 
begin

    icol <= to_uint_array(col);
    irow <= to_uint_array(row);
    
    GPORT : for i in ports - 1 downto 0 generate  
        signal bank : natural range 0 to 31 := to_integer(unsigned(address(i)(15 downto 11)));
    begin
        GRAM: for j in bank_range generate
            IRAM : entity work.ram 
            port map
            (
                clk         => clk,
                enable      => '1' ,
                we          => we(i),
                address     => address(i)(10 downto 0),
                data_write  => mem_din(j),
                data_read   => mem_dout(j)
            );
        end generate;
        
        process(clk, rst)
        begin
            if rst then
                dout    <= (others => (others => '0'));
                mem_din <= (others => (others => '0'));
                address <= (others => (others => '0'));
            elsif rising_edge(clk) then 
            
                address(i)      <= word_t(to_unsigned(irow(i) * mem_w + icol(i), address'length)); 
                
                if we(i) then                     
                    mem_din(bank)   <= din(i);
                end if;

                dout(i) <= mem_dout(bank);
            end if;
        end process;
    end generate;
end rtl;
