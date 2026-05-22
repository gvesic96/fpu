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
    Generic(WIDTH : positive := 32);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           ba_start : in STD_LOGIC;
           
           multiplicand_q : in STD_LOGIC_VECTOR(2*WIDTH-1 downto 0);
           multiplier_q : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           
           d0_fsm : out STD_LOGIC;
           
           multiplicand_en : out STD_LOGIC;
           multiplicand_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
           multiplier_en : out STD_LOGIC;
           multiplier_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
           
           ba_alu_en : out STD_LOGIC
           
           );
end fp_mul_big_alu_cp;

architecture Behavioral of fp_mul_big_alu_cp is

    type mul_ba_state_type is (IDLE, MUL, READY);
    signal state_reg, state_next : mul_ba_state_type;

    signal count_s, count_s_next : unsigned(4 downto 0) := (others=>'0');

begin


    d0_fsm <= '0';

    state_proc: process (rst, clk) is
    begin
        if (rst='1') then
          state_reg <= IDLE;
          count_s <= "00000";
        else
          if (rising_edge(clk)) then
            state_reg <= state_next;
            count_s <= count_s_next;
          end if;
        end if;
    end process state_proc;


    control_proc: process (state_reg, ba_start, multiplicand_q, multiplier_q) is
    begin
    
        count_s_next <= count_s;
    
        case state_reg is
          when IDLE =>
            count_s_next <= "00000";
            if(ba_start='1') then
              ctrl_multiplicand <= "11";  --load
              ctrl_multiplier <= "11";  --load
              state_next <= MUL;
            else  
              state_next <= IDLE;
            end if;
          
          when MUL =>
            
            
        
        end case;
    
    
    end process control_proc;



end Behavioral;
