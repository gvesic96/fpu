----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2025 08:41:55 PM
-- Design Name: 
-- Module Name: data_path_add - Structural
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

entity data_path_add is
  Generic(WIDTH : positive := 32;
          WIDTH_EXP : positive := 8;
          WIDTH_FRACT : positive := 23;
          WIDTH_GRS : positive := 3
  );
  Port (clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
        op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
        
        op_reg_en : in STD_LOGIC;
        ed_reg_en : in STD_LOGIC;
        mexp_sel_top : in STD_LOGIC;
        mexp_sel_bot : in STD_LOGIC;
        mfract_1_sel : in STD_LOGIC;
        mfract_2_sel : in STD_LOGIC;
        mres_sel : in STD_LOGIC;
        inc_dec_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
        --round_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
        shift_r_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
        shift_r_d0 : in STD_LOGIC;
        
        ba_en : in STD_LOGIC;
        ba_sel : in STD_LOGIC;
        --ba_result : out STD_LOGIC_VECTOR(WIDTH_FRACT + WIDTH_GRS - 1 downto 0); --JEDNAKO SA EXTENDED_WIDTH_FRACT-1
        ba_carry : out STD_LOGIC;
        
        norm_reg_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
        norm_reg_d0 : in STD_LOGIC;
        --norm_reg_en : in STD_LOGIC; --SUVISAN SIGNAL? TREBA GA UKLONITI IZ Control_Patha ?
        
        round_en : in STD_LOGIC;
        
        
        output_reg_en : in STD_LOGIC;
        
        ed_val : out STD_LOGIC_VECTOR(WIDTH_EXP downto 0); --9 bits, 8 downto 0
        
        round_rdy : out STD_LOGIC;
        round_carry : out STD_LOGIC;
        
        result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
        
        
   );
end data_path_add;

architecture Structural of data_path_add is

    constant EXT_WIDTH_FRACT : positive := WIDTH_FRACT + WIDTH_GRS;

    signal op1_s, op2_s : STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    --signal op_en_s : STD_LOGIC;
    signal ed_val_s : STD_LOGIC_VECTOR(WIDTH_EXP downto 0); --9 bits signal, 8 downto 0
    signal op1_fract_s, op2_fract_s : STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0);
    
    signal fract_ext_1_s, fract_ext_2_s : STD_LOGIC_VECTOR(EXT_WIDTH_FRACT-1 downto 0);
    signal fract_1_s, fract_2_s : STD_LOGIC_VECTOR(EXT_WIDTH_FRACT-1 downto 0);
   
    signal ba_op_1_s, ba_op_2_s, ba_result_s : STD_LOGIC_VECTOR(EXT_WIDTH_FRACT-1 downto 0); 
    signal norm_reg_in_s, norm_reg_out_s : STD_LOGIC_VECTOR(EXT_WIDTH_FRACT-1 downto 0);
    signal round_fract_res_s : STD_LOGIC_VECTOR(EXT_WIDTH_FRACT-1 downto 0);
    
    signal exp_1_s, exp_2_s, exp_selected_s, exp_s, round_exp_out_s, round_exp_in_s : STD_LOGIC_VECTOR(WIDTH_EXP-1 downto 0);
    
    signal final_result_s : STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    
begin

    op1_fract_s <= op1_s(22 downto 0);
    op2_fract_s <= op2_s(22 downto 0);
    
    exp_1_s <= op1_s(30 downto 23);
    exp_2_s <= op2_s(30 downto 23);
    
    ba_op_2_s <= fract_2_s; -- drugi operand za BIG ALU koji nije pomeran



    operand_1_reg: entity work.d_reg(Behavioral)
        generic map(WIDTH => WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => op_reg_en,
                 d => op1,
                 q => op1_s
        );

    operand_2_reg: entity work.d_reg(Behavioral)
        generic map(WIDTH => WIDTH)
        port map(clk =>clk,
                 rst => rst,
                 en => op_reg_en,
                 d => op2,
                 q => op2_s
        );

    small_alu: entity work.small_alu(Behavioral)
        generic map(WIDTH => WIDTH_EXP)
        port map(op1 => op1_s(30 downto 23),
                 op2 => op2_s(30 downto 23),
                 result => ed_val_s
        );

    ed_register: entity work.d_reg(Behavioral)
        generic map(WIDTH => WIDTH_EXP+1)
        port map(clk => clk,
                 rst => rst,
                 en => ed_reg_en,
                 d => ed_val_s,
                 q => ed_val
        );

    --multiplekseri se mogu pisati pomocu selecta da bi bilo preglednije
    
    --RAD SA FRAKCIJAMA
    --prosirenje na 26 bita, 3 dodatna bita za GRS
    fract_ext_1: entity work.fract_extender(Behavioral)
        generic map(WIDTH => WIDTH_FRACT)
        port map(fract_in => op1_fract_s,
                 fract_ext_out => fract_ext_1_s
        );
    fract_ext_2: entity work.fract_extender(Behavioral)
        generic map(WIDTH => WIDTH_FRACT)
        port map(fract_in => op2_fract_s,
                 fract_ext_out => fract_ext_2_s
        );
    
    
    --selekcija frakcije operanda ciji je eksponent manji
    mux_fract_1: entity work.mux2on1(Behavioral)
        generic map(WIDTH => EXT_WIDTH_FRACT)
        port map(x0 => fract_ext_1_s,
                 x1 => fract_ext_2_s,
                 sel => mfract_1_sel,
                 y => fract_1_s
        );
    
    mux_fract_2: entity work.mux2on1(Behavioral)
        generic map(WIDTH => EXT_WIDTH_FRACT)
        port map(x0 => fract_ext_1_s,
                 x1 => fract_ext_2_s,
                 sel => mfract_2_sel,
                 y => fract_2_s
        );
    
    shift_right_reg: entity work.shift_reg_d0(Behavioral)
        generic map(WIDTH => EXT_WIDTH_FRACT)
        port map(clk => clk,
                 rst => rst,
                 ctrl => shift_r_ctrl,
                 d => fract_1_s,
                 d0_fsm => shift_r_d0,
                 q => ba_op_1_s -- izmeniti
        );--treba izmeniti dizajn da se resi problem dodatnih GRS bita u shift registru SHIFT_R

    big_alu: entity work.big_alu(Behavioral)
        generic map(WIDTH => EXT_WIDTH_FRACT)
        port map(op1 => ba_op_1_s,
                 op2 => ba_op_2_s,
                 sel => ba_en,
                 en => ba_sel,
                 carry => ba_carry,
                 result => ba_result_s
        );
        
    --ba_result <= ba_result_s;
    
    mux_norm_fract: entity work.mux2on1(Behavioral)
        generic map(WIDTH => EXT_WIDTH_FRACT)
        port map(x0 => ba_result_s,
                 x1 => round_fract_res_s,
                 sel => mres_sel,
                 y => norm_reg_in_s
        );    
    
    norm_shift_reg: entity work.shift_reg_d0(Behavioral)
        generic map(WIDTH => EXT_WIDTH_FRACT)
        port map(clk => clk,
                 rst => rst,
                 ctrl => norm_reg_ctrl,
                 d0_fsm => norm_reg_d0,
                 d => norm_reg_in_s,
                 q => norm_reg_out_s
        );

    mux_exp_top: entity work.mux2on1(Behavioral)
        generic map(WIDTH => WIDTH_EXP)
        port map(x0 => exp_1_s,
                 x1 => exp_2_s,
                 sel => mexp_sel_top,
                 y => exp_selected_s
        );

    mux_exp_bot: entity work.mux2on1(Behavioral)
        generic map(WIDTH => WIDTH_EXP)
        port map(x0 => exp_selected_s,
                 x1 => round_exp_out_s,
                 sel => mexp_sel_bot,
                 y => exp_s
        );

    incr_decr_block: entity work.incr_decr(Behavioral)
        generic map(WIDTH => WIDTH_EXP)
        port map(clk => clk,
                 rst => rst,
                 op1 => exp_s,
                 ctrl => inc_dec_ctrl,
                 result => round_exp_in_s
        );

    round_block: entity work.rounding_block(Behavioral)
        generic map(WIDTH_EXT_FRACT => WIDTH_FRACT + WIDTH_GRS,
                    WIDTH_EXP => WIDTH_EXP,
                    WIDTH_GRS => WIDTH_GRS
            )
        port map(en => round_en,
                 fract_in => norm_reg_out_s,
                 exp_in => round_exp_in_s,
                 fract_out => round_fract_res_s(EXT_WIDTH_FRACT-1 downto 0),
                 exp_out => round_exp_out_s,
                 round_rdy => round_rdy,
                 round_carry => round_carry
        );

    final_result_s <= '0' & round_exp_out_s & round_fract_res_s(EXT_WIDTH_FRACT-1 downto 3);

    output_reg: entity work.d_reg(Behavioral)
        generic map(WIDTH => WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => output_reg_en,
                 d => final_result_s,
                 q => result
        );

end Structural;
