----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/09/2025 06:13:22 PM
-- Design Name: 
-- Module Name: add_module - Behavioral
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

entity add_module is
    Generic (WIDTH : positive := 32;
             WIDTH_EXP : positive := 8;
             WIDTH_FRACT : positive := 23;
             WIDTH_GRS : positive := 3
             );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           start : in STD_LOGIC;
           
           rdy : out STD_LOGIC;
           result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
           );
end add_module;

architecture Behavioral of add_module is

    --signals from data_path to control_path
    signal ed_val_s : STD_LOGIC_VECTOR(WIDTH_EXP downto 0); --9 bits, 8 downto 0
    --signal big_alu_carry_s : STD_LOGIC;
    signal round_carry_s, round_rdy_s : STD_LOGIC;
    signal ba_carry_s : STD_LOGIC;
    signal op1_sign_s, op2_sign_s : STD_LOGIC;
    signal op1_fract_s, op2_fract_s : STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0);

    --signals from control_path to data_path
    signal op_en_s, ed_reg_en_s, shift_r_d0_s : STD_LOGIC;
    signal shift_r_ctrl_s, inc_dec_ctrl_s, nreg_ctrl_s : STD_LOGIC_VECTOR(1 downto 0);
    signal mfract_1_sel_s, mfract_2_sel_s, mexp_sel_top_s, mexp_sel_bot_s, mres_sel_s : STD_LOGIC;
    signal ba_en_s, ba_sel_s : STD_LOGIC;
    signal shift_flag_s : STD_LOGIC;
    
    signal nreg_d0_s : STD_LOGIC;
    signal round_en_s : STD_LOGIC;
    signal oreg_en_s : STD_LOGIC;
    signal res_sign_s : STD_LOGIC;
    
begin

    control_path: entity work.control_path_add(Behavioral)
        port map(clk => clk,
                 rst => rst,
                 start => start,
                 operands_en => op_en_s,
                 
                 op1_sign => op1_sign_s,
                 op1_fract => op1_fract_s,
                 op2_sign => op2_sign_s,
                 op2_fract => op2_fract_s,
                 
                 ed_val => ed_val_s,
                 ed_reg_en => ed_reg_en_s,
                 big_alu_carry => ba_carry_s,
                 --shift_r_en => shift_r_en_s,
                 shift_r_d0 => shift_r_d0_s,
                 shift_r_ctrl => shift_r_ctrl_s,
                 shift_flag => shift_flag_s,
                 mfract_1_sel => mfract_1_sel_s,
                 mfract_2_sel => mfract_2_sel_s,
                 mux_exp_sel_top => mexp_sel_top_s,
                 mux_exp_sel_bot => mexp_sel_bot_s,
                 inc_dec_ctrl => inc_dec_ctrl_s,
                 big_alu_en => ba_en_s,
                 big_alu_sel => ba_sel_s,
                 mres_sel => mres_sel_s,
                 norm_reg_ctrl => nreg_ctrl_s,
                 norm_reg_d0 => nreg_d0_s,
                 round_en => round_en_s,
                 round_rdy => round_rdy_s,
                 round_carry => round_carry_s,--iz data_patha u control_path
                 res_sign => res_sign_s,
                 output_reg_en => oreg_en_s,
                 rdy => rdy
        );

    data_path : entity work.data_path_add(Structural)
        generic map(WIDTH => WIDTH,
                    WIDTH_EXP => WIDTH_EXP,
                    WIDTH_FRACT => WIDTH_FRACT,
                    WIDTH_GRS => WIDTH_GRS
                    )
        port map(clk => clk,
                 rst => rst,
                 op1 => op1,
                 op2 => op2,
                 
                 op1_sign => op1_sign_s,
                 op1_fract => op1_fract_s,
                 op2_sign => op2_sign_s,
                 op2_fract => op2_fract_s,
                 
                 op_reg_en => op_en_s,
                 ed_reg_en => ed_reg_en_s,
                 mexp_sel_top => mexp_sel_top_s,
                 mexp_sel_bot => mexp_sel_bot_s,
                 mfract_1_sel => mfract_1_sel_s,
                 mfract_2_sel => mfract_2_sel_s,
                 mres_sel => mres_sel_s,
                 
                 inc_dec_ctrl => inc_dec_ctrl_s,
                 
                 shift_r_ctrl => shift_r_ctrl_s,
                 shift_r_d0 => shift_r_d0_s,
                 shift_flag => shift_flag_s,
                 
                 ba_en => ba_en_s,
                 ba_sel => ba_sel_s,
                 --ba_result => ba_result_s, --ba_result je verovatno suvisan signal
                 ba_carry => ba_carry_s,
                 norm_reg_ctrl => nreg_ctrl_s,
                 norm_reg_d0 => nreg_d0_s,
                 round_en => round_en_s,
                 output_reg_en => oreg_en_s,
                 res_sign => res_sign_s,
                 
                 ed_val => ed_val_s,
                 round_rdy => round_rdy_s,
                 round_carry => round_carry_s,
                 result => result
                    
        );

end Behavioral;
