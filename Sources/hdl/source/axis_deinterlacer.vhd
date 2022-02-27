----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/07/2022 05:38:00 PM
-- Design Name: 
-- Module Name: axis_deinterlacer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity axis_deinterlacer is
    generic (
        linelength    :   integer := 720
    );
    Port (
        clk, reset    :   in std_logic;
        
        -- slave axis interface
        stdata        :   in std_ulogic_vector(7 downto 0);
        steol         :   in std_logic;
        stsof         :   in std_logic;
        stdata_valid  :   in std_logic;
        stready       :   out std_logic;
        
        -- master axis interface
        mtdata        :   out std_ulogic_vector(7 downto 0);
        mteol         :   out std_logic;
        mtsof         :   out std_logic;
        mtdata_valid  :   out std_logic;
        mtready       :   in std_logic 
    );
end axis_deinterlacer;

architecture Behavioral of axis_deinterlacer is

    type ram is array((linelength - 1) downto 0) of std_ulogic_vector(23 downto 0);
    signal linebuffer : ram;
    
    type state_type is (idle, s1, s2);
    signal state : state_type;
    
    signal columncounter : integer := 0;
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if stdata_valid = '1' then
                case state is
                    when idle =>
                        columncounter <= columncounter + 1;
                        linebuffer(columncounter) <= stdata;
                        if steol = '1' then
                            
                        end if;
                    when s1 =>
                    when s2 =>
                    when others =>
                end case;
            end if;
        end if;
    end process;
end Behavioral;
