----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/08/2025 07:19:52 PM
-- Design Name: 
-- Module Name: fract_extender - Behavioral
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

entity fract_extender is
    Generic (WIDTH : positive := 23);
    Port ( fract_in : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
           fract_ext_out : out STD_LOGIC_VECTOR (WIDTH+2 downto 0));
end fract_extender;

architecture Behavioral of fract_extender is

begin

    fract_ext_out <= fract_in & "000";

end Behavioral;
