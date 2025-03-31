----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/27/2025 12:22:19 AM
-- Design Name: 
-- Module Name: d_reg - Behavioral
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

entity d_reg is
    Generic ( WIDTH : positive := 32);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           
           q : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
           );
end d_reg;

architecture Behavioral of d_reg is

begin

    d_reg_proc: process (clk, rst) is
    begin
        if(rst = '1') then
          q <= (others => '0');
        else
          if(clk'event and clk='1') then
            q <= d;
          end if;
        end if;
    
    end process d_reg_proc;


end Behavioral;
