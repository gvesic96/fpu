----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/26/2025 12:55:54 PM
-- Design Name: 
-- Module Name: rounding_block - Behavioral
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
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rounding_block is
    Generic ( WIDTH_FRACT : positive := 23;
              WIDTH_EXP : positive := 8);
    Port ( en : in STD_LOGIC;
           fract_in : in STD_LOGIC_VECTOR (WIDTH_FRACT+2 downto 0); --sirina je 23, 25 downto 0, ukupno 26 bita, dodatna 3 bita za guard i round bite
           exp_in : in STD_LOGIC_VECTOR (WIDTH_EXP-1 downto 0);
           
           fract_out : out STD_LOGIC_VECTOR (WIDTH_FRACT-1 downto 0); --frakcija je 23 bita sirine 22 downto 0
           exp_out : out STD_LOGIC_VECTOR (WIDTH_FRACT-1 downto 0);
           round_rdy : out STD_LOGIC;
           round_carry : out STD_LOGIC);
end rounding_block;

architecture Behavioral of rounding_block is
    
    signal round_s : unsigned(2 downto 0) := (others=>'0'); --3 bita za GUARD ROUND STICKY
    signal round_val_s : unsigned(WIDTH_FRACT downto 0) := (others=>'0'); --23 downto 0, ukupno 24 bita, zato sot ima dodatni bit na pocetku za overflow u slucaju zaokruzivanja
    
begin

    round_s <= unsigned(fract_in(2 downto 0));
    round_val_s <= '0' & unsigned(fract_in(WIDTH_FRACT+2 downto 3));

--TREBA PREPRAVITI, PRVO IMA 3 dodatna bita GUARD ROUND STICKY, za 100 kombinaciju je tacno izmedju 2 broja i radi se round to even
--round to even znaci da ako je ispred guard bita 1 onda ce biti dodat 1 i generisati carry kako bi LSB odnosno bit pre guarda postao 0
--ako je GRS 100 i bit ispred G bita, LSB, jednak 0, onda se ne dodaje nista nego se samo odbacuju GRS biti TRUNCATE i frakcija ostaje ista
--ako je GUARD ROUND EVEN 110 101 111 onda se dodaje 1 kao ROUND UP
--ako je GUARD 0 onda se ostavlja kako jeste odno samo se odbacuju GRS biti TRUNCATE    
    round_proc: process (round_s, round_val_s) is
    begin
      if(en='1') then
        case round_s is
          --round to even
          when "100" =>
            if(round_val_s(0)='0') then
              round_val_s <= round_val_s;
            else
              round_val_s <= round_val_s + 1;
            end if;
          --round up
          when "101" =>
            round_val_s <= round_val_s + 1;
          when "110" =>
            round_val_s <= round_val_s + 1;
          when "111" =>
            round_val_s <= round_val_s + 1;
          --truncate
          when others =>
            round_val_s <= round_val_s;
        end case;
        round_rdy <= '1';
      else
        round_rdy <= '0';
      end if;
    end process;

    round_carry <= std_logic(round_val_s(WIDTH_FRACT)); --carry out je potreban da se doda na hidden value, da bi se rezultat ponovo normalizovao
    fract_out <= std_logic_vector(round_val_s(WIDTH_FRACT-1 downto 0));
    exp_out <= exp_in;

end Behavioral;
