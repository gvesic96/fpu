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
			round_en,
			nv_flag_s,
			dz_flag_s,
			of_flag_s,
			uf_flag_s,
			nx_flag_s,
			fflags, 
			res_sign);

	default
	clocking @(posedge clk);
	endclocking

	default disable iff rst;

	localparam SHIFT_COUNT_MAX = 26; //26 pomeranja daju skrivenu jedinicu na poslednjem bitu prosirene frakcije, za 27 i ona ce ispasti iz prosirene frakcije i broj se moze smatrati nulom
	localparam NORM_COUNT_MAX = 25;//25 pomeranje u okviru normalizacije za 25 posto n_count_s brojac krece od nule

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
	state_tr_shift_sm1: assert property ((state_reg==SHIFT_SMALLER && count_s>0 && count_s<=SHIFT_COUNT_MAX) |=> state_reg==SHIFT_SMALLER); //pomeranje je dozvoljeno za razliku u eksponentima maksimalno 26
	state_tr_shift_sm2: assert property ((state_reg==SHIFT_SMALLER && count_s==0) |=> state_reg==FRACTION_ADD); 
	state_tr_shift_sm3: assert property ((state_reg==SHIFT_SMALLER && count_s>SHIFT_COUNT_MAX && input_comb_s==2'b11) |=> (state_reg==EXP_COMPARE && input_comb_s==2'b10)); //za razliku 27 i vecu besmisleno je pomerati

	//FRACTION_ADD
	state_tr_fract_add: assert property (state_reg==FRACTION_ADD |=> state_reg==NORM);

	//NORM
	state_tr_norm1: assert property ((state_reg==NORM && norm_exp==0) |=> state_reg==RESULT_ZERO);
	state_tr_norm2: assert property ((state_reg==NORM && (hidden_value==2'b10 || hidden_value==2'b11) && norm_exp==254) |=> state_reg==RESULT_OVERFLOW );
	state_tr_norm3: assert property ((state_reg==NORM && (hidden_value==2'b10 || hidden_value==2'b11) && (norm_exp!=254 && norm_exp !=0)) |=> state_reg==NORM_BUFF);
	state_tr_norm4: assert property ((state_reg==NORM && norm_exp!=0 && hidden_value==2'b00 && (input_comb_s==2'b10 || input_comb_s==2'b01)) |=> state_reg==NORM_BUFF);
	state_tr_norm5: assert property ((state_reg==NORM && norm_exp!=0 && hidden_value==2'b00 && (input_comb_s==2'b00 || input_comb_s==2'b11) && n_count_s<NORM_COUNT_MAX) |=> state_reg==NORM);	
	state_tr_norm6: assert property ((state_reg==NORM && norm_exp!=0 && hidden_value==2'b00 && (input_comb_s==2'b00 || input_comb_s==2'b11) && n_count_s==NORM_COUNT_MAX) |=> state_reg==NORM_BUFF);
	state_tr_norm7: assert property ((state_reg==NORM && norm_exp!=0 && hidden_value==2'b01) |=> state_reg==NORM_BUFF);

	//NORM_BUFF
	state_tr_nbuff1: assert property ((state_reg==NORM_BUFF && n_count_s==NORM_COUNT_MAX) |=> state_reg==RESULT_ZERO);
	state_tr_nbuff2: assert property ((state_reg==NORM_BUFF && n_count_s!=NORM_COUNT_MAX) |=> state_reg==ROUND);

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
	//------------------- counters assertions -----------------
	//---------------------------------------------------------
	
	//counter_assert_1: assert property(n_count_s);


	//*********************************************************
	//------------------- signals assertions ------------------
	//---------------------------------------------------------
	sig_assert_1: assert property ((state_reg==ROUND && round_en==1'b1) |-> round_rdy==1'b1); //dokazivanje da ce svaki put u ROUND stanju round_rdy signal biti na 1
	sig_assert_2: assert property ((state_reg==INPUT_CHECK && (op1_exp==255 || op2_exp==255)) |=> exp255_flag_s);
	sig_assert_3: assert property ((state_reg==INPUT_CHECK && op1_exp==0 && op2_exp==0) |=> !exp255_flag_s);

	sig_assert_4: assert property ((state_reg==INPUT_CHECK && (op1_exp==0 ^ op2_exp==0) && (op1_fract != op2_fract)) |=> (input_comb_s==2'b10 || input_comb_s==2'b01));
		//simbol ^ oznacava xor bitwise operaciju u sistem verilogu
	sig_assert_5: assert property ((state_reg==EXP_COMPARE && input_comb_s!=2'b11) |=> ($stable(input_comb_s) until_with (state_reg==READY_STATE))); //tvrdnja je ispravna
	
	sig_assert_6: assert property ((state_reg==SHIFT_SMALLER ##1 state_reg==EXP_COMPARE) |=> ($stable(input_comb_s) until_with (state_reg==READY_STATE))); //slucaj da je input_comb=11 i da je >SHIFT_COUNT_MAX

	//sig_assert_6: assert property (state_reg==LOAD_BUFF |-> ##[1:50]rdy ##1 !rdy); //ovaj assert je prosao, ali treba obratiti paznju na ostajanje 255 taktova u shift smaller stanju !
											//reseno ostajanje 255 taktova u shift_smaller stanju ? Trebalo bi..
	sig_assert_7: assert property (rdy |=> !rdy);

	sig_assert_8: assert property (n_count_s <= NORM_COUNT_MAX); //safety property

	sig_assert_9: assert property ((start && state_reg==IDLE) |=> ##[1:50]rdy ##1 !rdy);//execution completeness safety assertion

	

	  //sticky bit assertion
	//sig_assert_8: assert property ();

	//sig_assert_7: assert property (input_comb_s==2'b01 |=> ##[1:$]res_sign==0);


	//*********************************************************
	//------------------- deadlock checking -------------------
	//---------------------------------------------------------

	deadlock_assert_1: assert property (state_reg==SHIFT_SMALLER |-> ##[1:27] state_reg!=SHIFT_SMALLER);//26 + 1 za final check vrednosti koja je dobijena dekrementiranjem u prethodnom ciklusu
	deadlock_assert_2: assert property (state_reg==NORM |-> ##[1:26] state_reg!=NORM);//26 zato sto se inkrementira i nema ciklus overheada


	//*********************************************************
	//------------------- fflags assertions -------------------
	//---------------------------------------------------------

	  //asserting allowed combinations of fflags
	fflags_assert_1: assert property ((state_reg==READY_STATE && nv_flag_s) |-> fflags==5'b10000);
	fflags_assert_2: assert property (dz_flag_s==1'b0);
	fflags_assert_3: assert property ((state_reg==READY_STATE && of_flag_s) |-> fflags==5'b00101);
	fflags_assert_4: assert property ((state_reg==READY_STATE && uf_flag_s) |-> fflags==5'b00011);
	fflags_assert_5: assert property ((state_reg==READY_STATE && nx_flag_s) |-> (fflags==5'b00001 || fflags==5'b00101 || fflags==5'b00011));



	//*********************************************************
	//------------------- cover points ------------------------
	//---------------------------------------------------------

	cover_shiftcount_sig: cover property(state_reg==SHIFT_SMALLER && count_s==SHIFT_COUNT_MAX);

	cover_ncount_sig: cover property (state_reg==NORM && n_count_s==NORM_COUNT_MAX && op1_fract!=0 && op2_fract!=0);
	cover_ncount_sig_0: cover property (state_reg==NORM && n_count_s==NORM_COUNT_MAX-3 && op1_fract!=0 && op2_fract!=0 && op1_fract!=op2_fract);//provereno tacno za N_COUNT_MAX-5
	cover_ncount_sig_1: cover property (state_reg==NORM && n_count_s==NORM_COUNT_MAX+1);
	//cover_ncount_sig_2: cover property (n_count_s==NORM_COUNT_MAX);
		
	cover_rnd_carry_sig: cover property (state_reg==ROUND && round_carry==1'b1); // tacka pokrivenosti za slucaj kada dodje do generisanja bita prenosa prilikom zaokruzivanja rezultata
	cover_ROUND: cover property (state_reg==ROUND && round_rdy==1'b0); //ovu tacku nije moguce pokriti jer ne postoji u prostoru stanja dizajna !
	

endchecker
