----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/07/2026 01:04:54 AM
-- Design Name: 
-- Module Name: data_path_fp_mul - Behavioral
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

entity data_path_fp_mul is
    Generic ( WIDTH : positive := 32;
              WIDTH_EXP : positive := 8;
              WIDTH_FRACT : positive := 23;
              WIDTH_GRS : positive := 3
    );
    Port ( rst : in STD_LOGIC;
           clk : in STD_LOGIC;
           op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           
           operands_en : in STD_LOGIC;
           sa_sel : in STD_LOGIC;
           
           
           --rdy : out STD_LOGIC;
           result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
           
    );
end data_path_fp_mul;

architecture Structural of data_path_fp_mul is


    
    signal op1_s, op2_s : STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    signal op1_exp_s, op2_exp_s : STD_LOGIC_VECTOR(WIDTH_EXP-1 downto 0);
    signal op1_fract_s, op2_fract_s : STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0);
    signal exp_val_s, sa_result_s : STD_LOGIC_VECTOR(WIDTH_EXP downto 0);
    
    
begin

    
    op1_exp_s <= op1_s(WIDTH-2 downto WIDTH_FRACT);
    op2_exp_s <= op2_s(WIDTH-2 downto WIDTH_FRACT);
    

    op1_reg: entity work.d_reg(Behavioral)
        generic map(WIDTH => WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => operands_en,
                 d => op1,
                 q => op1_s
        );

    op2_reg: entity work.d_reg(behavioral)
        generic map(WIDTH => WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => operands_en,
                 d => op2,
                 q => op2_s
        );


    small_alu: entity work.small_alu(Behavioral)
        generic map(WIDTH => WIDTH_EXP)
        port map(op1 => op1_exp_s,
                 op2 => op2_exp_s,
                 sel => sa_sel,
                 result => sa_result_s
        );       
        
    exp_reg: entity work.d_reg(Behavioral)
        generic map(WIDTH => WIDTH_EXP+1)
        port map(clk => clk,
                 rst => rst,
                 d => sa_result_s,
                 q => exp_val_s
        );

    











end Structural;
