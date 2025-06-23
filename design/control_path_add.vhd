----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2025 08:41:19 PM
-- Design Name: 
-- Module Name: control_path_add - Behavioral
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

entity control_path_add is
  Port (clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        start : in STD_LOGIC;
        ed_val : in STD_LOGIC_VECTOR(7 downto 0);
        fraction_val : in STD_LOGIC_VECTOR(7 downto 0);
        big_alu_out : in STD_LOGIC_VECTOR(22 downto 0);
        
        
        shift_r_en : out STD_LOGIC;
        shift_r_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
        mux_exp_1 : out STD_LOGIC;
        mux_exp_2 : out STD_LOGIC;
        
        
        mux_exp_sel_top : out STD_LOGIC;
        mux_exp_sel_bot : out STD_LOGIC;
        inc_dec_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
        
        big_alu_en : out STD_LOGIC;
        big_alu_sel : out STD_LOGIC;
        
        round_ctrl : out STD_LOGIC
        
   );
end control_path_add;

architecture Behavioral of control_path_add is
    type add_state_type is (IDLE, EXP_COMPARE, SHIFT_SMALLER, FRACTION_ADD, NORM, ROUND, READY_STATE);
    signal state_next, state_reg : add_state_type;
    
begin

    state_proc: process(clk, rst) is
    begin
        if(rst='1') then
          state_reg <= IDLE;
        else
          if(clk'event and clk='1') then
            state_reg <= state_next;
          end if;
        end if;
    end process state_proc;

    control_proc: process(state_reg, start) is --za milijev automat treba dodati signale u sensitivity listu
    begin
        case state_reg is
          when IDLE =>
            if(start='1') then
              state_next<=EXP_COMPARE;
            else
              state_next<=IDLE;
            end if;
          when EXP_COMPARE =>
            if(unsigned(ed_val)=0) then
              shift_r_en <= '1'; --enabluje shift registar i sa 11 se ucita vrednost u njega
              shift_r_ctrl <= "11"; --ucita vrednost u shift registar
              big_alu_en <= '1'; --enable big alu
              big_alu_sel <= '0'; --selektuje operaciju sabiranja op1 i op2
              
              mux_exp_sel_top <= '0'; --selektuje eksponent op1 (moze i '1' za op2 svejedno je jer su jednaki)
              mux_exp_sel_bot <= '0'; --selektuje eksponent iz ulaznog broja (sa '1' bi selektovao eksponent iz round bloka)
              inc_dec_ctrl <= "11"; --ucita vrednost selektovanog eksponenta
              
              state_next <= FRACTION_ADD;
            else
              shift_r_en <= '1';
              if(unsigned(ed_val)>0) then
                
              end if;
            end if;
            
            
            
          when FRACTION_ADD =>
        end case;
    
    
    end process control_proc;





end Behavioral;
