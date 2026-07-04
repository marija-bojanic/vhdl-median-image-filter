library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.RAM_definitions_PK.all;
use IEEE.NUMERIC_STD.ALL;

entity median is
  Port ( 
        clk: in std_logic;
        data_in: in matrix(0 to 8); 
        data_out: out std_logic_vector(7 downto 0)
  );
end median;

architecture Behavioral of median is

    type Result is record
        in1 : std_logic_vector(7 downto 0);
        in2 : std_logic_vector(7 downto 0);
    end record;

    -- Blok za sortiranje dva elementa
    function cmp_swap(in1, in2: std_logic_vector(7 downto 0)) return Result is
        variable sorted_pair: Result;
    begin
        if (in1 >= in2) then
            sorted_pair.in1 := in2;
            sorted_pair.in2 := in1;
        else
            sorted_pair.in1 := in1;
            sorted_pair.in2 := in2;
        end if;
        return sorted_pair;
    end function;

    
    signal r_data_in:  matrix(0 to 8); -- Ulazni registar
    signal stage0_out: matrix(0 to 8); 
    signal stage1_out: matrix(0 to 8);
    signal stage2_out: matrix(0 to 8);
    signal stage3_out: matrix(0 to 8);
    signal stage4_out: matrix(0 to 8);
    signal stage5_out: matrix(0 to 8);
    signal stage6_out: matrix(0 to 8);
    signal stage7_out: matrix(0 to 8);
    signal stage8_out: matrix(0 to 8);
    signal stage9_out: matrix(0 to 1); -- Izlazni registar
     
begin
    
    -- Upis u ulazni ragistar
    REGS_PROC: process(clk) is
    begin
        if rising_edge(clk) then
            r_data_in <= data_in; 
            data_out <= stage9_out(1);
        end if; 
    end process REGS_PROC;

    STAGE0: process(clk) is
        variable swapped : Result; 
    begin
        if rising_edge(clk) then  
            for i in 0 to 3 loop
                swapped := cmp_swap(r_data_in(2*i), r_data_in(2*i+1));
                stage0_out(2*i) <= swapped.in1;
                stage0_out(2*i+1) <= swapped.in2;
            end loop;
            stage0_out(8) <= r_data_in(8);
        end if;
    end process STAGE0;
    


   
    
    STAGE1: process(clk) is
        variable swapped1 : Result; 
        variable swapped2 : Result;
    begin
        if rising_edge(clk) then
            for i in 0 to 1 loop
                swapped1 := cmp_swap(stage0_out(4*i), stage0_out(4*i+2));
                swapped2 := cmp_swap(stage0_out(4*i+1), stage0_out(4*i+3));
                stage1_out(4*i) <= swapped1.in1;
                stage1_out(4*i+2) <= swapped1.in2;
                stage1_out(4*i+1) <= swapped2.in1;
                stage1_out(4*i+3) <= swapped2.in2;   
            end loop;
            stage1_out(8) <= stage0_out(8);
        end if;
    end process STAGE1;
    
    STAGE2: process(clk) is
        variable swapped : Result; 
    begin
        if rising_edge(clk) then
            for j in 0 to 8 loop
                if (j mod 4 = 1) then
                        swapped := cmp_swap(stage1_out(j), stage1_out(j+1));
                        stage2_out(j) <= swapped.in1;
                        stage2_out(j+1) <= swapped.in2;
                elsif((j mod 4 /= 2)) then
                    stage2_out(j) <= stage1_out(j);
                end if;
            end loop;
        end if;
    end process STAGE2;
    
    STAGE3: process(clk) is
        variable swapped : Result; 
    begin
        if rising_edge(clk) then  
            for i in 0 to 3 loop
                swapped := cmp_swap(stage2_out(i), stage2_out(i+4));
                stage3_out(i) <= swapped.in1;
                stage3_out(i+4) <= swapped.in2;
            end loop;
                stage3_out(8) <= stage2_out(8);
        end if;
        end process STAGE3;
    
    STAGE4: process(clk) is
            variable swapped : Result; 
        begin
            if rising_edge(clk) then
                for i in 0 to 8 loop
                    if((i = 2) or (i = 3)) then
                        swapped := cmp_swap(stage3_out(i), stage3_out(i+2));
                        stage4_out(i) <= swapped.in1;
                        stage4_out(i+2) <= swapped.in2;
                    elsif ((i /= 4) and (i /= 5)) then
                        stage4_out(i) <= stage3_out(i);
    
                    end if;
                end loop;
            end if;
        end process STAGE4;
        
        STAGE5: process(clk) is
            variable swapped : Result; 
        begin
            if rising_edge(clk) then
                for i in 0 to 8 loop
                    if ((i mod 2 = 1) and (i < 7)) then
                            swapped := cmp_swap(stage4_out(i), stage4_out(i+1));
                            stage5_out(i) <= swapped.in1;
                            stage5_out(i+1) <= swapped.in2;
                    elsif((i = 0) or (i >= 7)) then
                        stage5_out(i) <= stage4_out(i);
                    end if;
                end loop;
            end if;
        end process STAGE5;
        
        STAGE6: process(clk) is
            variable swapped : Result; 
        begin
            if rising_edge(clk) then
                for i in 0 to 7 loop
                    if (i /= 0) then
                        stage6_out(i) <= stage5_out(i);     
                    else 
                        swapped := cmp_swap(stage5_out(0), stage5_out(8));
                        stage6_out(0) <= swapped.in1;
                        stage6_out(8) <= swapped.in2;
                    end if;
                end loop;
            end if;
        end process STAGE6;
        
        STAGE7: process(clk) is
            variable swapped : Result; 
        begin
            if rising_edge(clk) then
                for i in 0 to 7 loop
                    if (i /= 4) then
                        stage7_out(i) <= stage6_out(i);     
                    else 
                        swapped := cmp_swap(stage6_out(4), stage6_out(8));
                        stage7_out(4) <= swapped.in1;
                        stage7_out(8) <= swapped.in2;
                    end if;
                end loop;
            end if;
        end process STAGE7;

        STAGE8: process(clk) is
             variable swapped : Result; 
        begin
            if rising_edge(clk) then
                for i in 0 to 8 loop
                    if((i = 2) or (i = 3)) then
                        swapped := cmp_swap(stage7_out(i), stage7_out(i+2));
                        stage8_out(i) <= swapped.in1;
                        stage8_out(i+2) <= swapped.in2;
                    elsif ((i /= 4) and (i /= 5)) then
                        stage8_out(i) <= stage7_out(i);
    
                    end if;
                end loop;
            end if;
        end process STAGE8;
                
        STAGE9: process(clk) is
             variable swapped : Result; 
        begin
             if rising_edge(clk) then
                swapped := cmp_swap(stage8_out(3), stage8_out(4));
                stage9_out(0) <= swapped.in1;
                stage9_out(1) <= swapped.in2;
             end if;
        end process STAGE9;
        
    
        
    end Behavioral;