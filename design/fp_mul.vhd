----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/07/2026 01:13:41 AM
-- Design Name: 
-- Module Name: fp_mul - Structural
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

entity fp_mul is
    Generic ( WIDTH : positive := 32;
              WIDTH_EXP : positive := 8;
              WIDTH_FRACT : positive := 23;
              WIDTH_GRS : positive := 3
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start : in STD_LOGIC;
           op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           
           fflags : out STD_LOGIC_VECTOR(4 downto 0);
           result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           rdy : out STD_LOGIC
    );
end fp_mul;

architecture Structural of fp_mul is


    --signals from control_path to data_path
    signal sa_sel_s, exp_reg_en_s, operands_en_s : STD_LOGIC;
    signal ba_en_s, ba_start_s, ba_rdy_s : STD_LOGIC;
    signal hidden_value_mux_x1_s : STD_LOGIC_VECTOR(1 downto 0);
    signal mres_sel_s : STD_LOGIC;
    signal norm_block_en_s : STD_LOGIC;
    signal incr_decr_en_s, mexp_sel_s : STD_LOGIC;
    signal incr_decr_ctrl_s : STD_LOGIC_VECTOR(1 downto 0);
    signal round_en_s : STD_LOGIC;
    signal output_reg_en_s : STD_LOGIC;
    signal res_sign_s : STD_LOGIC;
    
    --signals from data_path to control_path
    signal op1_s, op2_s : STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    signal exp_val_s : STD_LOGIC_VECTOR(WIDTH_EXP downto 0); --9bits
    signal hidden_value_mux_y_s : STD_LOGIC_VECTOR(1 downto 0);
    signal round_rdy_s, round_carry_s : STD_LOGIC;
    signal nx_flag_s : STD_LOGIC;
    

begin



  --ovde je potrebno instancirati control_path_fp_mul i data_path_fp_mul i povezati ih

    control_path: entity work.control_path_fp_mul(Behavioral)
        port map(clk => clk,
                 rst => rst,
                 start => start,
                 op1 => op1_s,
                 op2 => op2_s,
                 
                 operands_en => operands_en_s,
                 sa_sel => sa_sel_s,
                 
                 exp_val => exp_val_s,
                 exp_reg_en => exp_reg_en_s,
                 
                 ba_en => ba_en_s,
                 ba_start => ba_start_s,
                 ba_rdy => ba_rdy_s,
                 
                 hidden_value_in => hidden_value_mux_y_s,
                 hidden_value_out => hidden_value_mux_x1_s,
                 mres_sel => mres_sel_s,
                 norm_block_en => norm_block_en_s,
                 
                 mexp_sel => mexp_sel_s,
                 incr_decr_en => incr_decr_en_s,
                 incr_decr_ctrl => incr_decr_ctrl_s,
                 
                 round_en => round_en_s,
                 round_rdy => round_rdy_s,
                 round_carry => round_carry_s,
                 nx_flag_in => nx_flag_s,
                 
                 output_reg_en => output_reg_en_s,
                 
                 res_sign => res_sign_s,
                 
                 fflags => fflags,
                 rdy => rdy
           
        );




    data_path: entity work.data_path_fp_mul(Structural)
        port map(clk => clk,
                 rst => rst,
                 op1 => op1,
                 op2 => op2,
                 
                 res_sign => res_sign_s,
                 
                 operands_en => operands_en_s,
                 op1_q => op1_s,
                 op2_q => op2_s,
                 
                 exp_reg_en => exp_reg_en_s,
                 exp_val => exp_val_s,
                 sa_sel => sa_sel_s,
                 
                 ba_start => ba_start_s,
                 ba_rdy => ba_rdy_s,
                 
                 mres_sel => mres_sel_s,
                 
                 norm_block_en => norm_block_en_s,
                 hidden_value_mux_y => hidden_value_mux_y_s,
                 hidden_value_mux_x1 => hidden_value_mux_x1_s,
                 
                 mexp_sel => mexp_sel_s,
                 incr_decr_en => incr_decr_en_s,
                 incr_decr_ctrl => incr_decr_ctrl_s,
                 
                 round_en => round_en_s,
                 round_rdy => round_rdy_s,
                 round_carry => round_carry_s,
                 
                 nx_flag => nx_flag_s,
                 output_reg_en => output_reg_en_s,
                 result => result
        );



















end Structural;
