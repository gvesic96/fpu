----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/07/2026 01:13:41 AM
-- Design Name: 
-- Module Name: fp_mul - Structural
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

entity fp_mul is
    Generic ( WIDTH : positive := 32;
              WIDTH_EXP : positive := 8;
              WIDTH_FRACT : positive := 23;
              WIDTH_GRS : positive := 3
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           start : in STD_LOGIC;
           op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           
           result : out STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           rdy : out STD_LOGIC
    );
end fp_mul;

architecture Structural of fp_mul is

begin



  --ovde je potrebno instancirati control_path_fp_mul i data_path_fp_mul i povezati ih

    fp_mul_control_path: entity work.control_path_fp_mul(Behavioral)
        port map(clk => clk,
                 rst => rst
        );




    fp_mul_data_path: entity work.data_path_fp_mul(Structural)
        port map(clk => clk,
                 rst => rst
        );



















end Structural;
