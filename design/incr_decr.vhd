----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2025 08:22:29 PM
-- Design Name: 
-- Module Name: incr_decr - Behavioral
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity incr_decr is
    Generic ( WIDTH : positive := 32);
    Port ( op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           sel : in STD_LOGIC;
           result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
           );
end incr_decr;

architecture Behavioral of incr_decr is

begin

    increment_decrement_proc: process (sel, op1) is
    begin
        if(sel = '0') then
          result <= std_logic_vector(unsigned(op1)+1);
        else
          result <= std_logic_vector(unsigned(op1)-1);
        end if;
    
    end process increment_decrement_proc;


end Behavioral;
