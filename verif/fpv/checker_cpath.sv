checker checker_cpath(  clk, 
			rst, 
			state_reg, 
			state_next, 
			start, 
			rdy, 
			exp255_flag_s, 
			op1_exp, 
			op2_exp, 
			op1_fract, 
			op2_fract, 
			input_comb_s, 
			ed_val, 
			count_s, 
			norm_exp, 
			hidden_value, 
			n_count_s, 
			round_carry, 
			round_rdy, 
			res_sign);

	default
	clocking @(posedge clk);
	endclocking

	default disable iff rst;


	typedef enum logic [3:0]{
	  IDLE            = 4'b0000,
	  LOAD_BUFF       = 4'b0001,
	  INPUT_CHECK     = 4'b0010,
	  EXP_COMPARE     = 4'b0011,
	  SHIFT_SMALLER   = 4'b0100,
	  FRACTION_ADD    = 4'b0101,
	  NORM            = 4'b0110,
	  NORM_BUFF       = 4'b0111,
	  RESULT_OVERFLOW = 4'b1000,
	  ROUND           = 4'b1001,
	  RESULT_ZERO     = 4'b1010,
	  READY_STATE     = 4'b1011
	} add_state_type;

	//*********************************************************
	//-------------- state transitions assertions -------------
	//---------------------------------------------------------
	//IDLE
	state_tr_idle1: assert property ((state_reg == IDLE && start) |=> state_reg==LOAD_BUFF);
	state_tr_idle2: assert property ((state_reg==IDLE && !start) |=> state_reg==IDLE);	
	//LOAD_BUFF	
	state_tr_load_buff: assert property (state_reg==LOAD_BUFF |=> state_reg==INPUT_CHECK);
	
	//INPUT_CHECK
	state_tr_input_check: assert property (state_reg==INPUT_CHECK |=> state_reg==EXP_COMPARE);
	
	//EXP_COMPARE
	state_tr_exp_comp1: assert property ((state_reg==EXP_COMPARE && input_comb_s==2'b00) |=> state_reg==RESULT_ZERO);
	state_tr_exp_comp2: assert property ((state_reg==EXP_COMPARE && input_comb_s!=2'b00 && ed_val==9'b000000000) |=> state_reg==FRACTION_ADD);
	state_tr_exp_comp3: assert property ((state_reg==EXP_COMPARE && input_comb_s!=2'b00 && ed_val!=9'b000000000) |=> state_reg==SHIFT_SMALLER);
	
	//SHIFT_SMALLER
	state_tr_shift_sm1: assert property ((state_reg==SHIFT_SMALLER && count_s>0 && count_s<27) |=> state_reg==SHIFT_SMALLER);
	state_tr_shift_sm2: assert property ((state_reg==SHIFT_SMALLER && count_s==0) |=> state_reg==FRACTION_ADD);
	state_tr_shift_sm3: assert property ((state_reg==SHIFT_SMALLER && count_s>26 && input_comb_s==2'b11) |=> (state_reg==EXP_COMPARE && input_comb_s==2'b10));	

	//FRACTION_ADD
	state_tr_fract_add: assert property (state_reg==FRACTION_ADD |=> state_reg==NORM);

	//NORM
	state_tr_norm1: assert property ((state_reg==NORM && norm_exp==0) |=> state_reg==RESULT_ZERO);
	state_tr_norm2: assert property ((state_reg==NORM && (hidden_value==2'b10 || hidden_value==2'b11) && norm_exp==254) |=> state_reg==RESULT_OVERFLOW );
	state_tr_norm3: assert property ((state_reg==NORM && (hidden_value==2'b10 || hidden_value==2'b11) && (norm_exp!=254 && norm_exp !=0)) |=> state_reg==NORM_BUFF);
	state_tr_norm4: assert property ((state_reg==NORM && norm_exp!=0 && hidden_value==2'b00 && (input_comb_s==2'b10 || input_comb_s==2'b01)) |=> state_reg==NORM_BUFF);
	state_tr_norm5: assert property ((state_reg==NORM && norm_exp!=0 && hidden_value==2'b00 && (input_comb_s==2'b00 || input_comb_s==2'b11) && n_count_s<25) |=> state_reg==NORM);	
	state_tr_norm6: assert property ((state_reg==NORM && norm_exp!=0 && hidden_value==2'b00 && (input_comb_s==2'b00 || input_comb_s==2'b11) && n_count_s==25) |=> state_reg==NORM_BUFF);
	state_tr_norm7: assert property ((state_reg==NORM && norm_exp!=0 && hidden_value==2'b01) |=> state_reg==NORM_BUFF);

	//NORM_BUFF
	state_tr_nbuff1: assert property ((state_reg==NORM_BUFF && n_count_s==25) |=> state_reg==RESULT_ZERO);
	state_tr_nbuff2: assert property ((state_reg==NORM_BUFF && n_count_s!=25) |=> state_reg==ROUND);

	//RESULT_OVERFLOW
	state_tr_res_overflow: assert property (state_reg==RESULT_OVERFLOW |=> state_reg==NORM);

	//ROUND
	state_tr_round1: assert property ((state_reg==ROUND && round_rdy==1'b1 && round_carry==1'b1) |=> state_reg==NORM);
	state_tr_round2: assert property ((state_reg==ROUND && round_rdy==1'b1 && round_carry==1'b0) |=> state_reg==READY_STATE);
	state_tr_round3: assert property ((state_reg==ROUND && round_rdy==1'b0) |=> state_reg==ROUND);//ova tvrdnja ne moze da se dokaze posto cover tacka nije u prostoru stanja dizajna koje je moguce dosegnuti
											//IZMENJENO I U DIZAJNU! VEROVATNO NE POSTOJI SLUCAJ KADA JE round_rdy=0 U OVOM STANJU I ZBOG TOGA NIJE MOGUCE DOKAZATI
	//RESULT_ZERO
	state_tr_res_zero: assert property (state_reg==RESULT_ZERO |=> state_reg==READY_STATE);
	
	//READY_STATE
	state_tr_ready: assert property (state_reg==READY_STATE |=> state_reg==IDLE);

	//state_assignment: assert property (state_reg==$past(state_next));

	//*********************************************************
	//------------------- signals assertions ------------------
	//---------------------------------------------------------
	sig_assert_1: assert property (state_reg==ROUND |-> round_rdy==1'b1); //dokazivanje da ce svaki put u ROUND stanju round_rdy signal biti na 1
	sig_assert_2: assert property ((state_reg==INPUT_CHECK && (op1_exp==255 || op2_exp==255)) |=> exp255_flag_s);
	sig_assert_3: assert property ((state_reg==INPUT_CHECK && op1_exp==0 && op2_exp==0) |=> !exp255_flag_s);

	sig_assert_4: assert property ((state_reg==INPUT_CHECK && (op1_exp==0 ^ op2_exp==0) && (op1_fract != op2_fract)) |=> (input_comb_s==2'b10 || input_comb_s==2'b01));
		//simbol ^ oznacava xor bitwise operaciju u sistem verilogu
	sig_assert_5: assert property ((state_reg==EXP_COMPARE) |=> ($stable(input_comb_s) until_with (state_reg==READY_STATE))); //ovo nesto ne valja? ????
	//sig_assert_5: assert property ($stable(input_comb_s)); //kada dodje do promene signala property ce se evaluirati u tom taktu i prijaviti pad propertija u narednom taktu
								//pad propertija se ne prijavljuje u istom taktu kada se dogodi promena vec u narednom taktu ? Tako bi trebalo.

	sig_assert_6: assert property (state_reg==LOAD_BUFF |-> ##[1:50]rdy ##1 !rdy); //ovaj assert je prosao, ali treba obratiti paznju na ostajanje 255 taktova u shift smaller stanju !
											//reseno ostajanje 255 taktova u shift_smaller stanju ? Trebalo bi..
	sig_assert_7: assert property (rdy |=> !rdy);

	//sig_assert_8: assert property ();

	//sig_assert_7: assert property (input_comb_s==2'b01 |=> ##[1:$]res_sign==0);

	//*********************************************************
	//------------------- cover points ------------------------
	//---------------------------------------------------------

	cover_rnd_carry_sig: cover property (state_reg==ROUND && round_carry==1'b1); // tacka pokrivenosti za slucaj kada dodje do generisanja bita prenosa prilikom zaokruzivanja rezultata
	cover_ROUND: cover property (state_reg==ROUND && round_rdy==1'b0); //ovu tacku nije moguce pokriti jer ne postoji u prostoru stanja dizajna !
	

endchecker
