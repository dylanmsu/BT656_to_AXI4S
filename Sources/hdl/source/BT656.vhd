----------------------------------------------------------------------------------
-- Company: None
-- Engineer: Dylan Missuwe
-- 
-- Create Date: 01/09/2022 10:07:34 PM
-- Design Name: BT656
-- Module Name: BT656 - Behavioral
-- Project Name: ADV7180_Interface
-- Target Devices: XC7Z020CLG400-1
-- Tool Versions: Vivado 2021.2
-- Description: Extracts the blank, field and active signals from the bt656 byte stream.
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
use ieee.numeric_std.all;

entity BT656 is
    Port (
        bt656_data: in std_logic_vector(7 downto 0) := (others => '0');
        llc: in std_logic;
        reset_n: in std_logic;
        
        data : out std_logic_vector(7 downto 0);
        active_video: out std_logic := '0';
        h_blank: out std_logic := '0';
        v_blank: out std_logic := '0';
        field_id: out std_logic := '0'
    );
end BT656;

architecture Behavioral of BT656 is
    constant fifo_length : integer := 4;  -- AV code length
    
    type fifo is array (0 to (fifo_length - 1)) of std_logic_vector(7 downto 0);
    signal data_fifo : fifo;
    
    type state_type is (idle, hblank, vblank);
    signal hstate : state_type := idle;
    signal vstate : state_type := idle;
    
    signal sfield_id, av_h_blank, av_v_blank , sh_blank, sv_blank : std_logic := '0';
    signal hcounter     : integer := 0;
    signal vcounter     : integer := 0;
    
    signal sactive_video : std_logic := '0';
    signal sdata : std_logic_vector(7 downto 0);
    
begin
    h_blank <= sh_blank;
    v_blank <= sv_blank;
    field_id <= sfield_id;
    sactive_video <= (not (sh_blank or sv_blank)) and reset_n;
    active_video <= sactive_video;
    data <= sdata;
    
    fifo_proc: process(llc)
    begin
        if rising_edge(llc) then
            if (reset_n='0') then
                sfield_id <= '0';
                av_h_blank <= '0';
                av_v_blank <= '0';
                
                -- reset fifo to all zeros
                for i in 0 to 3 loop
                    data_fifo(i) <=    (others => '0');
                end loop;
            else
                
                -- shift the fifo one place forward every clock cycle
                for i in 0 to fifo_length loop
                    if (i = 0) then
                        sdata <= data_fifo(fifo_length - 1);
                    elsif (i = fifo_length) then
                        data_fifo(0) <=    bt656_data;
                    else
                        data_fifo(fifo_length - i) <= data_fifo((fifo_length - 1) - i);
                    end if;
                end loop;
            
                -- detect the av codes
                if (data_fifo(2) = X"ff") and (data_fifo(1) = X"00") and (data_fifo(0) = X"00") then
                    av_h_blank <= bt656_data(4);
                    av_v_blank <= bt656_data(5);
                    sfield_id <= bt656_data(6);
                end if;
                
            end if;
        end if;
    end process;
    
    hdecode: process(llc)
    begin
        if rising_edge(llc) then
            if reset_n = '0' then
                hstate <= idle;
            else
                case hstate IS
                    
                    when idle =>
                        if av_h_blank = '1' then
                            sh_blank <= '1';
                            hcounter <= 0;
                            hstate <= hblank;
                        end if;
                    
                    when hblank =>
                        if av_h_blank = '0' then
                            hcounter <= hcounter+1;
                            if (hcounter >= 4) then
                                sh_blank <= '0';
                                hcounter <= 0;
                                hstate <= idle;
                            end if;
                        end if;                    
                    
                    when others =>
                        hstate <= idle;
                    
                end case;
            end if;
        end if;
    end process;
    
    vdecode: process(llc)
    begin
        if rising_edge(llc) then
            if reset_n = '0' then
                vstate <= idle;
            else
                case vstate IS
                    
                    when idle =>
                        if av_v_blank = '1' then
                            sv_blank <= '1';
                            vcounter <= 0;
                            vstate <= vblank;
                        end if;
                    
                    when vblank =>
                        if av_v_blank = '0' then
                            vcounter <= vcounter+1;
                            if (vcounter >= 4) then
                                sv_blank <= '0';
                                vcounter <= 0;
                                vstate <= idle;
                            end if;
                        end if;                    
                    
                    when others =>
                        vstate <= idle;
                    
                end case;
            end if;
        end if;
    end process;    
end Behavioral;
