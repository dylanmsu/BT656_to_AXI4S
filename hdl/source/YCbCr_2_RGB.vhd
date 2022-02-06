----------------------------------------------------------------------------------
-- Company: None
-- Engineer: Dylan Missuwe
-- 
-- Create Date: 02/01/2022 07:03 PM
-- Design Name: BT656_decoder
-- Module Name: YCbCr_2_RGB - Behavioral
-- Project Name: ADV7180_Interface
-- Target Devices: XC7Z020CLG400-1
-- Tool Versions: Vivado 2021.2
-- Description: 
--      Converts YCbCr (YUV) to RGB color space
--      R = Y + 1.403Cr
--      G = Y - 0.344Cb - 0.714Cr
--      B = Y + 1.770Cb
-- 
-- Dependencies: 
-- 
-- Revision: 1.00 - First working prototype
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Entity YCbCr_2_RGB is
    Generic(
        data_width : integer := 8
    );
    Port(
        clk : in std_logic;
        y, cb, cr : in std_logic_vector((data_width - 1) downto 0);
        r, g, b : out std_logic_vector((data_width - 1) downto 0)
    );
end YCbCr_2_RGB;

architecture Behavioral of YCbCr_2_RGB is
    
    signal iy, icr, icb : integer := 0;
    signal ir, ig,  ib  : integer := 0;
begin
    
    -- convert the vectors to integers
    iy  <= to_integer(unsigned(y));
    icb <= to_integer(unsigned(cb));
    icr <= to_integer(unsigned(cr));
    
    -- calculate r, g, b from y, cb, cr
    ir <= iy +  45 * (icr - 128) / 32;
    ig <= iy - (11 * (icb - 128) + 23 * (icr - 128)) / 32;
    ib <= iy + 113 * (icb - 128) / 64;
    
    -- clamp rgb values between 0 and 255 to prevent integer overflow
    process (clk)
    begin
        if rising_edge(clk) then
            if (ir <= 0) then
                r <= (others => '0');
            elsif (ir >= 255) then
                r <= (others => '1');
            else
                r <= std_logic_vector(to_unsigned(ir, data_width));
            end if;
            
            if (ig <= 0) then
                g <= (others => '0');
            elsif (ig >= 255) then
                g <= (others => '1');
            else
                g <= std_logic_vector(to_unsigned(ig, data_width));
            end if;
            
            if (ib <= 0) then
                b <= (others => '0');
            elsif (ib >= 255) then
                b <= (others => '1');
            else
                b <= std_logic_vector(to_unsigned(ib, data_width));
            end if;        
        end if;
    end process;

end Behavioral;