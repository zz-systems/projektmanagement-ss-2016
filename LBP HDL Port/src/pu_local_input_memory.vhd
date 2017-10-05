library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;	
	use ieee.numeric_std.all;
	 
library work;
    use work.pm_lib.all;

entity pu_local_input_memory is
generic
(
    ports : positive := 1;

    mem_w : positive := 256;
    mem_h : positive := 256;
    radius : positive := 1
);
port
(
    clk     : in std_logic;
    rst     : in std_logic;

    row     : in word_array_t       (ports - 1 downto 0);
    col     : in word_array_t       (ports - 1 downto 0);

    we      : in std_logic_vector   (ports - 1 downto 0);

    din     : in byte_array_t       (ports - 1 downto 0);

    -- for each port: window with 9 entries
    dout    : out byte_array_t      (ports * 9 - 1 downto 0);
    
    davail  : out std_logic_vector(ports - 1 downto 0)
);
end pu_local_input_memory;

architecture rtl of pu_local_input_memory is      
    signal icol : int_array_t(col'range);
    signal irow : int_array_t(row'range);
    
    signal address : word_array_t(ports - 1 downto 0);
    subtype ports_range 	is integer range -radius to radius;	 
    subtype bank_range      is integer range 0 to (mem_w * mem_h / 2048) - 1;
    
    signal mem_din, mem_dout : byte_array_t(bank_range);     
begin
    icol <= to_uint_array(col);
    irow <= to_uint_array(row);
    
    GPORT : for i in ports - 1 downto 0 generate  
        signal cur_col, cur_col_s : integer;
        signal cur_row, cur_row_s : integer; 
        signal bank : natural range 0 to 31 := to_integer(unsigned(address(i)(15 downto 11)));
    begin
        GRAM: for j in bank_range generate
            IRAM : entity work.ram 
            port map
            (
                clk         => clk,
                enable      => '1' ,
                we          => we(0),
                address     => address(i)(10 downto 0),
                data_write  => mem_din(j),
                data_read   => mem_dout(j)
            );
        end generate;
        
        process(clk, rst)
        begin
            if rst then
                cur_col     <= -1;
                cur_row     <= -1;
                davail(i)   <= '0';
                --dout    <= (others => (others => (others => (others => '0'))));               
                
            elsif rising_edge(clk) then
                
                -- write to all
                if we(i) then
                    address(i) <= word_t(to_unsigned((irow(i) + radius) * mem_w + (icol(i) + radius), address'length));                   
                    mem_din(bank) <= din(i);
                end if;

                
                if cur_col < 2 then
                    davail(i)   <= '0';
                    cur_col     <= cur_col + 1;
                elsif cur_row < 2 then 
                    davail(i)   <= '0';
                    cur_row     <= cur_row + 1;
                    cur_col     <= 0;
                else 
                    davail(i)   <= '1';
                end if;
                
                address(i) <= word_t(to_unsigned((irow(i) + radius * cur_row) * mem_w + (icol(i) + radius * cur_col), address'length));
                dout(i * 9 + (cur_row * 3 + cur_col)) <= mem_dout(bank);
                --dout(i)(cur_col)(cur_row) <= mem_dout(bank);
                --for x in -radius to radius loop
                --    for y in -radius to radius loop
                --        dout(i)(x)(y) <= mem((irow(i) + radius + y) * mem_w + (icol(i) + radius + x));
                --    end loop;
                -- end loop;

            end if;
        end process;
    end generate;
end rtl;
