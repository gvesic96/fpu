----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/15/2026 07:15:43 PM
-- Design Name: 
-- Module Name: fp_mul_big_alu - Structural
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

entity fp_mul_big_alu is
    Generic (WIDTH : positive := 24);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           ba_start : in STD_LOGIC;
           op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           
           result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
           );
end fp_mul_big_alu;

architecture Structural of fp_mul_big_alu is


    signal ba_result_s : std_logic_vector(2*WIDTH-1 downto 0);
    
    --signals from control_path to data_path
    signal product_en_s, multiplicand_en_s, multiplier_en_s : std_logic;
    signal d0_fsm_s : std_logic;
    --signal d0_fsm_multiplier_s, d0_fsm_multiplicand_s : std_logic;
    signal multiplier_ctrl_s, multiplicand_ctrl_s : std_logic_vector(1 downto 0);
    signal ba_alu_en_s : std_logic;
    
    --signals from data_path to control_path
    signal multiplier_q_s : std_logic_vector(WIDTH-1 downto 0);
    signal multiplicand_q_s : std_logic_vector(2*WIDTH-1 downto 0);
    
    

begin

    result <= ba_result_s;

    ba_control_path: entity work.fp_mul_big_alu_cp(Behavioral)
        generic map(WIDTH => WIDTH)
        port map(clk => clk,
                 rst => rst,
                 ba_start => ba_start,
                 d0_fsm => d0_fsm_s,
                 multiplicand_q => multiplicand_q_s,
                 multiplier_q => multiplier_q_s
        );



    ba_data_path: entity work.fp_mul_big_alu_dp(Structural)
        generic map(WIDTH => WIDTH)
        port map(clk => clk,
                 rst => rst,
                 
                 op1_multiplicand => op1,
                 op2_multiplier => op2,
                 
                 product_en => product_en_s, 
      
                 multiplicand_en => multiplicand_en_s,
                 multiplicand_d0_fsm => d0_fsm_s,
                 multiplicand_ctrl  => multiplicand_ctrl_s,
           
                 multiplier_en => multiplier_en_s,
                 multiplier_d0_fsm => d0_fsm_s,
                 multiplier_ctrl => multiplier_ctrl_s,
           
                 ba_alu_en => ba_alu_en_s,
           
                 multiplicand_q => multiplicand_q_s,
                 multiplier_q => multiplier_q_s,
                 ba_result => ba_result_s
        );




end Structural;
