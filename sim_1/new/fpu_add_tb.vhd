----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/13/2025 11:44:19 AM
-- Design Name: 
-- Module Name: fpu_add_tb - Behavioral
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

entity fpu_add_tb is
--  Port ( );
end fpu_add_tb;

architecture Behavioral of fpu_add_tb is

    constant width : positive := 32;
    constant width_fract : positive := 23;
    constant width_exp : positive := 8;
    constant width_grs : positive := 3;
    
    --component big_alu is
    --    generic(WIDTH :positive := width_fract+width_grs);
    --    port(op1 : in STD_LOGIC_VECTOR(width_fract+width_grs-1 downto 0);
    --         op2 : in STD_LOGIC_VECTOR(width_fract+width_grs-1 downto 0);
    --         sel : in STD_LOGIC;
    --         en : in STD_LOGIC;
    --         carry : out STD_LOGIC;
    --        result : out STD_LOGIC_VECTOR(width_fract+width_grs-1 downto 0));
    --end component big_alu;
    
    component add_module is
        Generic(WIDTH : positive := width;
                WIDTH_FRACT : positive := width_fract;
                WIDTH_EXP : positive := width_exp;
                WIDTH_GRS : positive := width_grs
        );
        Port(clk, rst : in std_logic;
             start : in STD_LOGIC;
             op1 : in STD_LOGIC_VECTOR(width-1 downto 0);
             op2 : in STD_LOGIC_VECTOR(width-1 downto 0);
             rdy : out STD_LOGIC;
             result : out STD_LOGIC_VECTOR(width-1 downto 0)
        );
    end component add_module;

    signal clk_s, rst_s : std_logic;
    signal op1_s, op2_s : std_logic_vector(width-1 downto 0);
    signal start_s, ready_s : std_logic;
    signal result_s : std_logic_vector(width-1 downto 0);

    --signal op1_ba_s, op2_ba_s, result_ba_s : STD_LOGIC_VECTOR(width_fract+width_grs-1 downto 0);
    --signal sel_ba_s, en_ba_s, carry_ba_s : STD_LOGIC;

begin

    --dut_ba: big_alu
    --port map(op1 => op1_ba_s,
    --         op2 => op2_ba_s,
    --         sel => sel_ba_s,
    --         en => en_ba_s,
    --         carry => carry_ba_s,
    --         result => result_ba_s);

    design_under_verification: add_module
        port map(
            clk => clk_s,
            rst => rst_s,
            start => start_s,
            op1 => op1_s,
            op2 => op2_s,
            rdy => ready_s,
            result => result_s
        );

    clk_gen:process
    begin
        clk_s <= '0', '1' after 100ns;
        wait for 200ns;    
    end process clk_gen;

    
    stim_gen:process
    begin
        rst_s <= '1', '0' after 50ns;
        --op1_s <= "00000000000000000000000000000000", "11001110101000110000010001000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op1_s <= "00000000000000000000000000000000", "11001010101000110000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op1_s <= "00000000000000000000000000000000", "00000000000000000000000000000000" after 50ns;
        
        --op2_s <= "00000000000000000000000000000000", "10000000000000000000000000000000" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "01001010101000110000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "01000010011000000010010100000001" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        
        --op1_s <= "00000000000000000000000000000000", "01000010011000000010010100000001" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "01000010111000000010010100000001" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --op1_s <= "00000000000000000000000000000000", "01000010000000000000000000000111" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "01000011111111111111111111111111" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        
        
        
        --dva obicna broja gde se dobije redovno resenje
        --op1_s <= "00000000000000000000000000000000", "01000010000000100100000000000111" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "11000011101101111011111111111111" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --dva broja u kojima dolazi do overflow-a
        --op1_s <= "00000000000000000000000000000000", "11111111000000100100000000000111" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "11111111011111111111111111111111" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --jedan obican broj i beskonacno
        --op1_s <= "00000000000000000000000000000000", "11011011000000100100000000000111" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "01111111100000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --dve nule, jedna pozitivna druga negativna
        --op1_s <= "00000000000000000000000000000000", "00000000000000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "10000000000000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --oba ulaza identicna inf
        --op1_s <= "00000000000000000000000000000000", "01111111100000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "01111111100000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --jedan ulaz -inf, drugi +inf, rezultat NaN
        --op1_s <= "00000000000000000000000000000000", "11111111100000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "01111111100000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --jedan ulaz inf, drugi nula
        --op1_s <= "00000000000000000000000000000000", "00000000000000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "01111111100000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --jedan obican broj i nula
        --op1_s <= "00000000000000000000000000000000", "00000000000000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "11000011101101111011111111111111" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --jedan ulaz NaN, drugi +inf, rezultat NaN
        --op1_s <= "00000000000000000000000000000000", "01111111110000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "01111111100000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --jedan ulaz NaN, drugi normalizovan broj, rezultat NaN
        --op1_s <= "00000000000000000000000000000000", "01111111110000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "01111100100101000100000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --jedan ulaz +inf, drugi normalizovan broj, rezultat +inf
        --op1_s <= "00000000000000000000000000000000", "01111111100000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", "01111100100101000100000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --round_carry testing
        --op1_s <= "00000000000000000000000000000000", x"021fffdf" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", x"01c00041" after 50ns;--"01000010000100000010010100000001" after 50ns;
      
      --some testing for case from JasperGold
        --op1_s <= "00000000000000000000000000000000", x"ffbfffff" after 50ns;--"01000010000100000010010100000001" after 50ns;
        --op2_s <= "00000000000000000000000000000000", x"007fffff" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        --op1=qNaN  op2=qNaN
        op1_s <= "00000000000000000000000000000000", "01111111110000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        op2_s <= "00000000000000000000000000000000", "01111111110000000000000000000000" after 50ns;--"01000010000100000010010100000001" after 50ns;
        
        start_s <= '0', '1' after 250ns, '0' after 350ns;
        
        
        --op1_ba_s <= "11000000010010100000001000";
        --op2_ba_s <= "11000000010010100000001000";
        --sel_ba_s <= '0';
        --en_ba_s <= '1';
        
        --carry_ba_s
        --result_ba_s
        wait;
    end process stim_gen;




end Behavioral;
