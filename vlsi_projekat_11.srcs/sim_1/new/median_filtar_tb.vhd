library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.RAM_definitions_PK.all;


entity median_filtar_tb is
end;

architecture Behavioral of median_filtar_tb is

  signal clk: std_logic := '1';
  signal reset: std_logic;
  signal median_out: std_logic_vector(7 downto 0);

begin

  clk_gen : clk<= not clk after 4 ns;

  DUT: entity work.median_filtar
  port map ( clk   => clk,
            reset => reset,
            median_out => median_out );
                                
  STIMULUS: process is
  begin
  reset <= '1';
  wait for 8 ns;
  reset <= '0';
  
  wait;
  
  end process; 
                                
  

end Behavioral;