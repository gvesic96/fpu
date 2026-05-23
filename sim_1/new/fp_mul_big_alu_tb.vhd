----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/23/2026 12:39:57 AM
-- Design Name: 
-- Module Name: fp_mul_big_alu_tb - Behavioral
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

entity fp_mul_big_alu_tb is
--  Port ( );
end fp_mul_big_alu_tb;

architecture Behavioral of fp_mul_big_alu_tb is

--constant width_tb : integer := 64;
constant WIDTH : positive := 24;
    --instanciranje komponente
    --component shift_reg is
    --    Generic(WIDTH : integer := width_tb);
    --    Port(
    --        clk, rst : in std_logic;
    --        ctrl : in STD_LOGIC_VECTOR (1 downto 0);
    --        d : in STD_LOGIC_VECTOR (WIDTH-1 downto 0);
    --        q : out STD_LOGIC_VECTOR (WIDTH-1 downto 0)
    --        );
    --end component shift_reg;
    
    component fp_mul_big_alu is
        Generic(WIDTH : positive := 24);
        Port(
            clk, rst : in std_logic;
            ba_start : in STD_LOGIC;
          
            op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
            op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
          
            rdy : out STD_LOGIC;
            result : out STD_LOGIC_VECTOR(2*WIDTH-1 downto 0)
            );
    end component fp_mul_big_alu;

    signal clk_s, rst_s : std_logic;
    signal op1_in_s, op2_in_s : std_logic_vector(WIDTH-1 downto 0);
    signal start_s, ready_s : std_logic;
    signal result_s : std_logic_vector(2*WIDTH-1 downto 0);
    
begin

    design_under_verification: fp_mul_big_alu
        generic map(WIDTH => WIDTH)
        port map(
            clk => clk_s,
            rst => rst_s,
            ba_start => start_s,
            op1 => op1_in_s,
            op2 => op2_in_s,
            rdy => ready_s,
            result => result_s
        );

    clk_gen:process
    begin
        clk_s <= '0', '1' after 100ns;
        wait for 200ns;    
    end process clk_gen;

    
    stim_gen:process
    begin
        rst_s <= '1', '0' after 50ns;
        --op1_in_s <= x"0000000000000000", x"0000000000000101" after 75ns;
        --op2_in_s <= x"0000000000000000", x"0000000000000010" after 75ns;
        
        op1_in_s <= x"000000", x"f1f111" after 75ns;
        op2_in_s <= x"000000", x"f1f001" after 75ns;
        start_s <= '0', '1' after 250ns, '0' after 350ns;
        
        wait until ready_s = '1';
        wait for 300 ns;
        
        
        op1_in_s <= x"000000", x"ffffff" after 75ns;
        op2_in_s <= x"000000", x"ffffff" after 75ns;
        start_s <= '0', '1' after 250ns, '0' after 350ns;
        
        wait until ready_s = '1';
        wait for 300 ns;
        
        op1_in_s <= x"000000", x"000000" after 75ns;
        op2_in_s <= x"000000", x"f1f001" after 75ns;
        start_s <= '0', '1' after 250ns, '0' after 350ns;
        
        wait until ready_s = '1';
        wait for 300 ns;
        
        
        op1_in_s <= x"000000", x"ffffff" after 75ns;
        op2_in_s <= x"000000", x"000000" after 75ns;
        start_s <= '0', '1' after 250ns, '0' after 350ns;
        
        wait until ready_s = '1';
        wait for 300 ns;
        
        
        
        
        wait;
    end process stim_gen;
    
end Behavioral;
