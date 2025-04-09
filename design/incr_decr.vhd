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
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           ctrl : in STD_LOGIC_VECTOR(1 downto 0);
           
           result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0)
           );
end incr_decr;

architecture Behavioral of incr_decr is

    signal q_s : unsigned(WIDTH-1 downto 0);

begin

    increment_decrement_proc: process (clk, rst) is
    begin
        if(rst = '1') then
          q_s <= (others => '0');
        else
          if(rising_edge(clk)) then
            case ctrl is
              when "00" =>
                --hold
                q_s <= q_s;
              when "01" =>
                --increment
                q_s <= q_s + 1;
              when "10" =>
                --decrement
                q_s <= q_s - 1;
              when others =>
                --load
                q_s <= unsigned(op1);
            end case;
          end if;
        end if;
        
        result <= std_logic_vector(q_s);
        
    end process increment_decrement_proc;


end Behavioral;
