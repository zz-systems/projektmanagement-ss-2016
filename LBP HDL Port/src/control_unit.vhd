library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library work;
    use work.pm_lib.all;

entity control_unit is
port
(
    clk             : in std_logic;
    rst             : in std_logic;

    -- memory interface --------------------------------------------------------
    row             : out word_t;
    col             : out word_t;

    mem_din         : in byte_t;
    mem_dout        : out byte_t;
    mem_we          : out std_logic;

    -- host interface ----------------------------------------------------------
    host_din        : in byte_t;
    host_dout       : out byte_t;
    host_we         : out std_logic;
    host_davail     : in std_logic;
    host_busy       : in std_logic;

    -- processing unit control signals -----------------------------------------
    pu_reset        : out std_logic;
    pu_enable       : out std_logic;
    pu_busy         : in std_logic
);
end control_unit;

architecture rtl of control_unit is
    type states is (listen, rcv_cmd_init, rcv_cmd_ttd, rcv_cmd_tth, rcv_cmd_proc, rcv_data, rcv_col_hi, rcv_col_lo, rcv_row_hi, rcv_row_lo, snd_cmd_ack, snd_data);
    
    signal state, ret_state, ret_ret_state : states;  

    signal col_addr, row_addr : word_t;
begin

    process(clk, rst)
    begin
        if rst then
        elsif rising_edge(clk) then
            ret_state <= listen;
            mem_we      <= '0';
            case state is 

                -- listen to incoming commands ---------------------------------
                when listen => 
                    host_we <= '0';

                    if host_davail then                         
                        case decode_cmd(host_din) is
                            when init   => state <= rcv_cmd_init;
                            when ttd    => state <= rcv_cmd_ttd;
                            when tth    => state <= rcv_cmd_tth;
                            when proc   => state <= rcv_cmd_proc;
                            -- invalid cmd : ignore
                            when others => state <= listen;
                        end case;  
                    end if;

                -- inbound cmd: init. reset compute units ----------------------
                when rcv_cmd_init => 
                    pu_reset    <= '1';
                    pu_enable   <= '0'; 

                    state       <= snd_cmd_ack;
                    ret_state   <= listen;

                -- inbound cmd: transfer to device -----------------------------
                when rcv_cmd_ttd => 
                    state           <= snd_cmd_ack;
                    ret_state       <= rcv_col_hi;                
                    ret_ret_state   <= rcv_data;

                -- inbound cmd: transfer to host -------------------------------
                when rcv_cmd_tth => 
                    state           <= snd_cmd_ack;
                    ret_state       <= rcv_col_hi;
                    ret_ret_state   <= snd_data;

                -- inbound cmd: process data -----------------------------------
                when rcv_cmd_proc => 
                    pu_enable       <= '1';

                    if not pu_busy then
                        state       <= snd_cmd_ack;
                        ret_state   <= listen;
                    end if;

                -- wait for incoming data --------------------------------------
                when rcv_data => 
                    if host_davail then
                        row         <= row_addr;
                        col         <= col_addr;                        
                        mem_dout    <= host_din;
                        mem_we      <= '1';

                        state       <= snd_cmd_ack;
                        ret_state   <= listen;
                    end if;

                -- wait for inbound address components -------------------------
                when rcv_col_hi => 
                    if host_davail then
                        col_addr(15 downto 8) <= host_din;

                        state       <= snd_cmd_ack;
                        ret_state   <= rcv_col_lo;
                    end if;

                when rcv_col_lo => 
                    if host_davail then
                        col_addr(7 downto 0) <= host_din;

                        state       <= snd_cmd_ack;
                        ret_state   <= rcv_row_hi;
                    end if;

                when rcv_row_hi => 
                    if host_davail then
                        row_addr(15 downto 8) <= host_din;

                        state       <= snd_cmd_ack;
                        ret_state   <= rcv_row_lo;
                    end if;

                when rcv_row_lo => 
                    if host_davail then
                        row_addr(7 downto 0) <= host_din;

                        state       <= snd_cmd_ack;
                        ret_state   <= ret_ret_state;
                    end if;

                -- send acknowledge cmd to host --------------------------------
                when snd_cmd_ack => 
                    host_dout <= encode_cmd(ack);
                    host_we   <= '1';

                    if not host_busy then
                        state   <= ret_state;
                    end if;

                -- send data to host -------------------------------------------
                when snd_data => 
                    host_dout <= mem_din;
                    host_we <= '1';

                    if not host_busy then                        
                        state   <= ret_state;
                    end if;


            end case;
        end if;
    end process;
end rtl;

