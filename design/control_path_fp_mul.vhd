----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/07/2026 01:04:54 AM
-- Design Name: 
-- Module Name: control_path_fp_mul - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity control_path_fp_mul is
    Generic (WIDTH : positive := 32;
             WIDTH_EXP : positive := 8;
             WIDTH_FRACT : positive := 23
            );
    Port ( rst : in STD_LOGIC;
           clk : in STD_LOGIC;
           start : in STD_LOGIC;

           op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);

           
           operands_en : out STD_LOGIC;
           sa_sel : out STD_LOGIC
           
           );
end control_path_fp_mul;

architecture Behavioral of control_path_fp_mul is

    type mul_state_type is (IDLE, INPUT_CHECK, MUL, NORM, ROUND, READY);
    signal state_next, state_reg : mul_state_type;

    signal op1_exp_s, op2_exp_s : STD_LOGIC_VECTOR(WIDTH_EXP-1 downto 0) := (others=>'0');
    signal op1_fract_s, op2_fract_s : STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0) := (others=>'0');
    signal op1_sign_s, op2_sign_s : STD_LOGIC;

begin


    op1_sign_s <= op1(WIDTH-1);
    op1_exp_s <=  op1(WIDTH-2 downto WIDTH_FRACT);
    op1_fract_s <= op1(WIDTH_FRACT-1 downto 0);
    
    op2_sign_s <= op2(WIDTH-1);
    op2_exp_s <=  op2(WIDTH-2 downto WIDTH_FRACT);
    op2_fract_s <= op2(WIDTH_FRACT-1 downto 0);


    state_proc: process(clk,rst) is
    begin
        if(rst='1') then
        
        else
          if(clk'event and clk='1') then
            state_reg <= state_next;
          end if;
        
        end if;
    
    end process state_proc;




    control_proc: process(state_reg, op1, op2) is
    begin
        
        operands_en <= '0';
        sa_sel <= '0';
        
        
        
        case state_reg is
          when IDLE =>
            if(start='1') then
              state_next <= INPUT_CHECK;
              operands_en <= '1';
              --small_alu_sel <= '0';
            else
              state_next<=IDLE;
            end if;
          
          when INPUT_CHECK =>
            --ispitati ulaze i odrediti znak i eventualno preci u stanja
            sa_sel <= '0';
            exp_reg_en <= '1';
            
            if() then

            end if;
        
        
        end case;
    end process control_proc;











end Behavioral;
