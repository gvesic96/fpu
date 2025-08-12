----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2025 06:27:35 PM
-- Design Name: 
-- Module Name: big_alu - Behavioral
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

entity big_alu is
    Generic ( WIDTH : positive := 23);
    Port ( op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           sel : in STD_LOGIC;
           en : in STD_LOGIC;
           
           carry : out STD_LOGIC; --ovaj carry cu omoguciti kasnije
           result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0));
end big_alu;

architecture Behavioral of big_alu is

    signal result_s: unsigned(WIDTH downto 0):= (others=>'0');  --uvodjenje ovog unutrasnjeg signala ce verovatno ubaciti latch kako bi memorisao stanje medjusignala?

begin

    alu: process (sel, op1, op2) is
    -- da li je enable signal neophodan u sensitivy listi?
    begin
      if(en = '1') then
        if(sel ='0') then
            
            --result <= std_logic_vector(unsigned(op1) + unsigned(op2));
            result_s <= ('0' & unsigned(op1)) + ('0' & unsigned(op2));
            
          else
            
            --result <= std_logic_vector(unsigned(op1) + (not(unsigned(op2))+1));
            result_s <= ('0' & (unsigned(op1)) + (not('0' & unsigned(op2)+1)));
  
        end if;
        carry <= std_logic(result_s(WIDTH)); --uzme msb kao carry out signal
      else
        result_s <= (others => '0');
        carry <= '0';
      end if;
      
    end process alu;

    result <= std_logic_vector(result_s(WIDTH-1 downto 0));

end Behavioral;
