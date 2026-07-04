library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.RAM_definitions_PK.all;


entity median_filtar is
 port (
        clk : in std_logic;
        reset : in std_logic;
        median_out : out std_logic_vector(7 downto 0)
        
 );
end median_filtar;

architecture Behavioral of median_filtar is

 type State_t is (stIdle, stWrite, stSend);
 signal next_state, state_reg : State_t;          
 signal cnt_state : integer := 0;     
 signal cnt_addr_wr : integer := 0;  
 signal cnt_addr_rd : integer := 0;  
 signal reg0_in, reg0_out : std_logic_vector(7 downto 0);
 signal reg1_out, reg2_out : std_logic_vector(7 downto 0);   --reg2_out je fifo1 in
 signal reg3_out, reg4_out, reg5_out: std_logic_vector(7 downto 0);  --reg5_out je fifo2_in
 signal reg3_in, reg6_in : std_logic_vector(7 downto 0);
 signal reg6_out, reg7_out, reg8_out: std_logic_vector(7 downto 0);
 signal addr_wr, addr_rd : std_logic_vector(15 downto 0);  --addr za citanje i upis iz mem
 signal wr_enable : std_logic;   --enable za upis u mem
 signal median : std_logic_vector(7 downto 0);  --izlaz iz median komponente
 signal valid_output: std_logic := '0'; -- flag koji signalizira kada pocinje ili se zavrsava slanje
 signal fifo1_re : std_logic;
 signal fifo2_re : std_logic;
 signal fifo1_we : std_logic;
 signal fifo2_we : std_logic;
 signal median_in : matrix(0 to 8);  --ulaz u sam median

begin

IM_MEM : entity work.im_ram(Behavioral)
 generic map(
            G_RAM_WIDTH => 8,
            G_RAM_DEPTH => 256*256,
            G_RAM_PERFORMANCE => "HIGH_PERFORMANCE"
        )
        port map (
            addra => addr_wr, 
            addrb => addr_rd, 
            dina  => median, 
            clka  => clk,
            wea   => wr_enable,
            enb   => '1',   
            rstb  => reset,
            regceb=> '1', 
            doutb => reg0_in
        );
FIFO1: entity work.fifo(Behavioral)
generic map(
            G_DATAWIDTH => 8,
            G_FIFODEPTH => 253
        )
        
         port map (
                    clk => clk,
                    reset => reset,
                    fifo_wr => fifo1_we,   --write enable  
                    din => reg2_out,
                    fifo_rd => fifo1_re,  --read enable
                    dout => reg3_in,
                    full => fifo1_re
         );
FIFO2: entity work.fifo(Behavioral)
generic map(
            G_DATAWIDTH => 8,
            G_FIFODEPTH => 253
        )
        
         port map (
                    clk => clk,
                    reset => reset,
                    fifo_wr => fifo2_we,   --write enable  
                    din => reg5_out,
                    fifo_rd => fifo2_re,  --read enable
                    dout => reg6_in, 
                    full => fifo2_re
         );
MEDIAN_COMP: entity work.median(Behavioral)

    port map (
            clk => clk,
            data_in => median_in,
            data_out => median
    
    );

STATE_TRANSITION: process(clk) is

begin

    if(rising_edge(clk)) then
        if reset='1' then
            state_reg <= stIdle;
        else
            state_reg <= next_state;
        end if; 
    end if;
end process STATE_TRANSITION;

NEXT_STATE_LOGIC: process(clk) is
 begin
 if (rising_edge(clk)) then
    case state_reg is 
    
        when stIdle =>
           if (cnt_state >=515) then  -- 515 taktova je potrebno da se pojavi izlaz iz reg8 sto je ulaz u median komponentu
                next_state <= stWrite;
            else 
                next_state <= stIdle;
           end if;      
       when  stWrite =>
            if(cnt_state >=(10+256*256+2)) then  
                next_state <= stSend;
            else
                next_state <= stWrite;
            end if;
       when stSend =>
            if(cnt_state >= 2 and cnt_state < 256*256+2) then -- +2 takta zbog high performance memorije
                valid_output <= '1';
            else
                valid_output <= '0';
            end if;
           
     end case; 
end if;
end process NEXT_STATE_LOGIC;



CNT_STATE_PROCESS: process(clk) is 
begin 
    if (rising_edge(clk)) then
       if (next_state /=state_reg or reset = '1') then
                cnt_state <= 0;
            else
                cnt_state <= cnt_state + 1;
        end if;
    end if;
    
end process CNT_STATE_PROCESS;

MASKING: process(clk) is 
begin
    if(rising_edge(clk)) then   
       if (reset = '1') then
        fifo1_we <= '0';
        fifo2_we <= '0';
        
       elsif(state_reg = stIdle) then
        if(cnt_state >=2) then
          fifo1_we <= '1';       
        else 
          fifo1_we <= '0';
        end if;
              
        if(cnt_state >=258) then
          fifo2_we <= '1';
        else 
          fifo2_we <= '0';
        end if;
       end if;    
             
       reg0_out <= reg0_in;
       reg1_out <= reg0_out;
       reg2_out <= reg1_out;
       reg3_out <= reg3_in;
       reg4_out <= reg3_out;
       reg5_out <= reg4_out;
       reg6_out <= reg6_in;
       reg7_out <= reg6_out;
       reg8_out <= reg7_out;
   end if;
end process MASKING;


ADDR_WR_PROCESS: process(clk) is 
begin
    if(rising_edge(clk)) then
        if (reset = '1') then
            cnt_addr_wr <= 258;   
        
        end if;
        if (wr_enable = '1') then
            if(cnt_addr_wr<65279+1) then
                    cnt_addr_wr <= cnt_addr_wr+1;
            else 
                cnt_addr_wr <= 65279+1;
            end if;
        end if;
    end if; 
end process ADDR_WR_PROCESS;

ADDR_RD_PROCESS: process(clk) is 
begin

    if(rising_edge(clk)) then
        if((reset='1') or ((state_reg = stWrite) and (next_state = stSend))) then
            cnt_addr_rd <= 0;
            
        else 
            cnt_addr_rd <= cnt_addr_rd + 1;
        end if;
        addr_rd <= std_logic_vector(to_unsigned(cnt_addr_rd,16));
    end if;
    
    
end process ADDR_RD_PROCESS;


WRITE_MEDIAN_PROCESS: process(clk) is 
 begin
    if(rising_edge(clk)) then
        if (state_reg = stWrite) then
               
            median_in(0) <= reg0_out;
            median_in(1) <= reg1_out;
            median_in(2) <= reg2_out;
            median_in(3) <= reg3_out;
            median_in(4) <= reg4_out;
            median_in(5) <= reg5_out;
            median_in(6) <= reg6_out;
            median_in(7) <= reg7_out;
            median_in(8) <= reg8_out;
       
            if(cnt_state >= 10+2 and cnt_addr_wr /= 65279+1) then       --inicijalno je potrebno 10+2 takta da se prvi piksel upise u memoriju
                wr_enable <= '1';
                addr_wr <= std_logic_vector(to_unsigned(cnt_addr_wr,16));
            else 
                wr_enable <= '0';
            end if;
        end if;
        
        if(valid_output = '1') then
            median_out <= reg0_in;
        else
            median_out <= (others => '0');
        end if;
    
    end if;

end process WRITE_MEDIAN_PROCESS;
--proba test
end Behavioral;