----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/20/2026 01:45:49 PM
-- Design Name: 
-- Module Name: fp_mul_ba_alu - Behavioral
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

entity fp_mul_ba_alu is
    Generic(WIDTH : positive := 8);
    Port ( op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           en : in STD_LOGIC;
           result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
           );
end fp_mul_ba_alu;

architecture Behavioral of fp_mul_ba_alu is

    signal result_s : unsigned(WIDTH-1 downto 0) := (others=>'0');
    
begin

    alu: process (op1, op2, en) is
    begin
        if(en='1') then
          result_s <= unsigned(op1) + unsigned(op2);
        else
          result_s <= (others=>'0');
        end if;
    end process alu;

    result <= std_logic_vector(result_s(WIDTH-1 downto 0));

end Behavioral;
