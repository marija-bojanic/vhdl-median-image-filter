library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.RAM_definitions_PK.all;

entity median_tb is
end median_tb;

architecture tb of median_tb is


    signal clk          : std_logic := '1';
    signal data_in      : matrix(0 to 8); 
    signal data_out     : std_logic_vector(7 downto 0); 

begin

	clk_gen : clk<= not clk after 200 ms;


    dut: entity work.median
        port map (
            clk => clk,
            data_in => data_in,
            data_out => data_out
        );


    stimulus: process is
    begin

        data_in(0) <= "00010011"; -- 19
        data_in(1) <= "00000011"; -- 3
        data_in(2) <= "00010001"; -- 17
        data_in(3) <= "00000111"; -- 7
        data_in(4) <= "00001001"; -- 9
        data_in(5) <= "00010001"; -- 17
        data_in(6) <= "00000001"; -- 1
        data_in(7) <= "00000100"; -- 4
        data_in(8) <= "00000000"; -- 23
      
        wait for 400 ms;
        wait;
        
     end process stimulus;
end tb;
     