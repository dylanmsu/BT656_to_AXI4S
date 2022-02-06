-----------------------------------------------------------------------------
-- This file is part of BT656_DECODER_IP.
-- Copyright (C) 2014, Laurentiu ACASANDREI
--
-- CbYCrY_UpSampler is free software: you can redistribute 
-- it and/or modify it under the terms of the GNU General Public License as 
-- published by the Free Software Foundation, either version 3 of the License, 
-- or (at your option) any later version.
--
-- CbYCrY_UpSampler is distributed in the hope that it will
-- be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with CbYCrY_UpSampler.  If not, 
-- see <http://www.gnu.org/licenses/>.
--
-- Contact      : laurentiu@imse-cnm.csic.es
--  			  www.imse-cnm.csic.es	
-- Disclaimer   : All information is provided "as is", there is no warranty that
-- 				 the information is correct or suitable for any purpose,
-- 				 neither implicit nor explicit.
-----------------------------------------------------------------------------
-- Entity: 	CbYCrY_UpSampler
-- File:	CbYCrY_UpSampler.vhd
-- Author:	Laurentiu Acasandrei
-- Description:The standard ITU.601 specifies that the values for Y,Cb,Cr
--			   cannot be zero or  255.
------------------------------------------------------------------------------	

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CbYCrY_UpSampler is
    Generic (
        data_width : integer:= 8
    );
    Port (
        pix_clk     : in STD_LOGIC;
        reset_n     : in STD_LOGIC;
        data_valid  : in STD_LOGIC;
        data        : in STD_LOGIC_VECTOR (data_width-1 downto 0);
        
        ycbcr_valid : out STD_LOGIC;
        y_out       : out STD_LOGIC_VECTOR (data_width-1 downto 0);
        cb_out      : out STD_LOGIC_VECTOR (data_width-1 downto 0);
        cr_out      : out STD_LOGIC_VECTOR (data_width-1 downto 0)
    );
end CbYCrY_UpSampler;

architecture Behavioral of CbYCrY_UpSampler is

    type state_type is (Idle_Wait_for_Cb, Receive_Y_odd, Receive_Cr, Receive_Y_even); 
    signal state, next_state : state_type; 
    
    signal Cb_reg, Cr_reg, Y_reg: std_logic_vector(data_width-1 downto 0);
	
BEGIN
   SYNC_PROC: process (pix_clk)
   begin
      if (rising_edge(pix_clk)) then
         if (reset_n = '0') then
            state <= Idle_Wait_for_Cb;
         else
            state <= next_state;
         end if;        
      end if;
   end process;
   
OUTPUT_DECODE: process (pix_clk, data_valid, Y_reg, Cb_reg, data, Cr_reg, state)
begin
    if (rising_edge(pix_clk)) then
        --Cb_reg
        if (state = Idle_Wait_for_Cb and data_valid = '1') then
            Cb_reg <= data;
        elsif (state = Idle_Wait_for_Cb and data_valid = '0') then
            Cb_reg <= (others=>'1');
        end if;
        
        --Y_reg
        if (state = Receive_Y_odd and data_valid = '1') then
            Y_reg <= data;
        elsif (state = Receive_Y_odd and data_valid = '0') then
            Y_reg <= (others=>'1');
        end if;		
        
        --Cr_reg
        if (state = Receive_Cr and data_valid = '1') then
            Cr_reg <= data;
        elsif (state = Receive_Cr and data_valid = '0') then
            Cr_reg <= (others=>'1');
        end if;
    
    end if; --if clk
    -- driving the outputs asyncronous. Two times less transistors.
    -- Note: If I put the output in the clock section I will have lower 
    -- frequency and towo times more register usage.
    if (state = Receive_Cr ) then
        ycbcr_valid <= data_valid; 
        Y_out  <= Y_reg;		--odd pixel
        Cb_out <= Cb_reg ;
        Cr_out <= data;
    elsif (state = Receive_Y_even ) then
        ycbcr_valid <= data_valid;
        Y_out  <= data;		--even pixel
        Cb_out <= Cb_reg;
        Cr_out <= Cr_reg;				
    else
        ycbcr_valid <= '0'; 
        Y_out  <= (others=>'1');	--non pixel region
        Cb_out <= (others=>'1');
        Cr_out <= (others=>'1');
    end if;
end process;
 
NEXT_STATE_DECODE: process (state, data_valid)
begin
    --declare default state for next_state to avoid latches
    next_state <= state;  --default is to stay in current state
    
    case (state) is
        when Idle_Wait_for_Cb =>
            if data_valid = '1' then
                next_state <= Receive_Y_odd;
            end if;
        
        when Receive_Y_odd =>
            if data_valid = '1' then
                next_state <= Receive_Cr;
            else
                next_state <= Idle_Wait_for_Cb;
            end if;
        
        when Receive_Cr =>
            if data_valid = '1' then
                next_state <= Receive_Y_even;
            else
                next_state <= Idle_Wait_for_Cb;
            end if;
        
        when Receive_Y_even =>
            next_state <= Idle_Wait_for_Cb;
        
        when others =>
            next_state <= Idle_Wait_for_Cb;
    end case;      
end process;


END Behavioral;

