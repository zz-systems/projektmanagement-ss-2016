library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;


package pm_lib is
    -- types -------------------------------------------------------------------
    subtype byte_t is std_logic_vector(7 downto 0);
    subtype word_t is std_logic_vector(16 downto 0);

    type byte_array_t   is array(integer range<>) of byte_t;
    --type byte_array2d_t is array(integer range<>) of byte_array_t;
    --type byte_array3d_t is array(integer range<>) of byte_array2d_t;

    type word_array_t   is array(natural range<>) of word_t;
    
    type int_array_t    is array(natural range<>) of integer;

    subtype neighborhood_range  is natural range 7 * 8 - 1 downto 0; 
    subtype neighborhood        is std_logic_vector(neighborhood_range);

    -- commands ----------------------------------------------------------------
    type commands    is (init, ack, ttd, proc, tth, invop);

    function decode_cmd(raw_cmd : byte_t) return commands;
    function encode_cmd(cmd : commands) return byte_t;

    -- conversion --------------------------------------------------------------
    function to_std_logic(L: BOOLEAN) return std_ulogic;

    function to_uint_array(L : word_array_t) return int_array_t;


    function element(elements : std_logic_vector; index : integer) return byte_t;
    function element(elements : std_logic_vector; w : integer; col : integer; row : integer) return byte_t;

end package;

package body pm_lib is 
    function decode_cmd(raw_cmd : byte_t) return commands is     
    begin
        case raw_cmd is 
            when x"0F" => return init;
            when x"0E" => return ack;
            when x"0D" => return ttd;
            when x"0C" => return tth;
            when x"0B" => return proc;

            when others => return invop;
        end case;
    end function;

    function encode_cmd(cmd : commands) return byte_t is
    begin
        case cmd is 
            when init   => return x"0F";
            when ack    => return x"0E";
            when ttd    => return x"0D";
            when tth    => return x"0C";
            when proc   => return x"0B";

            when invop  => return x"00";
        end case;
    end function;

    function to_std_logic(L: BOOLEAN) return std_ulogic is
    begin
        if L then
            return('1');
        else
            return('0');
        end if;
    end function to_std_logic;

    function to_uint_array(L : word_array_t) 
        return int_array_t is
        variable result : int_array_t(L'range);
    begin
        for i in L'range loop
            result(i) := to_integer(unsigned(L(i)));
        end loop;

        return result;
    end function;

    function element(elements : std_logic_vector; index : integer) 
        return byte_t is 
    begin
        return elements((index + 1) * 8 - 1 downto (index * 8));
    end;

    function element(elements : std_logic_vector; w : integer; col : integer; row : integer) 
        return byte_t is 
        constant index : integer := (row * w + col);
    begin
        return elements((index - 1) * 8 to (index * 8));
    end;


end package body;
