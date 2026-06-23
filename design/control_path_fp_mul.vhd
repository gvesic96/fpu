----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/07/2026 01:04:54 AM
-- Design Name: 
-- Module Name: control_path_fp_mul - Behavioral
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

entity control_path_fp_mul is
    Generic (WIDTH : positive := 32;
             WIDTH_EXP : positive := 8;
             WIDTH_FRACT : positive := 23
            );
    Port ( rst : in STD_LOGIC;
           clk : in STD_LOGIC;
           start : in STD_LOGIC;

           op1 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);
           op2 : in STD_LOGIC_VECTOR(WIDTH-1 downto 0);

           
           operands_en : out STD_LOGIC;
           sa_sel : out STD_LOGIC;
           exp_val : in STD_LOGIC_VECTOR(WIDTH_EXP downto 0); --9bits wide
           exp_reg_en : out STD_LOGIC;
           
           ba_en : out STD_LOGIC;
           ba_start : out STD_LOGIC;
           ba_rdy : in STD_LOGIC;
           hidden_value_in : in STD_LOGIC_VECTOR(1 downto 0);
           hidden_value_out : out STD_LOGIC_VECTOR(1 downto 0);
           
           mres_sel : out STD_LOGIC;
           
           norm_block_en : out STD_LOGIC;
           --norm_block_load : out STD_LOGIC;
           
           mexp_sel : out STD_LOGIC;
           incr_decr_en : out STD_LOGIC;
           incr_decr_ctrl : out STD_LOGIC_VECTOR(1 downto 0);
           
           round_en : out STD_LOGIC;
           round_rdy : in STD_LOGIC;
           round_carry : in STD_LOGIC;
           
           output_reg_en : out STD_LOGIC;
           
           res_sign : out STD_LOGIC;
           
           fflags : out STD_LOGIC_VECTOR(4 downto 0);
           rdy : out STD_LOGIC
           
           );
end control_path_fp_mul;

architecture Behavioral of control_path_fp_mul is

    type mul_state_type is (IDLE, INPUT_CHECK, MUL, NORM, ROUND, READY);
    signal state_next, state_reg : mul_state_type;

    signal op1_exp_s, op2_exp_s : STD_LOGIC_VECTOR(WIDTH_EXP-1 downto 0) := (others=>'0');
    signal op1_fract_s, op2_fract_s : STD_LOGIC_VECTOR(WIDTH_FRACT-1 downto 0) := (others=>'0');
    signal op1_sign_s, op2_sign_s : STD_LOGIC;
    signal res_sign_s, res_sign_next : STD_LOGIC := '0';
    
    signal input_comb_s, input_comb_next : STD_LOGIC_VECTOR(1 downto 0);
    signal exp255_flag_s, exp255_flag_next : STD_LOGIC;
    signal ba_work_flag_s, ba_work_flag_next : STD_LOGIC;
    signal hidden_value_s, hidden_value_next : STD_LOGIC_VECTOR(1 downto 0);
    
    signal nv_flag_s, nv_flag_next : STD_LOGIC; --fflags(4)
    signal dz_flag_s, dz_flag_next : STD_LOGIC; --fflags(3)
    signal of_flag_s, of_flag_next : STD_LOGIC; --fflags(2)
    signal uf_flag_s, uf_flag_next : STD_LOGIC; --fflags(1)
    signal nx_flag_s, nx_flag_next : STD_LOGIC; --fflags(0)

begin


    res_sign <= res_sign_s;

    op1_sign_s <= op1(WIDTH-1);
    op1_exp_s <=  op1(WIDTH-2 downto WIDTH_FRACT);
    op1_fract_s <= op1(WIDTH_FRACT-1 downto 0);
    
    op2_sign_s <= op2(WIDTH-1);
    op2_exp_s <=  op2(WIDTH-2 downto WIDTH_FRACT);
    op2_fract_s <= op2(WIDTH_FRACT-1 downto 0);


    state_proc: process(clk,rst) is
    begin
        if(rst='1') then
          state_reg <= IDLE;
          res_sign_s <= '0';
          input_comb_s <= "11";
          exp255_flag_s <= '0';
          ba_work_flag_s <= '0';
          hidden_value_s <= "00";
        else
          if(clk'event and clk='1') then
            state_reg <= state_next;
            res_sign_s <= res_sign_next;
            input_comb_s <= input_comb_next;
            exp255_flag_s <= exp255_flag_next;
            ba_work_flag_s <= ba_work_flag_next;
            hidden_value_s <= hidden_value_next;
          end if;
        
        end if;
    
    end process state_proc;




    control_proc: process(start, state_reg, op1_sign_s, op1_fract_s, op1_exp_s, op2_sign_s, op2_fract_s, 
                          op2_exp_s, input_comb_s, exp_val, exp255_flag_s, ba_work_flag_s, hidden_value_s, round_rdy, round_carry, ba_rdy) is
    begin
        
        operands_en <= '0';
        sa_sel <= '0';
        res_sign_next <= res_sign_s;
        input_comb_next <= input_comb_s;
        exp255_flag_next <= exp255_flag_s;
        
        mexp_sel <= '0';
        
        ba_en <= '0';
        ba_start <= '0';
        ba_work_flag_next <= ba_work_flag_s;
        mres_sel <= '0';
        
        norm_block_en <= '0';
        
        hidden_value_next <= hidden_value_s;
        rdy <= '0';
        incr_decr_en <= '1';
        incr_decr_ctrl <= "00";
        
        
        nv_flag_next <= nv_flag_s;    
        
        case state_reg is
          
          --************************************** IDLE **********************************************
          when IDLE =>
            ba_work_flag_next <= '0';
            if(start='1') then
              state_next <= INPUT_CHECK;
              operands_en <= '1';
            else
              state_next<=IDLE;
            end if;
          
          --************************************** INPUT_CHECK ***************************************
          when INPUT_CHECK =>
            --ispitati ulaze i odrediti znak i eventualno preci u stanja
            sa_sel <= '0';
            exp_reg_en <= '1';
            
            --sign determination
            if(op1_sign_s = op2_sign_s) then
              res_sign_next <= '0';
            else
              res_sign_next <= '1';
            end if;
        
            state_next <= NORM;
        
            if(unsigned(op1_exp_s)=0 and unsigned(op2_exp_s)=0) then
              input_comb_next <= "00";
              --znak ce biti odredjen ranije i bice +-0
              --state_next<=RESULT_ZERO;
            else
              --op1 = NaN
              if((unsigned(op1_exp_s)=255 and unsigned(op1_fract_s)>0)) then
                input_comb_next <= "01";
                res_sign_next <= '0';
                --state_next<=RESULT_QNAN;
                if(op1_fract_s(WIDTH_FRACT-1)='0') then
                  --sNaN detection
                  nv_flag_next <= '1';
                else
                  nv_flag_next <= '0';
                end if;
              --op2 = NaN
              elsif(unsigned(op2_exp_s)=255 and unsigned(op2_fract_s)>0) then
                input_comb_next <= "01";
                res_sign_next <= '0';
                --state_next<=RESULT_QNAN;
                if(op2_fract_s(WIDTH_FRACT-1)='0') then
                  --sNaN detection
                  nv_flag_next <= '1';
                else
                  nv_flag_next <= '0';
                end if;
              --op1 = inf
              elsif(unsigned(op1_exp_s)=255 and unsigned(op1_fract_s)=0) then
                exp255_flag_next <= '1';
                if(unsigned(op2_exp_s)=0) then
                  --inf*0 --za nulu nije bitna frakcija jer subnormalne brojeve racunam kao nulu
                  input_comb_next <= "01";
                  res_sign_next <= '0';
                  nv_flag_next <= '1';
                  --state_next<=RESULT_QNAN;
                else
                  --inf*norm_number
                  input_comb_next <= "10"; --za ovu ulaznu kombinaciju rezultat ce biti inf? a za 00 cu koristiti kada je jedan od operanada nula a drugi norm broj
                  --state_next <= RESULT_INF;
                end if;
              --op2 = inf
              elsif(unsigned(op2_exp_s)=255 and unsigned(op2_fract_s)=0) then
                exp255_flag_next <= '1';
                if(unsigned(op1_exp_s)=0) then
                  --0*inf
                  input_comb_next <= "01";
                  res_sign_next <= '0';
                  nv_flag_next <= '1';
                  --state_next <= RESULT_QNAN;
                else
                  --norm_number*inf
                  input_comb_next <= "10";
                  --state_next <= RESULT_INF; 
                end if;
              --op1=norm_number
              elsif(unsigned(op1_exp_s)>0 and unsigned(op1_fract_s)>0) then  
                if(unsigned(op2_exp_s)=0) then
                  --norm_number*0
                  input_comb_next <= "00";
                  --state_next <= RESULT_ZERO;
                else
                  input_comb_next <= "11";
                  state_next <= MUL;
                end if;
              --op2=norm_number
              elsif(unsigned(op2_exp_s)>0 and unsigned(op2_fract_s)>0) then
                if(unsigned(op1_exp_s)=0) then
                  --0*norm_number
                  input_comb_next <= "00";
                  --state_next <= RESULT_ZERO
                else
                  input_comb_next <= "11";
                  state_next <= MUL;
                end if;
              end if;
            end if;
        
          --*************************************** MUL ******************************************
          when MUL =>
            if(ba_work_flag_s='0') then
              if(input_comb_s="11") then
                if(unsigned(exp_val)>254) then
                  --state_next <= RESULT_INF;
                  state_next <= NORM; --predji u NORM stanje i tamo postavi vrednost incr_decr_en=0 da bi dobio sve jedinice u eksponentu?
                  input_comb_next <= "10";
                  of_flag_next <= '1';
                  nx_flag_next <= '1';
                else
                  ba_start <= '1';
                  ba_work_flag_next <= '1';
                  incr_decr_ctrl <= "11"; --load value into incr_decr_block
                  state_next <= MUL;
                end if;
              end if;
            else
              --ba_work_flag_s = 1
              if(ba_rdy='0') then
                state_next <= MUL;
              else
                ba_work_flag_next <= '0';
                state_next <= NORM;
                hidden_value_next <= hidden_value_in;
                --norm_block_en <= '1';
                --norm_block_load <= '1';
              end if;
            end if;
            
          --*************************************** NORM ******************************************
          when NORM =>
            case input_comb_s is
              when "11" =>
                --result in normalized range
                norm_block_en <= '1';
                --norm_block_load <= '1';
                state_next <= ROUND;
                --uvuci dva najstarija bita u FSM od ulaza u NORM_BLOCK i onda na osnovu toga kontrolisati incr_decr_block povecati za 1 ili zadrzati
                if(hidden_value_s="10") then
                  if(unsigned(exp_val)=254) then
                    input_comb_next <= "10"; --inf combination
                    state_next <= NORM;
                    incr_decr_ctrl <= "01";
                  else
                    incr_decr_ctrl <= "01"; --increment exponent
                  end if;
                  hidden_value_next <= "01";
                else
                  incr_decr_ctrl <= "00"; --hold exponent value unchanged
                end if;
              when "01" =>
                --result qNaN
                incr_decr_en <= '0'; --set exponent to all ones
                --dodati kreiranje jedinice kao MSB-a izmenama u NORM_BLOCKU i generisanjem 2 najstarija bita za mres_sel=1 ulaz iz FSMa
                hidden_value_out <= "11";
                mres_sel <= '1';
                norm_block_en <= '1';
              when "10" =>
                --result inf
                incr_decr_en <= '0'; --set exponent to all ones
                hidden_value_out <= "10";
                norm_block_en <= '1';
                mres_sel <= '1';
              when others =>
                --result zero
                round_en <= '0';
                output_reg_en <= '1';
                state_next <= READY;
            end case;
            
          --*************************************** ROUND ******************************************
          when ROUND => 
            round_en <= '1';
            if(round_rdy='1') then
              if(round_carry='1') then
                hidden_value_next <= "10";
                state_next <= NORM;
              else
                output_reg_en <= '1';
                state_next <= READY;
              end if;
            end if;
            
          --*************************************** READY ******************************************
          when READY =>
            rdy <= '1';
            state_next <= IDLE;
          
          
          when others =>
            state_next <= IDLE;
        
        end case;
    end process control_proc;




end Behavioral;
