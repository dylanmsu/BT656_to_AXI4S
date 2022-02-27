----------------------------------------------------------------------------------
-- Company: None
-- Engineer: Dylan Missuwe
-- 
-- Create Date: 02/01/2022 07:03 PM
-- Design Name: BT656_decoder
-- Module Name: axis_converter - Behavioral
-- Project Name: ADV7180_Interface
-- Target Devices: XC7Z020CLG400-1
-- Tool Versions: Vivado 2021.2
-- Description: Converts the opsampled color data  
-- 
-- Dependencies: 
-- 
-- Revision: 1.00 - First working prototype
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity axis_converter is
    Port (
        i_data_r        : in std_logic_vector(7 downto 0) := (others => '0');
        i_data_g       : in std_logic_vector(7 downto 0) := (others => '0');
        i_data_b       : in std_logic_vector(7 downto 0) := (others => '0');
        i_data_active   : in std_logic;
        i_clk           : in std_logic;
        i_reset         : in std_logic;
        i_h_blank       : in std_logic;
        i_v_blank       : in std_logic;
        i_field_id      : in std_logic;
        
        i_data_ready    : in  std_logic;
        o_data          : out std_logic_vector(23 downto 0);
        o_eol           : out std_logic;
        o_sof           : out std_logic;
        o_data_active   : out std_logic;
        o_field_id      : out std_logic
    );
end axis_converter;

architecture Behavioral of axis_converter is
    constant fifo_length    : integer := 8;  -- needs to be >= 2
    
    type fifo is array (0 to (fifo_length - 1)) of std_logic_vector(31 downto 0);
    signal data_fifo : fifo;
    
    type state_type is (idle, data, hblank, vblank, s_eol, s_sof);
    signal state : state_type := idle;
    
    signal eol, sof : std_logic;
    
      attribute X_INTERFACE_INFO : string;
      attribute X_INTERFACE_PARAMETER : string;
      attribute X_INTERFACE_INFO of o_eol : signal is "xilinx.com:interface:axis:1.0 M_AXIS_0 TLAST";
      attribute X_INTERFACE_INFO of i_data_ready : signal is "xilinx.com:interface:axis:1.0 M_AXIS_0 TREADY";
      attribute X_INTERFACE_INFO of o_data_active : signal is "xilinx.com:interface:axis:1.0 M_AXIS_0 TVALID";
      attribute X_INTERFACE_INFO of o_data : signal is "xilinx.com:interface:axis:1.0 M_AXIS_0 TDATA";
      attribute X_INTERFACE_PARAMETER of o_data : signal is "XIL_INTERFACENAME M_AXIS_0, CLK_DOMAIN BT656_decode_m_clk, FREQ_HZ 100000000, HAS_TKEEP 0, HAS_TLAST 1, HAS_TREADY 1, HAS_TSTRB 0, INSERT_VIP 0, LAYERED_METADATA undef, PHASE 0.0, TDATA_NUM_BYTES 3, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 1";
      attribute X_INTERFACE_INFO of o_sof : signal is "xilinx.com:interface:axis:1.0 M_AXIS_0 TUSER";

begin    
    decode: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_reset = '0' then
                state <= idle;
            else
                case state IS
                    
                    when idle =>
                        if (i_v_blank or i_h_blank) = '1' then
                            state <= vblank;
                        end if;
                        
                        if i_h_blank = '1' then
                            eol <= '1';
                            state <= hblank;
                        end if;
                        
                    when vblank =>
                        if (i_v_blank or i_h_blank) = '0' then
                            sof <= '1';
                            state <= data;
                        end if;
                        
                    when data =>
                        sof <= '0';
                        state <= idle;
                    
                    when hblank =>
                        eol <= '0';
                        if i_h_blank = '0' then
                            state <= idle;
                        end if;
                        
                    when others =>
                        state <= idle;
                    
                end case;
            end if;
        end if;
    end process;
    
    fifo_proc: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_reset='0') then                
                -- reset fifo to all zeros
                for i in 0 to (fifo_length - 1) loop
                    data_fifo(i) <= (others => '0');
                end loop;
            else
                -- align sync signals
                o_data          <= data_fifo(fifo_length - 3)(23 downto 0);
                o_eol           <= data_fifo(fifo_length - 4)(24);
                o_sof           <= data_fifo(fifo_length - 1)(25);
                o_data_active   <= data_fifo(fifo_length - 2)(26);
                o_field_id      <= data_fifo(fifo_length - 7)(27);
                
                --give data to the input of the fifo
                data_fifo(0)(7 downto 0)    <= i_data_b;
                data_fifo(0)(15 downto 8)   <= i_data_g;
                data_fifo(0)(23 downto 16)  <= i_data_r;
                data_fifo(0)(24)            <= eol;
                data_fifo(0)(25)            <= sof;
                data_fifo(0)(26)            <= i_data_active;
                data_fifo(0)(27)            <= i_field_id;
                
                for i in 1 to fifo_length - 1 loop
                        data_fifo(fifo_length - i) <= data_fifo((fifo_length - 1) - i);
                end loop;
            end if;
        end if;
    end process;


end Behavioral;
