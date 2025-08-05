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
          WIDTH_FRACT : positive := 23
  );
  Port (clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
        op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
        
        ed_reg_en : in STD_LOGIC;
        mexp_top_sel : in STD_LOGIC;
        mexp_bot_sel : in STD_LOGIC;
        mfract_1_sel : in STD_LOGIC;
        mfract_2_sel : in STD_LOGIC;
        mres_sel : in STD_LOGIC;
        inc_dec_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
        round_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
        shift_r_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
        shift_r_d0 : in STD_LOGIC;
        norm_reg_ctrl : in STD_LOGIC_VECTOR(1 downto 0);
        
        
        ed_val : out STD_LOGIC_VECTOR(WIDTH_EXP downto 1); --9 bits, 8 downto 0
        
        result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
        
   );
end data_path_add;

architecture Structural of data_path_add is

    signal op1_s, op2_s : STD_LOGIC_VECTOR(WIDTH-1 downto 0);
    signal op_en_s : STD_LOGIC;
    signal ed_val_s : STD_LOGIC_VECTOR(WIDTH_EXP downto 0); --9 bits signal, 8 downto 0
    signal op1_fract_s, op2_fract_s : STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0);
    signal fract_1_s, fract_2_s : STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0);
    signal shifted_fract_s : STD_LOGIC_VECTOR(WIDTH_FRACT+2 downto 0);
    
begin

    op1_fract_s <= op1_s(22 downto 0);
    op2_fract_s <= op2_s(22 downto 0);

    shifted_fract_s <= fract_1_s & "000";

    operand_1_reg: entity work.d_reg(Behavioral)
        generic map(WIDTH => WIDTH)
        port map(clk => clk,
                 rst => rst,
                 en => op_en_s,
                 d => op1,
                 q => op1_s
        );

    operand_2_reg: entity work.d_reg(Behavioral)
        generic map(WIDTH => WIDTH)
        port map(clk =>clk,
                 rst => rst,
                 en => op_en_s,
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
    
    mux_fract_1: entity work.mux2on1(Behavioral)
        generic map(WIDTH => WIDTH_FRACT)
        port map(x0 => op1_fract_s,
                 x1 => op2_fract_s,
                 sel => mfract_1_sel,
                 y => fract_1_s
        );
    
    mux_fract_2: entity work.mux2on1(Behavioral)
        generic map(WIDTH => WIDTH_FRACT)
        port map(x0 => op1_fract_s,
                 x1 => op2_fract_s,
                 sel => mfract_2_sel,
                 y => fract_2_s
        );
    
    shift_right_reg: entity work.shift_reg_d0(Behavioral)
        generic map(WIDTH => WIDTH_FRACT+3)
        port map(clk => clk,
                 rst => rst,
                 ctrl => shift_r_ctrl,
                 d <= shifted_fract_s, --OVDE IMA ERROR --NE MOZE DODELA VREDNOSTI SIGNALU I POSLE DODELA DRUGOM SIGNALU U ENTITY DEKLARACIJI !
                 d0 <= shift_r_d0,
                 q <= ba_op_1_s -- izmeniti
        );--treba izmeniti dizajn da se resi problem dodatnih GRS bita u shift registru SHIFT_R

end Structural;
