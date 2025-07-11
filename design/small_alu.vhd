----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2025 07:48:14 PM
-- Design Name: 
-- Module Name: small_alu - Behavioral
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

entity small_alu is
    Generic ( WIDTH : positive := 32);
    Port ( op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           result : out STD_LOGIC_VECTOR(WIDTH downto 0)--9 bita za izlas SMALL ALUa zbog znaka po kome odredjuje da li je broj pozitivan ili negativan
           );
end small_alu;

architecture Behavioral of small_alu is

    --signal result_s : unsigned(WIDTH downto 0) := (others=>'0'); --jedan bit vise u odnosu na ulaz exp je 8 bita a medjurezultat treba 9 zbog komplementa dvojke
    --zbog komplementa dvojke je neophodan jos jedan dodatni bit jer su ulazi unsigned odnosno biased vrednosti od 0 do 255
begin
    

    --small alu mora imati izlaz od 9 bita ako je WIDTH 8, result ce biti 8 downto 0 sto je 9 bita
    result <= std_logic_vector(unsigned('0' & op1) + (not(unsigned('0' & op2))+1));
    --result <= std_logic_vector(result_s(WIDTH-1 downto 0));


end Behavioral;
