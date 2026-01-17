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
  Generic  (WIDTH_FRACT : positive := 23;
            WIDTH_EXP : positive := 8
            );
  Port (clk : in STD_LOGIC;
        rst : in STD_LOGIC;
        start : in STD_LOGIC;
        
        op1_sign : in STD_LOGIC;
        op1_fract : in STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0);
        op1_exp : in STD_LOGIC_VECTOR(WIDTH_EXP-1 downto 0);
        
        op2_sign : in STD_LOGIC;
        op2_fract : in STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0);
        op2_exp : in STD_LOGIC_VECTOR(WIDTH_EXP-1 downto 0);
        
        operands_en : out STD_LOGIC; --enable signal for input registers
        
        ed_val : in STD_LOGIC_VECTOR(8 downto 0); --9 bita jer je signed vrednost
        big_alu_carry : in STD_LOGIC_VECTOR(1 downto 0);
        ed_reg_en : out STD_LOGIC; --enable signal za registar koji prihvata izlas small ALUa
        
        
        shift_r_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
        shift_r_d0 : out STD_LOGIC; --izlaz koji se povezuje na d0_fsm u shift registru
        
        
        shift_flag : out STD_LOGIC; --flag koji se vodi u BIG_ALU i sa 1 oznacava da je bilo pomeranja operanada
        
        
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
        norm_msb : in STD_LOGIC;
        
        norm_exp : in STD_LOGIC_VECTOR(7 downto 0); --dodato za OVERFLOW/UNDERFLOW detekciju
        
        round_en : out STD_LOGIC;
        round_carry : in STD_LOGIC;
        round_rdy : in STD_LOGIC;
        
        res_sign : out STD_LOGIC;
        output_reg_en : out STD_LOGIC;
        rdy : out STD_LOGIC
        
   );
end control_path_add;

architecture Behavioral of control_path_add is
    type add_state_type is (IDLE, LOAD_BUFF, INPUT_CHECK, EXP_COMPARE, SHIFT_SMALLER, FRACTION_ADD, NORM, NORM_BUFF, RESULT_OVERFLOW, ROUND, FINAL_CHECK, RESULT_ZERO, READY_STATE);
    signal state_next, state_reg : add_state_type;
    
	--constant IDLE          : add_state_type := IDLE;
	--constant LOAD_BUFF     : add_state_type := LOAD_BUFF;
	--constant INPUT_CHECK   : add_state_type := INPUT_CHECK;
	--constant EXP_COMPARE_1 : add_state_type := EXP_COMPARE_1;
	--constant EXP_COMPARE_2 : add_state_type := EXP_COMPARE_2;
	--constant SHIFT_SMALLER : add_state_type := SHIFT_SMALLER;
	--constant FRACTION_ADD  : add_state_type := FRACTION_ADD;
	--constant NORM          : add_state_type := NORM;
	--constant NORM_BUFF     : add_state_type := NORM_BUFF;
	--constant RESULT_OVERFLOW : add_state_type := RESULT_OVERFLOW;
	--constant ROUND         : add_state_type := ROUND;
	--constant FINAL_CHECK   : add_state_type := FINAL_CHECK;
	--constant RESULT_ZERO   : add_state_type := RESULT_ZERO;
	--constant READY_STATE   : add_state_type := READY_STATE;

    signal count_s, count_s_next : unsigned (7 downto 0) := (others=>'0');
    signal n_count_s, n_count_s_next : unsigned (4 downto 0) := (others =>'0');
    signal count_temp : unsigned (7 downto 0) := (others=>'0');
    signal hidden_value, hidden_value_next : unsigned(1 downto 0) := (others=>'0');
    signal shift_flag_next, shift_flag_s : std_logic := '0';
    signal op1_smaller_s, op1_smaller_next : std_logic := '1'; --signal that memorize which operand goes into SHIFT_R/BIG_ALU
    signal exp255_flag_s, exp255_flag_next : std_logic := '0'; --signal flag that notifies if at least one input exp is 255 (at least one input value inf)
    
    signal input_comb_s, input_comb_next : std_logic_vector(1 downto 0) := "11"; --signal for determining how many zeros are on input 00 01 10 11
    signal res_sign_s, res_sign_next : std_logic := '0';

begin

    --passing internal signal values to output signals
    res_sign <= res_sign_s;
    shift_flag <= shift_flag_s;
    
    
    state_proc: process(clk, rst) is
    begin
        if(rst='1') then
          state_reg <= IDLE;
          count_s <= (others=>'0');
          n_count_s <= (others=>'0');
          shift_flag_s <= '0';
          op1_smaller_s <= '0';
          res_sign_s <= '0';
          input_comb_s <= (others=>'0');
          exp255_flag_s <= '0';
	  hidden_value <= (others => '0');
        else
          if(clk'event and clk='1') then
            count_s <= count_s_next;
            n_count_s <= n_count_s_next;
            shift_flag_s <= shift_flag_next;
            op1_smaller_s <= op1_smaller_next;
            res_sign_s <= res_sign_next;
            input_comb_s <= input_comb_next;
            exp255_flag_s <= exp255_flag_next;
            state_reg <= state_next;
	    hidden_value <= hidden_value_next;
          end if;
        end if;
    end process state_proc;

    control_proc: process(state_reg, start, big_alu_carry, count_s, n_count_s) is --za milijev automat treba dodati signale u sensitivity listu? DA
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
        
        count_s_next <= count_s;
        n_count_s_next <= n_count_s; --ovaj signal je uklonjen zbog pravljenja petlje sto je detektovao jasperGold
        shift_flag_next <= shift_flag_s;
        op1_smaller_next <= op1_smaller_s;
        res_sign_next <= res_sign_s;
        input_comb_next <= input_comb_s;
        exp255_flag_next <= exp255_flag_s;
	hidden_value_next <= hidden_value;        

        case state_reg is
          
          when IDLE =>
            shift_flag_next <= '0';
            exp255_flag_next <= '0';
            if(start='1') then
              --small_alu_en <= '1'; --ovaj signal je suvisan
              operands_en <= '1';
              state_next <= LOAD_BUFF;
            else
              state_next <= IDLE;
            end if;
          
          when LOAD_BUFF =>
            state_next <= INPUT_CHECK;
          
          when INPUT_CHECK =>
            ed_reg_en <= '1';
            --detection of inf on input
            if(unsigned(op1_exp)=255 or unsigned(op2_exp)=255) then
              exp255_flag_next <= '1';
            else
              exp255_flag_next <= '0';
            end if;
            
            if((unsigned(op1_exp)=255 and unsigned(op1_fract)>0) or (unsigned(op1_exp)=255 and unsigned(op1_fract)>0)) then
              input_comb_next <= "01";
            else
            --dodato za rad sa nulom
            if(unsigned(op1_exp)=0 or unsigned(op2_exp)=0) then
              if(unsigned(op1_exp)=0 and unsigned(op2_exp)=0) then
                input_comb_next <= "00";
              else
                input_comb_next <= "10";
              end if;
            else
              --ovde da dodam kada je jedan operand +-inf a drugi realan broj
              if(unsigned(op1_exp)=255 xor unsigned(op2_exp)=255) then
                input_comb_next <= "10";
              else
                if(unsigned(op1_exp)=255 and unsigned(op2_exp)=255) then
                  if(op1_sign = op2_sign) then
                    input_comb_next <= "10"; --situacija u kojoj su brojevi na ulazu (+inf +inf) ili (-inf -inf)
                  else
                    input_comb_next <= "01"; --situacija u kojoj su oba broja na ulazu inf, op1=-inf op2=+inf   -> REZULTAT CE BITI NaN
                  end if;
                else
                  input_comb_next <= "11"; --situacija kad nijedan broj na ulazu nije +-inf a nije ni nula
                end if;
              end if;
              --input_comb_next <= "11";
            end if;
            
            end if;-- OVO JE OD PRVOG TESTA ZA NaN
            state_next <= EXP_COMPARE;          
          
          when EXP_COMPARE =>
            case input_comb_s is
              when "00" =>
                res_sign_next <= '0'; --set sign for output here to zero because skipping sign determination
                state_next <= RESULT_ZERO;
              when others =>
            
                if(unsigned(ed_val)=0) then
                  --EXP_1 = EXP_2
                  --pusti manju frakciju uvek u shift registar
                  if(unsigned(op1_fract) > unsigned(op2_fract)) then
                    op1_smaller_next <= '0';
                    mfract_1_sel <= '1'; --pusti frakciju iz op2 u shift registar
                    mfract_2_sel <= '0'; --pusti frakciju iz op1 u BIG_ALU
                    res_sign_next <= op1_sign; --dodeli rezultatu znak veceg po apsolutnoj vrednosti
                  elsif(unsigned(op1_fract) < unsigned(op2_fract)) then
                    op1_smaller_next <= '1';
                    mfract_1_sel <= '0'; --pusti frakciju iz op1 u shift registar
                    mfract_2_sel <= '1'; --pusti frakciju iz op2 u BIG_ALU
                    res_sign_next <= op2_sign; --dodeli rezultatu znak veceg po apsolutnoj vrednosti
                  else
                    --EXP1 = EXP2 and FRACT1 = FRACT2
                    --za slucaj da su i frakcije i eksponenti jednaki
                    op1_smaller_next <= '1';
                    mfract_1_sel <= '0'; --pusti frakciju iz op1 u shift registar
                    mfract_2_sel <= '1'; --pusti frakciju iz op2 u BIG_ALU
                
                    if(op1_sign = op2_sign) then
                      res_sign_next <= op2_sign; --uvek prosledjujem znak operanda koji ide u BIG_ALU
                    else
                      res_sign_next <= '0'; --if op1=op2 and op1_sign!=op2_sign result is zero, and res_sign is 0 for positive zero
                      --potrebno je setovati i eksponent na nulu jer je zapis nule u IEEE754  0  00000000  000 0000 0000 0000 0000 0000
                    end if;
                  end if;
              
                  shift_r_ctrl <= "11"; --ucita vrednost u shift registar
              
                  mux_exp_sel_top <= '0'; --selektuje eksponent op1 (moze i '1' za op2 svejedno je jer su jednaki)
                  mux_exp_sel_bot <= '0'; --selektuje eksponent iz ulaznog broja (sa '1' bi selektovao eksponent iz round bloka)
                  inc_dec_ctrl <= "11"; --ucita vrednost selektovanog eksponenta
              
              
                  shift_flag_next <= '0';
                  state_next <= FRACTION_ADD;
                else
            
                  --exponent difference not zero
                  shift_flag_next <= '1';
                  shift_r_ctrl <= "11"; --"11" load value into shift reg
            
                  if(ed_val(8)='0') then --exponent difference value is positive 
                    -- op1 bigger than op2
                    op1_smaller_next <= '0';
                    mfract_1_sel <= '1'; --pusti frakciju iz op2 u shift_right registar jer je exp2 manji
                    mfract_2_sel <= '0'; --pusti frakciju iz op1 u BIG_ALU
                    res_sign_next <= op1_sign; --rezultat dobija znak veceg operanda
                
                    count_s_next <= unsigned(ed_val(7 downto 0)); --sacuva se kao broj ciklusa koje ce biti pomerana vrednost u registru
                
                    count_temp <= unsigned(ed_val(7 downto 0));
                    --count_temp <= count_s; --da li je ovo neophodno??
                    --dodela je konkurentna on ce uzeti vrednost count_s = (others=>'0')
                
                    if(input_comb_s="10" or input_comb_s="01") then --"10" for inf "01" for NaN
                      mux_exp_sel_top <= '0'; --op2 has ZERO EXP and pass EXP of op1 into incr/decr circuit
                    else
                      mux_exp_sel_top <= '1'; --pass the exp of op2 for increment/decrement
                    end if;
                    mux_exp_sel_bot <= '0';
                    inc_dec_ctrl <= "11";
                                
                    state_next <= SHIFT_SMALLER;
                  else
                    -- op2 bigger than op1
                    op1_smaller_next <= '1';
                    mfract_1_sel <= '0'; --pusti frakciju iz op1 u shift_right registar jer je exp1 manji
                    mfract_2_sel <= '1'; --pusti frakciju iz op2 u BIG ALU
                    res_sign_next <= op2_sign; --rezultat dobija znak veceg operanda
                
                    if(input_comb_s = "10" or input_comb_s="01") then
                      mux_exp_sel_top <= '1'; --op1 has ZERO EXP and pass EXP of op2 into incr/decr circuit
                    else
                      mux_exp_sel_top <= '0'; --pass the exp of op1 for increment/decrement
                    end if;
                
                    mux_exp_sel_bot <= '0'; --pass exp from top
                    inc_dec_ctrl <= "11"; --load value into inc_dec module
                
                    count_v := (not(unsigned(ed_val)))+1; --da negativnu vrednost prevede iz komplementa dvoje, DOBIJE APSOLUTNU VREDNOST RAZLIKE
                    count_s_next <= count_v(7 downto 0); --dodeli 8 bita odnosno apsolutnu vrednost razlike bez bita znaka
                
                    count_temp <= count_v(7 downto 0); --DA LI JE OVO NEOPHODNO ?
                
                    state_next <= SHIFT_SMALLER;
                  end if;
                end if;
              end case;
                
          when SHIFT_SMALLER =>
            --u ovom stanju treba da se vrti i da dekrementira brojac count_s do nule svaki takt da pomeri jednom frakciju i da dekrementira brojac
            
            --shift_r_ctrl <= "10"; --shift right
            --if(input_comb_s =)
            
            
            if(input_comb_s = "10" or input_comb_s="01") then
              inc_dec_ctrl <= "00"; --if smaller operand is zero exponent then do not increment exponent because larger operand is filled in
              shift_r_ctrl <= "00"; --no need to shift smaller operand if smaller operand is zero
            else  
              inc_dec_ctrl <= "01"; ----------- EXPONENT INCREMENT for shifting fraction right
              shift_r_ctrl <= "10"; --if smaller operand is not zero input 01 11 00 shift smaller operand right
            end if;
            
            --op1_smaller_s prevents returning mfract_selection values to default
            if(op1_smaller_s = '1') then
              mfract_1_sel <= '0';
              mfract_2_sel <= '1';
            else
              mfract_1_sel <= '1';
              mfract_2_sel <= '0';
            end if;
            
            --prvi shift unosi skrivenu jedinicu / nulu ako je jedan operand nula
            if(count_s = count_temp) then
              if(input_comb_s = "11") then
                shift_r_d0 <= '1'; --if one operand (smaller operand) is zero then shift 0 into the number
              else
                shift_r_d0 <= '0';
              end if;
            else
              shift_r_d0 <= '0';
            end if;
            
            if(count_s = 0) then
              shift_r_ctrl <= "00";
              inc_dec_ctrl <= "00";
              state_next <= FRACTION_ADD;
            else
              if(input_comb_s = "10" or input_comb_s="01") then
                count_s_next <= b"00000000";
              else
                count_s_next <= count_s - 1;
              end if;
              state_next <= SHIFT_SMALLER;
            end if;
            
          when FRACTION_ADD =>
            --u sabiranju treba ucitati vrednosti u big alu i dodati jos 2 bita da bi bilo moguce zaokruzivanje GUARD i ROUND bit
            if((input_comb_s = "10" and exp255_flag_s='1') or input_comb_s="01") then
              big_alu_en <= '0';
            else
              big_alu_en <= '1';
            end if;
            
            --op1_smaller_s prevents returning mfract_selection values to default
            if(op1_smaller_s = '1') then
              mfract_1_sel <= '0';
              mfract_2_sel <= '1';
            else
              mfract_1_sel <= '1';
              mfract_2_sel <= '0';
            end if;
            
            if(op1_sign = op2_sign) then
              big_alu_sel <= '0';
            else
              big_alu_sel <= '1';
            end if;
            
            mres_sel <= '0';
            norm_reg_ctrl <= "11"; --load big_alu result into normalization register
            hidden_value_next <= unsigned(big_alu_carry); --kada se promeni opet ce ga TRIGEROVATI OVDE SAM STAO OVAJ KOMENTAR OBRISI
            
            state_next <= NORM;
            
          when NORM =>
            if((input_comb_s = "10" and exp255_flag_s='1') or input_comb_s="01") then
              big_alu_en <= '0';
            else
              big_alu_en <= '1';--ovo je neophodno jer tek u ovom stanju normalizacioni registar moze ucitati vrednost
            end if;
            
            --op1_smaller_s prevents returning mfract_selection values to default
            if(op1_smaller_s = '1') then
              mfract_1_sel <= '0';
              mfract_2_sel <= '1';
            else
              mfract_1_sel <= '1';
              mfract_2_sel <= '0';
            end if;
            
            -- 3 cases of normalization register
            case norm_exp is
              
              --when "11111111" =>
              --  inc_dec_ctrl <= "00"; --hold value on 1111 1111
              --  big_alu_en <= '0';
              --  state_next <= RESULT_OVERFLOW;
              
              when "00000000" =>
                --inc_dec_ctrl <= "00"; --nebitno
                state_next <= RESULT_ZERO;
              
              when others =>
                --ovde treba da se desava sve ostalo sto se inace desava ispitivanje HIDDEN_VALUE vrednosti itd
                --pri normalizaciji je potrebno inkrementirati ili dekrementirati eksponent !          
                case hidden_value is
                  when "10" =>
                  --addition
                    norm_reg_d0 <= '0';
                    hidden_value_next <= "01";
                    norm_reg_ctrl <= "10"; --shift right
                    inc_dec_ctrl <= "01"; --icrementing exp
                    if(norm_exp = "11111110") then
                      state_next <= RESULT_OVERFLOW;
                      --big_alu_en <= '0';
                    else
                      state_next <= NORM_BUFF;
                    end if;
                  when "11" =>
                  --addition
                    norm_reg_d0 <= '1';
                    hidden_value_next <= "01";
                    norm_reg_ctrl <= "10"; --shift right
                    inc_dec_ctrl <= "01"; --icrementing exp
                    --state_next <= NORM_BUFF;
                    if(norm_exp = "11111110") then
                      state_next <= RESULT_OVERFLOW;
                      --big_alu_en <= '0';
                    else
                      state_next <= NORM_BUFF;
                    end if;
                  when "00" =>
                  --subtraction
                    if(input_comb_s = "10") then --ovde moze da stoji ...or input_comb_s="00"... ?
                      norm_reg_ctrl <= "00";
                      inc_dec_ctrl <= "00";
                      state_next <= NORM_BUFF;
                    elsif(input_comb_s = "01") then
                      norm_reg_d0 <= '1';
                      norm_reg_ctrl <= "10";
                      inc_dec_ctrl <= "00";
                      state_next <= NORM_BUFF;
                    else
                      norm_reg_d0 <= '0';
                      norm_reg_ctrl <= "01"; --shift left
                      inc_dec_ctrl <= "10"; --decrementing exponent
                
                      --NAKON 25 shiftovanja ukoliko ne pronadje jedinicu mora da ucita vrednost iz ROUND bloka u INCR_DECR blok kako bi se postavila vrednost EXP na nulu
                      if(n_count_s < 25) then
                        state_next <= NORM;
                        hidden_value_next <= '0' & norm_msb;
                        n_count_s_next <= n_count_s + 1; --problem je ako je dodela n_count_s_next <= n_count_s_next + 1; kreira se petlja Detektovao Jasper. Zasto se u tom slucaju kreira petlja???
                      else
                        state_next <= NORM_BUFF;
                        norm_reg_d0 <= '0';
                        norm_reg_ctrl <= "00";
                        inc_dec_ctrl <= "00";  
                      end if;
                    end if;
                  when others =>
                  --hidden value is 01 -> no need for shifting
                    norm_reg_d0 <= '0';
                    norm_reg_ctrl <= "00";
                    state_next <= NORM_BUFF;
                end case;
            
            end case;
            
            
          when NORM_BUFF =>
            if(n_count_s = 25) then
              --round_en <= '0';
              --res_sign_next <= '0'; not needed already set before
              state_next <= RESULT_ZERO;
            else
              state_next <= ROUND;
              --round_en <= '1';
            end if;
            
          when RESULT_OVERFLOW =>
            big_alu_en <= '0';  
            inc_dec_ctrl <= "00";
            norm_reg_ctrl <= "11";
            state_next <= NORM;
            
          when ROUND =>
            round_en <= '1';
            state_next <= FINAL_CHECK;
            
          when FINAL_CHECK =>
          --ROUND_RDY SIGNAL JE VEROVATNO NEPOTREBAN !!!! OBRATI PAZNJU
            round_en <= '1';
            if(round_rdy = '1') then
              if(round_carry='1') then
                hidden_value_next <= hidden_value + 1;
                norm_reg_ctrl <= "11"; --bilo je 00
                mres_sel <= '1';
                state_next <= NORM;
              else
                output_reg_en <= '1';
                state_next <= READY_STATE;
              end if;
            else
               state_next <= FINAL_CHECK;
            end if;
          
          when RESULT_ZERO =>
            --round block is disabled so its output is all zeros
            --round_en <= '0';
            --output_reg_en <= '1';
            --res_sign_next <= '0';
            state_next <= READY_STATE;  
          
          when READY_STATE =>
            rdy <= '1';
            state_next <= IDLE;
            
          when others =>
            state_next <= IDLE;
        end case;
    
    end process control_proc;


end Behavioral;
