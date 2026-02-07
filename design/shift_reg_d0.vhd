----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2025 08:01:34 PM
-- Design Name: 
-- Module Name: shift_reg_d0 - Behavioral
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

entity shift_reg_d0 is
    Generic(WIDTH : positive := 32);
    Port ( clk : in std_logic;
           rst : in std_logic;
           en : in std_logic;
           ctrl : in std_logic_vector (1 downto 0);
           d : in std_logic_vector(WIDTH-1 downto 0);
           d0_fsm : in std_logic;
           
           q : out std_logic_vector(WIDTH-1 downto 0)
    
     );
end shift_reg_d0;

architecture Behavioral of shift_reg_d0 is
    signal q_s : std_logic_vector (WIDTH-1 downto 0) := (others=>'0');
begin

    shift_reg:process (rst, clk) is
    begin
      if(rst='1') then
        q_s <= (others => '0');
      elsif(clk'event and clk='1') then
        if(en='1') then
          case ctrl is
            when "00" =>
              --hold
              q_s <= q_s;
            when "01" =>
              --shift left
              q_s <= q_s(WIDTH-2 downto 0) & d0_fsm;
            when "10" =>
              --shift right
              q_s <= d0_fsm & q_s(WIDTH-1 downto 1);
            when others =>
              --load for value "11"
              q_s <= d;
          end case;
        else
          q_s <= (others=>'0');
        end if;
      end if;
    end process shift_reg;
    
    --passing the value of q_s to output
    q <= q_s;


end Behavioral;
