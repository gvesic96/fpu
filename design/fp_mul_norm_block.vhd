----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/24/2026 09:42:24 PM
-- Design Name: 
-- Module Name: fp_mul_norm_block - Behavioral
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

entity fp_mul_norm_block is
    Generic (WIDTH : positive := 48;
             WIDTH_FRACT : positive := 23;
             WIDTH_GRS : positive := 3
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           fract_in : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           
           
           fract_out : out STD_LOGIC_VECTOR(WIDTH_FRACT+WIDTH_GRS-1 downto 0)
    
    );
end fp_mul_norm_block;

architecture Behavioral of fp_mul_norm_block is

    signal fract_in_s : STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0);
    signal guard_s, round_s, sticky_s : STD_LOGIC;
    signal fract_out_s : STD_LOGIC_VECTOR(WIDTH_FRACT+WIDTH_GRS-1 downto 0);
    
    
begin

    norm_process : process (en, fract_in) is
        begin
          if(en = '1') then
            if(fract_in(WIDTH-1 downto WIDTH-2)="10") then
              --sticky_s <= or fract_in(21 downto 0);
              sticky_s <= fract_in(21) or fract_in(20) or fract_in(19) or fract_in(18) or fract_in(17) or fract_in(16) or fract_in(15) or fract_in(14) or fract_in(13) or fract_in(12) or fract_in(11) or fract_in(10) or fract_in(9) or fract_in(8) or fract_in(7) or fract_in(6) or fract_in(5) or fract_in(4) or fract_in(3) or fract_in(2) or fract_in(1) or fract_in(0);
              fract_in_s <= fract_in(WIDTH-2 downto 24);
              guard_s <= fract_in(23);
              round_s <= fract_in(22);
            else
              --sticky_s <= or fract_in(20 downto 0);
              sticky_s <= fract_in(20) or fract_in(19) or fract_in(18) or fract_in(17) or fract_in(16) or fract_in(15) or fract_in(14) or fract_in(13) or fract_in(12) or fract_in(11) or fract_in(10) or fract_in(9) or fract_in(8) or fract_in(7) or fract_in(6) or fract_in(5) or fract_in(4) or fract_in(3) or fract_in(2) or fract_in(1) or fract_in(0);
              fract_in_s <= fract_in(WIDTH-3 downto 23);
              guard_s <= fract_in(22);
              round_s <= fract_in(21);
            end if;
          else
            fract_in_s <= (others=>'0');  
            guard_s <= '0';
            round_s <= '0';
            sticky_s <= '0';
          end if;
        end process norm_process;


    d_reg: process (rst, clk) is
        begin
          if(rst='1') then
            fract_out_s <= (others=>'0');
          else
            if(rising_edge(clk)) then
              fract_out_s <= fract_in_s & guard_s & round_s & sticky_s;
            end if;
          end if;
        end process d_reg;

    --normalized output fraction 26 bits wide
    --fract_out <= fract_in_s & guard_s & round_s & sticky_s;
    fract_out <= fract_out_s;
    
    
end Behavioral;
