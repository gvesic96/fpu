----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2025 05:58:16 PM
-- Design Name: 
-- Module Name: mux2on1 - Behavioral
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

entity mux2on1 is
    Generic (WIDTH : positive := 32);
    Port ( x0 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           x1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           sel : in STD_LOGIC;
           
           y : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
           );
end mux2on1;

architecture Behavioral of mux2on1 is

begin

    mux2on1 : process (x0,x1,sel) is
    begin
        if(sel='0') then
          y <= x0;
        else
          y <= x1;
        end if;
    
    end process mux2on1;



end Behavioral;
