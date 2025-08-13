----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/31/2025 08:41:19 PM
-- Design Name: 
-- Module Name: control_path_add - Behavioral
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

entity control_path_add is
  Port (clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        start : in STD_LOGIC;
        
        operands_en : out STD_LOGIC; --enable signal for input registers
        
        ed_val : in STD_LOGIC_VECTOR(8 downto 0); --9 bita jer je signed vrednost
        big_alu_carry : in STD_LOGIC;
        ed_reg_en : out STD_LOGIC; --enable signal za registar koji prihvata izlas small ALUa
        
        
        
        shift_r_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
        shift_r_d0 : out STD_LOGIC; --izlaz koji se povezuje na d0_fsm u shift registru
        
        mfract_1_sel : out STD_LOGIC;
        mfract_2_sel : out STD_LOGIC;
        
        
        mux_exp_sel_top : out STD_LOGIC;
        mux_exp_sel_bot : out STD_LOGIC;
        inc_dec_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
        
        big_alu_en : out STD_LOGIC;
        big_alu_sel : out STD_LOGIC;
        mres_sel : out STD_LOGIC;
        
        --norm_reg_en : out STD_LOGIC;
        norm_reg_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
        norm_reg_d0 : out STD_LOGIC;
        
        round_en : out STD_LOGIC;
        --round_res : in STD_LOGIC_VECTOR(25 downto 0); --izgleda da se ovaj signal ne koristi NI ZA STA????!?!?!?!??! moguce d aje potreban samo carry u FSM !!!!
        round_carry : in STD_LOGIC;
        round_rdy : in STD_LOGIC;
        
        output_reg_en : out STD_LOGIC;
        rdy : out STD_LOGIC
        
   );
end control_path_add;

architecture Behavioral of control_path_add is
    type add_state_type is (IDLE, LOAD, EXP_COMPARE_1, EXP_COMPARE_2, SHIFT_SMALLER, FRACTION_ADD, NORM, ROUND, FINAL_CHECK, READY_STATE);
    signal state_next, state_reg : add_state_type;
    
    signal count_s : unsigned (7 downto 0) := (others=>'0');
    signal count_temp : unsigned (7 downto 0) := (others=>'0');
    signal hidden_value : unsigned(1 downto 0) := (others=>'0'); --za sta mi je trebao ovaj signal?

begin

    state_proc: process(clk, rst) is
    begin
        if(rst='1') then
          state_reg <= IDLE;
        else
          if(clk'event and clk='1') then
            state_reg <= state_next;
          end if;
        end if;
    end process state_proc;

    control_proc: process(state_reg, start) is --za milijev automat treba dodati signale u sensitivity listu? DA
      variable count_v : unsigned (8 downto 0) := (others=>'0');
    begin
        rdy <= '0'; --podrazumevana vrednost
        big_alu_en <= '0';
        big_alu_sel <= '0';
        ed_reg_en <= '0';
        inc_dec_ctrl <= "00";
        mfract_1_sel <= '0';
        mfract_2_sel <= '1';
        mres_sel <= '0';
        mux_exp_sel_bot <= '0';
        mux_exp_sel_top <= '0';
        norm_reg_ctrl <= "00";
        norm_reg_d0 <= '0';
        operands_en <= '0';
        output_reg_en <= '0';
        round_en <= '0';
        shift_r_ctrl <= "00";
        shift_r_d0 <= '0';
        
        case state_reg is
          
          when IDLE =>
            if(start='1') then
              --small_alu_en <= '1'; --ovaj signal je suvisan
              --ed_reg_en <= '1';
              operands_en <= '1';
              state_next <= LOAD;
            else
              state_next <= IDLE;
            end if;
          
          when LOAD =>
            --operands_en <= '1';
            ed_reg_en <= '1';
            state_next <= EXP_COMPARE_1;
          
          when EXP_COMPARE_1 =>
            --small_alu_en <= '0'; --ovaj signal je suvisan
            ed_reg_en <= '0'; --keep loaded value
            state_next <= EXP_COMPARE_2;
          
          when EXP_COMPARE_2 =>
            if(unsigned(ed_val)=0) then
              mfract_1_sel <= '0'; --pusti frakciju iz op1
              mfract_2_sel <= '1'; --pusti frakciju iz op2
              
              --shift_r_en <= '1'; --enabluje shift registar
              shift_r_ctrl <= "11"; --ucita vrednost u shift registar
              big_alu_en <= '1'; --enable big alu
              big_alu_sel <= '0'; --selektuje operaciju sabiranja op1 i op2
              
              mux_exp_sel_top <= '0'; --selektuje eksponent op1 (moze i '1' za op2 svejedno je jer su jednaki)
              mux_exp_sel_bot <= '0'; --selektuje eksponent iz ulaznog broja (sa '1' bi selektovao eksponent iz round bloka)
              inc_dec_ctrl <= "11"; --ucita vrednost selektovanog eksponenta
              
              hidden_value <= "10";  --VREDNOST LEVO OD BINARNE TACKE AKO SU OPERANDI ISTOG EKSPONENTA
              
              big_alu_en <= '1'; --enable big alu
              big_alu_sel <= '0'; --selektuje operaciju sabiranja op1 i op2
              state_next <= FRACTION_ADD;
            else
              --OVDE ENABLUJE SHIFT_RIGHT REGISTAR I UCITA U NJEGA VREDNOST
              --shift_r_en <= '1';
              shift_r_ctrl <= "11";
            
              hidden_value <= "01"; --VREDNOST LEVO OD BINARNE TACKE AKO SU OPERANDI NISU ISTOG EKSPONENTA
              
              if(ed_val(8)='0') then --exponent difference value is positive 
                -- op1 bigger than op2
                mfract_1_sel <= '1'; --pusti frakciju iz op2 u shift_right registar jer je exp2 manji
                mfract_2_sel <= '0'; --pusti frakciju iz op1 u BIG_ALU
                
                count_s <= unsigned(ed_val(7 downto 0)); --sacuva se kao broj ciklusa koje ce biti pomerana vrednost u registru
                
                count_temp <= count_s; --da li je ovo neophodno??
                
                mux_exp_sel_top <= '1'; --pass the exp of op2 for increment/decrement
                mux_exp_sel_bot <= '0';
                inc_dec_ctrl <= "11";
                
                state_next <= SHIFT_SMALLER;
              else
                -- op2 bigger than op1
                mfract_1_sel <= '0'; --pusti frakciju iz op1 u shift_right registar jer je exp1 manji
                mfract_2_sel <= '1'; --pusti frakciju iz op2 u BIG ALU
                
                mux_exp_sel_top <= '0'; --pass exp of op1 for increment/decrement
                mux_exp_sel_bot <= '0'; --pass exp from top
                inc_dec_ctrl <= "11"; --load value into inc_dec module
                
                count_v := (not(unsigned(ed_val)))+1; --da negativnu vrednost prevede iz komplementa dvoje, DOBIJE APSOLUTNU VREDNOST RAZLIKE
                count_s <= count_v(7 downto 0); --dodeli 8 bita odnosno apsolutnu vrednost razlike bez bita znaka
                
                count_temp <= count_v(7 downto 0); --DA LI JE OVO NEOPHODNO ?
                
                state_next <= SHIFT_SMALLER;
              end if;
            end if;
            
          when SHIFT_SMALLER =>
            --u ovom stanju treba da se vrti i da dekrementira brojac count_s do nule svaki takt da pomeri jednom frakciju i da dekrementira brojac
            --shift_r_en <= '1';
            shift_r_ctrl <= "10"; --shift right
            inc_dec_ctrl <= "01"; ----------- EXPONENT INCREMENT for shifting fraction right
            
            --prvi shift unosi skrivenu jedinicu
            if(count_s=count_temp) then
              shift_r_d0 <='1';
            else
              shift_r_d0 <= '0';
            end if;
            if(count_s=0) then
              --shift_r_en <= '0';
              shift_r_ctrl <= "11";
              inc_dec_ctrl <= "00";
              
              big_alu_en <= '1'; --enable big alu
              big_alu_sel <= '0'; --selektuje operaciju sabiranja op1 i op2
              state_next <= FRACTION_ADD;
            else
              count_s <= count_s - 1;
              state_next <= SHIFT_SMALLER;
            end if;
            
          when FRACTION_ADD =>
            --u sabiranju treba ucitati vrednosti u big alu i dodati jos 2 bita da bi bilo moguce zaokruzivanje GUARD i ROUND bit
            big_alu_en <= '1';
            mres_sel <= '0';
            --norm_reg_en <= '1';
            norm_reg_ctrl <= "11"; --load big_alu result into normalization register
            if(big_alu_carry='0') then
              hidden_value <= hidden_value + 0; 
            else
              hidden_value <= hidden_value + 1;
            end if;
            state_next <= NORM;
            
          when NORM =>
          --pri normalizaciji je potrebno uvecati eksponent !
            case hidden_value is
              when "10" =>
                norm_reg_d0 <= '0';
                hidden_value <= "01";
              when "11" =>
                norm_reg_d0 <= '1';
                hidden_value <= "01";
              when others =>
                norm_reg_ctrl <= "00";
            end case;
            --norm_reg_en <= '1';
            norm_reg_ctrl <= "10";
            inc_dec_ctrl <= "01"; --icrementing exp
            --round_en <= '1';
            state_next <= ROUND;
            
          when ROUND =>
            round_en <= '1';
            state_next <= FINAL_CHECK;
            
          when FINAL_CHECK =>
          --ROUND_RDY SIGNAL JE VEROVATNO NEPOTREBAN !!!! OBRATI PAZNJU
            if(round_rdy = '1') then
              if(round_carry='1') then
                hidden_value <= hidden_value + 1;
                --norm_reg_en <= '1';
                norm_reg_ctrl <= "00";
                mres_sel <= '1';
                state_next <= NORM;
              else
                output_reg_en <= '1';
                state_next <= READY_STATE;
              end if;
             else
               state_next <= FINAL_CHECK;
            end if;
            
          when READY_STATE =>
            rdy <= '1';
            state_next <= IDLE;
            
        end case;
    
    end process control_proc;


end Behavioral;
