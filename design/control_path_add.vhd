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
        shift_r_en : out STD_LOGIC;
        shift_r_d0 : out STD_LOGIC; --izlaz koji se povezuje na d0_fsm u shift registru
        
        sticky_in_cp : in STD_LOGIC;
        sticky_out_cp : out STD_LOGIC;
        
        shift_flag : out STD_LOGIC; --flag koji se vodi u BIG_ALU i sa 1 oznacava da je bilo pomeranja operanada
        
        mfract_1_sel : out STD_LOGIC;
        mfract_2_sel : out STD_LOGIC;
        
        
        mux_exp_sel_top : out STD_LOGIC;
        mux_exp_sel_bot : out STD_LOGIC;
        inc_dec_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
        
        big_alu_en : out STD_LOGIC;
        big_alu_sel : out STD_LOGIC;
        mres_sel : out STD_LOGIC;
        
        norm_reg_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
        norm_reg_en : out STD_LOGIC;
        norm_reg_d0 : out STD_LOGIC;
        norm_msb : in STD_LOGIC;
        
        norm_exp : in STD_LOGIC_VECTOR(7 downto 0); --dodato za OVERFLOW/UNDERFLOW detekciju
        
        round_en : out STD_LOGIC;
        round_carry : in STD_LOGIC;
        round_rdy : in STD_LOGIC;
        
        --Exception flags, all single bit outputs NX=LSB, NV=MSB 
        fflags : out STD_LOGIC_VECTOR(4 downto 0);
        nx_flag_in : in STD_LOGIC;
        
        res_sign : out STD_LOGIC;
        output_reg_en : out STD_LOGIC;
        rdy : out STD_LOGIC
        
   );
end control_path_add;

architecture Behavioral of control_path_add is
    type add_state_type is (IDLE, LOAD_BUFF, INPUT_CHECK, EXP_COMPARE, SHIFT_SMALLER, FRACTION_ADD, NORM, NORM_BUFF, RESULT_OVERFLOW, ROUND, RESULT_ZERO, READY_STATE);
    signal state_next, state_reg : add_state_type;
    

    signal count_s, count_s_next : unsigned (7 downto 0) := (others=>'0');
    signal n_count_s, n_count_s_next : unsigned (4 downto 0) := (others =>'0');
    signal count_temp_s, count_temp_next : unsigned (7 downto 0) := (others=>'0');
    signal hidden_value, hidden_value_next : unsigned(1 downto 0) := (others=>'0');
    signal shift_flag_next, shift_flag_s : std_logic := '0';
    signal op1_smaller_s, op1_smaller_next : std_logic := '1'; --signal that memorize which operand goes into SHIFT_R/BIG_ALU
    signal exp255_flag_s, exp255_flag_next : std_logic := '0'; --signal flag that notifies if at least one input exp is 255 (at least one input value inf)
    
    --generisanje ispravnog sticky bita
    signal sticky_out_s, sticky_out_next : std_logic := '0';
    
    signal input_comb_s, input_comb_next : std_logic_vector(1 downto 0) := "11"; --signal for determining how many zeros are on input 00 01 10 11
    signal res_sign_s, res_sign_next : std_logic := '0';
    
    signal nv_flag_s, nv_flag_next : STD_LOGIC; --fflags(4)
    signal dz_flag_s, dz_flag_next : STD_LOGIC; --fflags(3)
    signal of_flag_s, of_flag_next : STD_LOGIC; --fflags(2)
    signal uf_flag_s, uf_flag_next : STD_LOGIC; --fflags(1)
    signal nx_flag_s, nx_flag_next : STD_LOGIC; --fflags(0)

begin

    --passing internal signal values to output signals
    res_sign <= res_sign_s;
    shift_flag <= shift_flag_s;
    sticky_out_cp <= sticky_out_s;
    
    fflags <= nv_flag_s & dz_flag_s & of_flag_s & uf_flag_s & nx_flag_s;
    
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
          count_temp_s <= (others =>'0');
	      hidden_value <= (others => '0');
	      sticky_out_s <= '0';
	      --exception flags
	      nv_flag_s <= '0';
	      uf_flag_s <= '0';
	      of_flag_s <= '0';
	      dz_flag_s <= '0';
	      nx_flag_s <= '0';
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
            count_temp_s <= count_temp_next;
	        hidden_value <= hidden_value_next;
	        sticky_out_s <= sticky_out_next;
            --exception flags
            nv_flag_s <= nv_flag_next;
	        uf_flag_s <= uf_flag_next;
	        of_flag_s <= of_flag_next;
	        dz_flag_s <= dz_flag_next;
	        nx_flag_s <= nx_flag_next;
          end if;
        end if;
    end process state_proc;

    control_proc: process(state_reg, start, big_alu_carry, count_s, n_count_s, round_rdy, round_carry, nx_flag_in) is --za milijev automat treba dodati signale u sensitivity listu? DA
      variable count_v : unsigned (8 downto 0) := (others=>'0');
    begin
        rdy <= '0'; --podrazumevana vrednost
        big_alu_en <= '0';
        big_alu_sel <= '0';
        ed_reg_en <= '0';
        inc_dec_ctrl <= "00";
        
        
        --Passing value to selection inputs of mux based on op1_smaller_s
        --op1_smaller_s prevents changing mfract_selection values
        mfract_1_sel <= not op1_smaller_next;
        mfract_2_sel <= op1_smaller_next;
        
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
        shift_r_en <= '1';
        norm_reg_en <= '1';
        
        count_s_next <= count_s;
        n_count_s_next <= n_count_s; --ovaj signal je uklonjen zbog pravljenja petlje sto je detektovao jasperGold
        shift_flag_next <= shift_flag_s;
        op1_smaller_next <= op1_smaller_s;
        res_sign_next <= res_sign_s;
        input_comb_next <= input_comb_s;
        exp255_flag_next <= exp255_flag_s;
	    hidden_value_next <= hidden_value;        
        count_temp_next <= count_temp_s;
        sticky_out_next <= sticky_out_s;
        
        --fflags
        nv_flag_next <= nv_flag_s;
	    uf_flag_next <= uf_flag_s;
	    of_flag_next <= of_flag_s;
	    dz_flag_next <= dz_flag_s;
	    nx_flag_next <= nx_flag_s;

        case state_reg is
          
          --************************************** IDLE **********************************************
          when IDLE =>
            input_comb_next <= "11";
            shift_flag_next <= '0';
            exp255_flag_next <= '0';
            sticky_out_next <= '0';
            op1_smaller_next <= '0';
            count_temp_next <= (others=>'0');
            n_count_s_next <= (others=>'0');
            nv_flag_next <= '0';
	        uf_flag_next <= '0';
	        of_flag_next <= '0';
	        dz_flag_next <= '0';
	        nx_flag_next <= '0';
            if(start='1') then
              operands_en <= '1';
              state_next <= LOAD_BUFF;
            else
              state_next <= IDLE;
            end if;
          
          --************************************** LOAD_BUFF *****************************************
          when LOAD_BUFF =>
            ed_reg_en <= '1';
            state_next <= INPUT_CHECK;
          
          --************************************** INPUT_CHECK ***************************************
          when INPUT_CHECK =>
            ed_reg_en <= '1';
            --detection of inf on input
            if(unsigned(op1_exp)=255 or unsigned(op2_exp)=255) then
              exp255_flag_next <= '1';
            else
              exp255_flag_next <= '0';
            end if;
            
            if((unsigned(op1_exp)=255 and unsigned(op1_fract)>0) or (unsigned(op2_exp)=255 and unsigned(op2_fract)>0)) then
                --ovde bi trebalo da dodam detekciju sNaN-a i postavljanje invalid operation zastavice
                if((unsigned(op1_exp)=255 and op1_fract(WIDTH_FRACT-1)='0' and unsigned(op1_fract)>0) or (unsigned(op2_exp)=255 and op2_fract(WIDTH_FRACT-1)='0' and unsigned(op2_fract)>0)) then
                  nv_flag_next <= '1'; --INVALID OPERATION flag set to high
                end if;
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
                      nv_flag_next <= '1'; --INVALID OPERATION flag set to high
                      input_comb_next <= "01"; --situacija u kojoj su oba broja na ulazu inf, op1=-inf op2=+inf   -> REZULTAT CE BITI NaN
                    end if;
                  else
                    input_comb_next <= "11"; --situacija kad nijedan broj na ulazu nije +-inf a nije ni nula
                  end if;
                end if;
              end if;
            
            end if; --closing first if statement that test input for NaN
            state_next <= EXP_COMPARE;          
          
          --************************************** EXP_COMPARE *****************************************
          when EXP_COMPARE =>
            case input_comb_s is
              
              when "00" =>
                if(op1_sign = op2_sign) then
                  res_sign_next <= op1_sign; --same signed zeros produce same signed zero (-0 + -0 = -0)
                else
                  res_sign_next <= '0'; --different signed zeros produce positive zero
                end if;
                state_next <= RESULT_ZERO;
              
              when others =>
                if(unsigned(ed_val)=0) then
                  --EXP_1 = EXP_2
                  --pusti manju frakciju uvek u shift registar
                  if(unsigned(op1_fract) > unsigned(op2_fract)) then
                    op1_smaller_next <= '0';                            --pusti frakciju iz op2 u shift registar --pusti frakciju iz op1 u BIG_ALU
                    res_sign_next <= op1_sign;                          --dodeli rezultatu znak veceg po apsolutnoj vrednosti
                  elsif(unsigned(op1_fract) < unsigned(op2_fract)) then
                    op1_smaller_next <= '1';                            --pusti frakciju iz op1 u shift registar --pusti frakciju iz op2 u BIG_ALU
                    res_sign_next <= op2_sign;                          --dodeli rezultatu znak veceg po apsolutnoj vrednosti
                  else
                    --EXP1 = EXP2 and FRACT1 = FRACT2
                    op1_smaller_next <= '1'; --pusti frakciju iz op1 u shift registar --pusti frakciju iz op2 u BIG_ALU
                
                    if(op1_sign = op2_sign) then
                      res_sign_next <= op2_sign; --uvek prosledjujem znak operanda koji ide u BIG_ALU
                    else
                      res_sign_next <= '0'; --if op1=op2 and op1_sign!=op2_sign result is zero, and res_sign is 0 for positive zero
                      --potrebno je postaviti i eksponent na nulu jer je zapis nule u IEEE754  0  00000000  000 0000 0000 0000 0000 0000
                    end if;
                  end if;
              
                  shift_r_ctrl <= "11"; --ucita vrednost u shift registar
              
                  mux_exp_sel_top <= '0'; --selektuje eksponent op1 (moze i '1' za op2 svejedno je jer su jednaki)
                  mux_exp_sel_bot <= '0'; --selektuje eksponent iz ulaznog broja (sa '1' bi selektovao eksponent iz round bloka)
                  inc_dec_ctrl <= "11"; --ucita vrednost selektovanog eksponenta
              
              
                  shift_flag_next <= '0';
                  state_next <= FRACTION_ADD;
                else
                  
                  --in case of one subnormal input shift_r_en signal will prevent subnormal fraction from propagating
                  if(input_comb_s="10") then
                    shift_r_en <= '0';
                  end if;
                  
                  --exponent difference not zero
                  shift_flag_next <= '1'; --there will be shifting of operand
                  shift_r_ctrl <= "11"; --"11" load value into shift reg
            
                  if(ed_val(8)='0') then --exponent difference value is positive 
                    -- op1 bigger than op2
                    op1_smaller_next <= '0';                --pusti frakciju iz op2 u shift_right registar jer je exp2 manji --pusti frakciju iz op1 u BIG_ALU
                    res_sign_next <= op1_sign; --rezultat dobija znak veceg operanda
                
                    count_s_next <= unsigned(ed_val(7 downto 0)); --sacuva se kao broj ciklusa koje ce biti pomerana vrednost u registru
                
                    count_temp_next <= unsigned(ed_val(7 downto 0));
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
                    op1_smaller_next <= '1';  --pusti frakciju iz op1 u shift_right registar jer je exp1 manji  --pusti frakciju iz op2 u BIG ALU
                    res_sign_next <= op2_sign; --rezultat dobija znak veceg operanda
                
                    if(input_comb_s = "10" or input_comb_s="01") then
                      mux_exp_sel_top <= '1'; --op1 has ZERO EXP and pass EXP of op2 into incr/decr circuit
                    else
                      mux_exp_sel_top <= '0'; --pass the exp of op1 for increment/decrement
                    end if;
                
                    mux_exp_sel_bot <= '0'; --pass exp from top
                    inc_dec_ctrl <= "11"; --load value into inc_dec module
                
                    count_v := (not(unsigned(ed_val)))+1; --da negativnu vrednost prevede iz komplementa dvojke, DOBIJE APSOLUTNU VREDNOST RAZLIKE
                    count_s_next <= count_v(7 downto 0); --dodeli 8 bita odnosno apsolutnu vrednost razlike bez bita znaka
                    count_temp_next <= count_v(7 downto 0);
                
                    state_next <= SHIFT_SMALLER;
                  end if;
                end if;
                --this line prevents generating negative qNaN, so qNaN value is always 7FC0 0000 -> Canonical qNaN
                if(input_comb_s="01") then
                  res_sign_next <= '0';
                end if;
              end case;
                
          --************************************** SHIFT_SMALLER *****************************************      
          when SHIFT_SMALLER =>
            sticky_out_next <= sticky_out_s or sticky_in_cp; -- dali bi sticky_in trebao u listu osetljivosti? moguce da ce raditi i bez..
            
            --u ovom stanju treba da se vrti i da dekrementira brojac count_s do nule svaki takt da pomeri jednom frakciju i da dekrementira brojac  
            if(input_comb_s = "10" or input_comb_s="01") then
              inc_dec_ctrl <= "00"; --if smaller operand is zero exponent then do not increment exponent because larger operand exp is filled in
              shift_r_ctrl <= "00"; --no need to shift smaller operand if smaller operand is zero
            else  
              inc_dec_ctrl <= "01"; ----------- EXPONENT INCREMENT for shifting fraction right
              shift_r_ctrl <= "10"; --if smaller operand is not zero input 01 11 00 shift smaller operand right
            end if;
          
            --prvi shift unosi skrivenu jedinicu / nulu ako je jedan operand nula
            if(count_s = count_temp_s) then
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
              if(input_comb_s="10" or input_comb_s="01") then
                count_s_next <= b"00000000";
              else
                count_s_next <= count_s - 1;
              end if;
              if(input_comb_s="11" and count_s>26) then
                --optimization for case when smaller operand does not effect the result (exp difference bigger or equal 27)
                input_comb_next <= "10";
                state_next <= EXP_COMPARE;
              else
                state_next <= SHIFT_SMALLER;
              end if;
            end if;
          
          --************************************** FRACTION_ADD *****************************************  
          when FRACTION_ADD =>
            if((input_comb_s = "10" and exp255_flag_s='1') or input_comb_s="01") then
              big_alu_en <= '0'; --izlaz BIG_ALU je na nuli
            else
              big_alu_en <= '1';
            end if;
            --op1_smaller_s prevents returning mfract_selection values to default
            
            if(op1_sign = op2_sign) then
              big_alu_sel <= '0';
            else
              big_alu_sel <= '1';
            end if;
            
            mres_sel <= '0';
            norm_reg_ctrl <= "11"; --load big_alu result into normalization register
            hidden_value_next <= unsigned(big_alu_carry); --kada se promeni opet ce ga TRIGEROVATI OVDE SAM STAO OVAJ KOMENTAR OBRISI
            
            state_next <= NORM;
            
          --************************************** NORM *****************************************
          when NORM =>
            if((input_comb_s = "10" and exp255_flag_s='1') or input_comb_s="01") then
              big_alu_en <= '0';
            else
              big_alu_en <= '1';--ovo je neophodno jer tek u ovom stanju normalizacioni registar moze ucitati vrednost
            end if;
            
            case norm_exp is
              -- 2 cases of normalization register
              when "00000000" =>
                --RESULT UNDERFLOW, SIGN IS KEPT UNCHANGED
                --IEEE754 standard requires signaling NX_FLAG when UNDERFLOW or OVERFLOW flag is raised
                uf_flag_next <= '1'; --UNDERFLOW flag set to high
                nx_flag_next <= '1'; --INEXACT flag set to high
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
                    if(norm_exp = "11111110") then
                      state_next <= RESULT_OVERFLOW;
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
            
          --************************************** NORM_BUFF *****************************************
          when NORM_BUFF =>
            if(n_count_s = 25) then
              --round_en <= '0';
              --res_sign_next <= '0'; not needed already set before
              --res_sign_next <= '0';
              state_next <= RESULT_ZERO;
            else
              state_next <= ROUND;
              --round_en <= '1';
            end if;
            
          --************************************** RESULT_OVERFLOW *****************************************
          when RESULT_OVERFLOW =>
            --IEEE754 standard requires signaling NX_FLAG when UNDERFLOW or OVERFLOW flag is raised
            of_flag_next <= '1';
            nx_flag_next <= '1';

            big_alu_en <= '0';  
            inc_dec_ctrl <= "00";
            norm_reg_ctrl <= "11";
            state_next <= NORM;
              
          --************************************** ROUND *****************************************    
          when ROUND =>
            round_en <= '1';
            nx_flag_next <= nx_flag_s or nx_flag_in;
            if(round_rdy = '1') then
              if(round_carry='1') then
                hidden_value_next <= hidden_value + 1;
                norm_reg_ctrl <= "11"; --bilo je 00 sto je dovodilo do greske jer se nije ucitavala vrednost
                mres_sel <= '1';
                state_next <= NORM;
              else
                output_reg_en <= '1';
                state_next <= READY_STATE;
              end if;
            else
               state_next <= ROUND; --Bolje je da ostane u ovom stanju i da se ne uvodi neka besmislena nova funkcionalnost prelaska u drugo stanje bez arhitekturnog smisla
               --sNaN ili qNaN su softverski nacini oznacavanja neispravne operacije a ne signaliziranje kvara u digitalnom sistemu
            end if;
          
          --************************************** RESULT_ZERO *****************************************
          when RESULT_ZERO =>
            --round block is disabled by default value of round_en signal, so its output is all zeros
            output_reg_en <= '1';
            state_next <= READY_STATE;
          
          --************************************** READY_STATE *****************************************
          when READY_STATE =>
            rdy <= '1';
            state_next <= IDLE;
          
          --************************************** when others *****************************************  
          when others =>
            state_next <= IDLE;
        
        end case;
    
    end process control_proc;

end Behavioral;