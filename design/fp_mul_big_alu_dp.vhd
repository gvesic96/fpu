----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/15/2026 07:15:43 PM
-- Design Name: 
-- Module Name: fp_mul_big_alu_dp - Structural
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

entity fp_mul_big_alu_dp is
    Generic(WIDTH : positive := 32);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           
           op1_multiplicand : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2_multiplier : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           
           product_en : in STD_LOGIC;
           
           multiplicand_en : in STD_LOGIC;
           multiplicand_d0_fsm : in STD_LOGIC;
           multiplicand_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
           
           multiplier_en : in STD_LOGIC;
           multiplier_d0_fsm : in STD_LOGIC;
           multiplier_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
           
           ba_alu_en : in STD_LOGIC;
           
           multiplicand_q : out STD_LOGIC_VECTOR(2*WIDTH-1 downto 0);
           multiplier_q : out STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           
           ba_result : out STD_LOGIC_VECTOR(2*WIDTH-1 downto 0)
           );
end fp_mul_big_alu_dp;

architecture Structural of fp_mul_big_alu_dp is

    signal multiplicand_q_s : STD_LOGIC_VECTOR(2*WIDTH-1 downto 0);
    signal multiplier_q_s : STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    signal product_d_s, product_q_s : STD_LOGIC_VECTOR(2*WIDTH-1 downto 0);
    signal op1_multiplicand_s : STD_LOGIC_VECTOR(2*WIDTH-1 downto 0);

begin
    
    op1_multiplicand_s <= x"000000" & op1_multiplicand;
    ba_result <= product_q_s;
    
    multiplicand_q <= multiplicand_q_s;
    multiplier_q <= multiplier_q_s;
    
    multiplicand: entity work.shift_reg_d0(Behavioral)
        generic map(WIDTH => 2*WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => multiplicand_en,
                 ctrl => multiplicand_ctrl,
                 d0_fsm => multiplicand_d0_fsm,
                 d => op1_multiplicand_s,
                 q => multiplicand_q_s
        );
        
    
    mulptiplier: entity work.shift_reg_d0(Behavioral)
        generic map(WIDTH => WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => multiplier_en,
                 ctrl => multiplier_ctrl,
                 d0_fsm => multiplier_d0_fsm,
                 d => op2_multiplier,
                 q => multiplier_q_s
        );
    
    product: entity work.d_reg(Behavioral)
        generic map(WIDTH => 2*WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => product_en,
                 d => product_d_s,
                 q => product_q_s
        );
    
    alu: entity work.fp_mul_ba_alu(Behavioral)
        generic map(WIDTH => 2*WIDTH)
        port map(op1 => product_q_s,
                 op2 => multiplicand_q_s,
                 en => ba_alu_en,
                 result => product_d_s
        );
    

end Structural;
