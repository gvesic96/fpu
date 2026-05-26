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
           exp_reg_en : in STD_LOGIC;
           sa_sel : in STD_LOGIC;
           
           ba_start : in STD_LOGIC;
           ba_rdy : out STD_LOGIC;
           
           mres_sel : in STD_LOGIC;
           
           norm_block_en : in STD_LOGIC;
           
           result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
           
    );
end data_path_fp_mul;

architecture Structural of data_path_fp_mul is


    --signals inside datapath
    signal op1_s, op2_s : STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    signal op1_exp_s, op2_exp_s : STD_LOGIC_VECTOR(WIDTH_EXP-1 downto 0);
    signal op1_fract_s, op2_fract_s : STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0);
    signal exp_val_s, sa_result_s : STD_LOGIC_VECTOR(WIDTH_EXP downto 0);
    signal op1_fract_ext_s, op2_fract_ext_s : STD_LOGIC_VECTOR(WIDTH_FRACT downto 0);
    signal ba_result_s, round_fract_res_s, norm_block_in_s : STD_LOGIC_VECTOR(2*WIDTH_FRACT-1 downto 0);
    signal norm_block_res_s : STD_LOGIC_VECTOR(WIDTH_FRACT+2 downto 0);
    
    
begin

    
    op1_exp_s <= op1_s(WIDTH-2 downto WIDTH_FRACT);
    op2_exp_s <= op2_s(WIDTH-2 downto WIDTH_FRACT);
    
    op1_fract_s <= op1_s(WIDTH_FRACT-1 downto 0);
    op2_fract_s <= op2_s(WIDTH_FRACT-1 downto 0);

    ------------------------------------------------
    --extended inputs for BIG_ALU - 24 bits in total
    op1_fract_ext_s <= '1'&op1_fract_s;
    op2_fract_ext_s <= '1'&op2_fract_s;


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
                 en => exp_reg_en,
                 d => sa_result_s,
                 q => exp_val_s
        );

    
    big_alu_mul: entity work.fp_mul_big_alu(Structural)
        generic map(WIDTH => WIDTH_FRACT+1,
                    WIDTH_COUNTER => 5
                    )
        port map(clk => clk,
                 rst => rst,
                 ba_start => ba_start,
                 op1 => op1_fract_ext_s,
                 op2 => op2_fract_ext_s,
                 rdy => ba_rdy,
                 result => ba_result_s
        );

    mux_norm_fract: entity work.mux2on1(Behavioral)
        generic map(WIDTH => 2*WIDTH)
        port map(x0 => ba_result_s,
                 x1 => round_fract_res_s,
                 sel => mres_sel,
                 y => norm_block_in_s
        );

    
    norm_block : entity work.fp_mul_norm_block(Behavioral)
        generic map(WIDTH => WIDTH_FRACT+1)
        port map(en => norm_block_en,
                 fract_in => ba_result_s,
                 fract_out => norm_block_res_s
        );


end Structural;
