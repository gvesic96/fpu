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
           
           en_product : in STD_LOGIC;
           
           en_multiplicand : in STD_LOGIC;
           d0_fsm_multiplicand : in STD_LOGIC;
           ctrl_multiplicand : in STD_LOGIC_VECTOR(1 downto 0);
           
           en_multiplier : in STD_LOGIC;
           d0_fsm_multiplier : in STD_LOGIC;
           ctrl_multiplier : in STD_LOGIC_VECTOR(1 downto 0);
           
           ba_alu_en : in STD_LOGIC;
           
           q_multiplicand : out STD_LOGIC_VECTOR(2*WIDTH-1 downto 0);
           q_multiplier : out STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           
           ba_result : out STD_LOGIC_VECTOR(2*WIDTH-1 downto 0)
           );
end fp_mul_big_alu_dp;

architecture Structural of fp_mul_big_alu_dp is

    signal q_multiplicand_s : STD_LOGIC_VECTOR(2*WIDTH-1 downto 0);
    signal q_multiplier_s : STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    signal d_product_s, q_product_s : STD_LOGIC_VECTOR(2*WIDTH-1 downto 0);

begin
    
    
    ba_result <= q_product_s;
    
    multiplicand: entity work.shift_reg_d0(Behavioral)
        generic map(WIDTH => 2*WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => en_multiplicand,
                 ctrl => ctrl_multiplicand,
                 d0_fsm => d0_fsm_multiplicand,
                 d => op1_multiplicand,
                 q => q_multiplicand_s
        );
        
    
    mulptiplier: entity work.shift_reg_d0(Behavioral)
        generic map(WIDTH => WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => en_multiplier,
                 ctrl => ctrl_multiplier,
                 d0_fsm => d0_fsm_multiplier,
                 d => op2_multiplier,
                 q => q_multiplier_s
        );
    
    product: entity work.d_reg(Behavioral)
        generic map(WIDTH => 2*WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => en_product,
                 d => d_product_s,
                 q => q_product_s
        );
    
    alu: entity work.fp_mul_ba_alu(Behavioral)
        generic map(WIDTH => 2*WIDTH)
        port map(op1 => q_product_s,
                 op2 => q_multiplicand_s,
                 en => ba_alu_en,
                 result => d_product_s
        );
    

end Structural;
