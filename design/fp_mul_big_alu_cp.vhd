----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/15/2026 07:15:43 PM
-- Design Name: 
-- Module Name: fp_mul_big_alu_cp - Behavioral
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
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fp_mul_big_alu_cp is
    Generic(WIDTH : positive := 32;
            WIDTH_COUNTER : positive := 5
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           ba_start : in STD_LOGIC;
           
           multiplicand_q : in STD_LOGIC_VECTOR(2*WIDTH-1 downto 0);
           multiplier_q : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           
           product_en : out STD_LOGIC;
           
           d0_fsm : out STD_LOGIC;
           
           multiplicand_en : out STD_LOGIC;
           multiplicand_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
           multiplier_en : out STD_LOGIC;
           multiplier_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
           
           ba_alu_en : out STD_LOGIC;
           
           rdy : out STD_LOGIC
           );
end fp_mul_big_alu_cp;

architecture Behavioral of fp_mul_big_alu_cp is

    type mul_ba_state_type is (IDLE, MUL, READY);
    signal state_reg, state_next : mul_ba_state_type;
    
    signal count_s, count_s_next : unsigned(WIDTH_COUNTER-1 downto 0) := (others=>'0');

begin


    d0_fsm <= '0';

    state_proc: process (rst, clk) is
    begin
        if (rst='1') then
          state_reg <= IDLE;
          count_s <= (others=>'0');
        else
          if(rising_edge(clk)) then
            state_reg <= state_next;
            count_s <= count_s_next;
          end if;
        end if;
    end process state_proc;


    control_proc: process (state_reg, ba_start, count_s, multiplicand_q, multiplier_q) is
    begin
    
        --default values
        multiplicand_en <= '1';
        multiplier_en <= '1';
        product_en <= '0';
        ba_alu_en <= '0';
        multiplicand_ctrl <= "00";
        multiplier_ctrl <= "00";
        count_s_next <= count_s;
        rdy <= '0';
    
        case state_reg is
          when IDLE =>
            --set value in product register to 0
            product_en <= '1';
            ba_alu_en <= '0'; 
            
            count_s_next <= (others => '0');
            if(ba_start='1') then
              multiplicand_ctrl <= "11";  --load
              multiplier_ctrl <= "11";  --load
              state_next <= MUL;
            else  
              state_next <= IDLE;
            end if;
          
          when MUL =>
            if(count_s<WIDTH) then
            --WIDTH = 24, counting max 23, for 24 go into ready state
            --counting 0-23
              multiplicand_ctrl <= "01"; --shift multiplicand left 01
              multiplier_ctrl <= "10";   --shift multiplier right 10
              if(multiplier_q(0)='1') then
                ba_alu_en <= '1';
                product_en <= '1';
              else
                ba_alu_en <= '0';
                product_en <= '0';
              end if;
            
              state_next <= MUL;
              count_s_next <= count_s + 1;
            else
              state_next <= READY;
            end if;
            
        when READY =>
          rdy <= '1';   
          state_next <= IDLE;  
            
        when others =>
          state_next <= IDLE;  
            
        end case;
    
    
    end process control_proc;



end Behavioral;
