--------------------------------------------------------------------------------
--
--   FileName:         pwm.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 64-bit Version 12.1 Build 177 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 8/1/2013 Scott Larson
--     Initial Public Release
--   Version 2.0 1/9/2015 Scott Larson
--     Transistion between duty cycles always starts at center of pulse to avoid
--     anomalies in pulse shapes
--    
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pwm is
  Generic(
      sys_clk         : integer := 13_500_000; --system clock frequency in Hz
      pwm_freq        : integer := 100_000;    --PWM switching frequency in Hz
      bits_resolution : integer := 8;          --bits of resolution setting the duty cycle
      phases          : integer := 1
  );
  Port(
      clk       : in  std_logic;                                    --system clock
      reset_n   : in  std_logic;                                    --asynchronous reset
      ena       : in  std_logic;                                    --latches in new duty cycle
      duty      : in  std_logic_vector(bits_resolution-1 downto 0); --duty cycle
      pwm_out   : out std_logic_vector(phases-1 downto 0);          --pwm outputs
      pwm_n_out : out std_logic_vector(phases-1 downto 0));         --pwm inverse outputs
end pwm;

architecture logic of pwm is
  constant  period     :  integer := sys_clk/pwm_freq;
  
  type counters is array (0 to phases-1) of integer range 0 to period - 1;
  signal  count        :  counters := (others => 0);
  signal   half_duty_new  :  integer range 0 to period/2 := 0;
  
  type half_duties is array (0 to phases-1) of integer range 0 to period/2;
  signal  half_duty    :  half_duties := (others => 0);
  
begin
  process(clk, reset_n)
  begin
    if(reset_n = '0') then
      count <= (others => 0);
      pwm_out <= (others => '0');
      pwm_n_out <= (others => '0');
    elsif(clk'event and clk = '1') then
    
      if(ena = '1') then                                                   --latch in new duty cycle
        half_duty_new <= conv_integer(duty)*period/(2**bits_resolution)/2;   --determine clocks in 1/2 duty cycle
      end if;
      
      for i in 0 to phases-1 loop                                            --create a counter for each phase
        if(count(0) = period - 1 - i*period/phases) then                       --end of period reached
          count(i) <= 0;                                                         --reset counter
          half_duty(i) <= half_duty_new;                                         --set most recent duty cycle value
        else                                                                   --end of period not reached
          count(i) <= count(i) + 1;                                              --increment counter
        end if;
      end loop;
      
      for i in 0 to phases-1 loop                                            --control outputs for each phase
        if(count(i) = half_duty(i)) then                                       --phase's falling edge reached
          pwm_out(i) <= '0';                                                     --deassert the pwm output
          pwm_n_out(i) <= '1';                                                   --assert the pwm inverse output
        elsif(count(i) = period - half_duty(i)) then                           --phase's rising edge reached
          pwm_out(i) <= '1';                                                     --assert the pwm output
          pwm_n_out(i) <= '0';                                                   --deassert the pwm inverse output
        end if;
      end loop;
    end if;
  end process;
end logic;
