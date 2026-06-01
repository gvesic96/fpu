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
              WIDTH_GRS : positive := 3;
              WIDTH_BA_RESULT : positive := 48
    );
    Port ( rst : in STD_LOGIC;
           clk : in STD_LOGIC;
           op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           res_sign : in STD_LOGIC;
           
           operands_en : in STD_LOGIC;
           exp_reg_en : in STD_LOGIC;
           sa_sel : in STD_LOGIC;
           
           ba_start : in STD_LOGIC;
           ba_rdy : out STD_LOGIC;
           
           mres_sel : in STD_LOGIC;
           
           norm_block_en : in STD_LOGIC;
           
           mexp_sel : in STD_LOGIC;
           incr_decr_en : in STD_LOGIC;
           incr_decr_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
           
           round_en : in STD_LOGIC;
           round_rdy : out STD_LOGIC;
           round_carry : out STD_LOGIC;
           nx_flag : out STD_LOGIC;
           
           output_reg_en : in STD_LOGIC;
           
           result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
           
    );
end data_path_fp_mul;

architecture Structural of data_path_fp_mul is


    --signals inside datapath
    signal op1_s, op2_s : STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    signal op1_exp_s, op2_exp_s : STD_LOGIC_VECTOR(WIDTH_EXP-1 downto 0);
    signal op1_fract_s, op2_fract_s : STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0);
    signal sa_result_s, exp_val_s : STD_LOGIC_VECTOR(WIDTH_EXP downto 0); --9bits
    signal round_exp_out_s, round_exp_in_s, exp_s : STD_LOGIC_VECTOR(WIDTH_EXP-1 downto 0); --8bits
    signal op1_fract_ext_s, op2_fract_ext_s : STD_LOGIC_VECTOR(WIDTH_FRACT downto 0);
    signal ba_result_s, round_fract_res_s, norm_block_in_s : STD_LOGIC_VECTOR(WIDTH_BA_RESULT-1 downto 0); --48bits in total
    signal norm_block_res_s : STD_LOGIC_VECTOR(WIDTH_FRACT+WIDTH_GRS-1 downto 0);
    signal final_result_s : STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    signal round_fract_out_s : STD_LOGIC_VECTOR(WIDTH_FRACT+WIDTH_GRS-1 downto 0);
    signal round_carry_s : STD_LOGIC;
    
    
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

    round_fract_res_s <= round_carry_s & "0" & round_fract_out_s & x"00000";

    mux_norm_fract: entity work.mux2on1(Behavioral)
        generic map(WIDTH => WIDTH_BA_RESULT) --48 bits
        port map(x0 => ba_result_s,
                 x1 => round_fract_res_s,
                 sel => mres_sel,
                 y => norm_block_in_s
        );

    
    norm_block : entity work.fp_mul_norm_block(Behavioral)
        generic map(WIDTH => WIDTH_BA_RESULT, --48bits
                    WIDTH_FRACT => WIDTH_FRACT,
                    WIDTH_GRS => WIDTH_GRS
        )
        port map(en => norm_block_en,
                 fract_in => norm_block_in_s,
                 fract_out => norm_block_res_s
        );

    mux_exp: entity work.mux2on1(Behavioral)
        generic map(WIDTH => WIDTH_EXP)
        port map(x0 => exp_val_s(WIDTH_EXP-1 downto 0), --prosledjujem nizih 8 bita
                 x1 => round_exp_out_s,
                 sel => mexp_sel, --signal from control path
                 y => exp_s
                );
        
        
    incr_decr_block: entity work.incr_decr(Behavioral)
        generic map(WIDTH => WIDTH_EXP)
        port map(clk => clk,
                 rst => rst,
                 en => incr_decr_en,
                 op1 => exp_s,
                 ctrl => incr_decr_ctrl,
                 result => round_exp_in_s
        );


    round_block: entity work.rounding_block(Behavioral)
        generic map(WIDTH_EXT_FRACT => WIDTH_FRACT + WIDTH_GRS,
                    WIDTH_EXP => WIDTH_EXP,
                    WIDTH_GRS => WIDTH_GRS
            )
        port map(en => round_en,
                 fract_in => norm_block_res_s,
                 exp_in => round_exp_in_s,
                 fract_out => round_fract_out_s,
                 exp_out => round_exp_out_s,
                 round_rdy => round_rdy,
                 nx_flag => nx_flag,
                 round_carry => round_carry_s
        );
    
    round_carry <= round_carry_s;
    final_result_s <= res_sign & round_exp_out_s & round_fract_out_s(WIDTH_FRACT+WIDTH_GRS-1 downto 3);    
        
    output_reg: entity work.d_reg(Behavioral)
        generic map(WIDTH => WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => output_reg_en,
                 d => final_result_s,
                 q => result
        );
        
        
        
end Structural;
