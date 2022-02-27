-----------------------------------------------------------------------------
-- This file is part of BT656_DECODER_IP.
-- Copyright (C) 2014, Laurentiu ACASANDREI
--
-- BT656_camera_model is free software: you can redistribute 
-- it and/or modify it under the terms of the GNU General Public License as 
-- published by the Free Software Foundation, either version 3 of the License, 
-- or (at your option) any later version.
--
-- BT656_camera_model is distributed in the hope that it will
-- be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with BT656_camera_model.  If not, 
-- see <http://www.gnu.org/licenses/>.
--
-- Contact      : laurentiu@imse-cnm.csic.es
--  			  www.imse-cnm.csic.es	
-- Disclaimer   : All information is provided "as is", there is no warranty that
-- 				 the information is correct or suitable for any purpose,
-- 				 neither implicit nor explicit.
-----------------------------------------------------------------------------
-- Entity: 	BT656_camera_model
-- File:	BT656_camera_model.vhd
-- Author:	Laurentiu Acasandrei
-- Description: This is a model description of camera that uses the BT656 standard
--			    To be used only in simulation !!!!. The camera has 625 horizontal
--				lines and each line is composed of 1888 pixel (both active, blanking, 
-- 				EAV, SAV). The source is figure 6 and 8 from an9728.pdf (application note
--				intersil 9728 ) 
------------------------------------------------------------------------------	

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BT656_camera_model is
    Generic(
		SENSOR_ROWS						 :integer := 18;
		VERTICAL_ACTIVE_DURATION         :integer := 16;
        
        HORIZONTAL_BLANK_DURATION 	     :integer := 10; --Must be greater than 8 (sav+eav)
        HORIZONTAL_ACTIVE_DURATION       :integer := 24
	);
end BT656_camera_model;

architecture Model of BT656_camera_model is

    signal clk : std_logic := '0';
    signal reset : std_logic;
    
    constant period : time := 10 ns;
	
	impure function encode_pixel(constant row : in integer; constant col : in integer) return std_logic_vector is

		variable result : std_logic_vector(7 downto 0);
		variable F,V,H : std_logic;
		variable pixmode : integer;
        begin
        
            --encode field and vertical blanking
            if (row<(SENSOR_ROWS/2+1)) then
                F := '0';
            else
                F := '1';
            end if;
            
            if (row>VERTICAL_ACTIVE_DURATION and row<SENSOR_ROWS) then
                V := '1';
            else
                V := '0';
            end if;
            
            -- at row level encode EAV, Blanking, SAV , Active Line
            -- begin encoding EAV
            if col=1 then 
                result := X"FF";
                return result;
            end if; 	
            
            if col=2 then 
                result := X"00";
                return result;
            end if; 	
            
            if col=3 then 
                result := X"00";
                return result;
            end if; 
            
            if col=4 then --Encode XYZ for EAV
                result := "1" & F & V & '1' & (V xor'1') & (F xor'1') & (F xor V) & (F xor V xor '1'); --H is 1
                return result;
            end if; 
            
            -- end encoding EAV
            
            -- encoding blanking
            if col>4 and col < HORIZONTAL_BLANK_DURATION-3 then
                if col mod 2=1 then
                    result := X"80";
                    return result;
                else
                    result := X"10";
                    return result;
                end if;
            end if;
            
            -- begin encoding SAV
            if col=HORIZONTAL_BLANK_DURATION-3 then 
                result := X"FF";
                return result;
            end if; 	
            
            if col=HORIZONTAL_BLANK_DURATION-2 then 
                result := X"00";
                return result;
            end if; 	
            
            if col=HORIZONTAL_BLANK_DURATION-1 then 
                result := X"00";
                return result;
            end if; 
            
            if col=HORIZONTAL_BLANK_DURATION then --Encode XYZ for SAV
                result := "1" & F & V & '0' & (V xor'0') & (F xor'0') & (F xor V) & (F xor V xor'0'); --H is 0
                return result;
            end if; 
            -- end encoding SAV
            
            if V='1' then --we put the row during vertical blanking
                result := X"00"; --row
                return result;
            end if;
            
            --if (col > HORIZONTAL_ACTIVE_DURATION) then
            --    pixmode := 0;
            --end if;
            
            --encode digital active line
            if col>HORIZONTAL_BLANK_DURATION and 
                col<=HORIZONTAL_ACTIVE_DURATION+ HORIZONTAL_BLANK_DURATION then 
                pixmode := col + 1;
                
                if (pixmode mod 4) = 0 then
                    result := X"C0";
                end if;
                
                if (pixmode mod 4) = 1 then
                    result := X"35";
                end if;
                
                if (pixmode mod 4) = 3 then
                    result := X"34";
                end if;
                
                if (pixmode mod 4) = 2 then
                    result := X"70";
                end if;
                return result;
            end if;
        end encode_pixel;
        
    signal CAM_Y : std_logic_vector (7 downto 0 ) := (others => '0');
    signal CAM_LLC : std_logic := '0';
    
    signal M_AXIS_0_tlast : std_logic;
    signal M_AXIS_0_tvalid : std_logic;
    signal M_AXIS_0_tuser : std_logic;
    signal M_AXIS_0_tdata : std_logic_vector(23 downto 0);    

begin

    dut : entity work.BT656_decode_wrapper
    port map (
        m_clk           => clk,
        BT656_clk       => CAM_LLC,
        BT656           => CAM_Y,
        reset           => reset,
        M_AXIS_0_tdata  => M_AXIS_0_tdata,
        M_AXIS_0_tlast  => M_AXIS_0_tlast,
        M_AXIS_0_tready => reset,
        M_AXIS_0_tuser(0)  => M_AXIS_0_tuser,
        M_AXIS_0_tvalid => M_AXIS_0_tvalid
    );

    CAM_LLC <= not CAM_LLC after period;
    clk     <= not clk after period*3;
    reset   <= '0', '1' after 100 ns;

	generate_output : process
        variable row,col: integer;
    begin
        row :=1;
        while row <= SENSOR_ROWS loop
           col:=1;
            while col<= (HORIZONTAL_ACTIVE_DURATION+ HORIZONTAL_BLANK_DURATION) loop
                wait until rising_edge(CAM_LLC);
                    if reset = '0' then
                        CAM_Y <= (others => '0');
                        row:=1;
                        col:=1;
                    else
                        CAM_Y <= encode_pixel(row,col);
                        col:= col+1;
                    end if;
            end loop;
            row := row +1;
        end loop;
	end process;

END Model;

