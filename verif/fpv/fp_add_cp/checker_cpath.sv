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
			op1_sign,
			op2_sign, 
			input_comb_s, 
			ed_val, 
			count_s,
			count_temp_s,
			sticky_out_s, 
			op1_smaller_s,
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
					 //OVA VREDNOST JE VAZNA ZBOG ZAOKRUZIVANJA, pogotovo u slucaju ODUZMANJA posto se brojevi oduzimaju ukljucujuci prosirene frakcije !
	localparam NORM_COUNT_MAX = 25;//25 pomeranje u okviru normalizacije za 25 zato sto n_count_s brojac krece od nule

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
	state_tr_nbuff1: assert property ((state_reg==NORM_BUFF && n_count_s==NORM_COUNT_MAX) |=> state_reg==RESULT_ZERO); //rezultat ce biti nula
	state_tr_nbuff2: assert property ((state_reg==NORM_BUFF && n_count_s!=NORM_COUNT_MAX) |=> state_reg==ROUND);

	//RESULT_OVERFLOW
	state_tr_res_overflow: assert property (state_reg==RESULT_OVERFLOW |=> state_reg==NORM);

	//ROUND
	state_tr_round1: assert property ((state_reg==ROUND && round_rdy==1'b1 && round_carry==1'b1) |=> state_reg==NORM);
	state_tr_round2: assert property ((state_reg==ROUND && round_rdy==1'b1 && round_carry==1'b0) |=> state_reg==READY_STATE);
	state_tr_round3: restrict property ((state_reg==ROUND && round_rdy==1'b0) |=> state_reg==ROUND);//ova tvrdnja ne moze da se dokaze posto cover tacka nije u prostoru stanja dizajna koje je moguce dosegnuti
											//IZMENJENO I U DIZAJNU! VEROVATNO NE POSTOJI SLUCAJ KADA JE round_rdy=0 U OVOM STANJU I ZBOG TOGA NIJE MOGUCE DOKAZATI
	//RESULT_ZERO
	state_tr_res_zero: assert property (state_reg==RESULT_ZERO |=> state_reg==READY_STATE);
	
	//READY_STATE
	state_tr_ready: assert property (state_reg==READY_STATE |=> state_reg==IDLE);

	//state_assignment: assert property (state_reg==$past(state_next)); ne radi ovako...



	//*********************************************************
	//------------------- signals assertions ------------------
	//---------------------------------------------------------
	sig_assert_1: assert property ((state_reg==ROUND && round_en==1'b1) |-> round_rdy==1'b1); //dokazivanje da ce svaki put u ROUND stanju round_rdy signal biti na 1
	sig_assert_2: assert property ((state_reg==INPUT_CHECK && (op1_exp==255 || op2_exp==255)) |=> exp255_flag_s); //postavnjanje exp255 zastavice na 1
	sig_assert_3: assert property ((state_reg==INPUT_CHECK && op1_exp==0 && op2_exp==0) |=> !exp255_flag_s); //postavljanje exp255 zastavice na 0

	sig_assert_4: assert property ((state_reg==INPUT_CHECK && (op1_exp==0 ^ op2_exp==0) && (op1_fract != op2_fract)) |=> (input_comb_s==2'b10 || input_comb_s==2'b01));
		//simbol ^ oznacava xor bitwise operaciju u sistem verilogu

	sig_assert_5: assert property ((state_reg==EXP_COMPARE && input_comb_s!=2'b11) |=> ($stable(input_comb_s) until_with (state_reg==READY_STATE))); //tvrdnja je ispravna.. za slucaj da nisu oba norm broja na ulazu, jer njihova razlika moze biti veca od SHIFT_COUNT_MAX i onda se moze vratiti u SHIFT SMALLER sto je opisano u sig_assert_6
	
	sig_assert_6: assert property ((state_reg==SHIFT_SMALLER ##1 state_reg==EXP_COMPARE) |=> ($stable(input_comb_s) until_with (state_reg==READY_STATE))); //slucaj da je input_comb=11 i da je >SHIFT_COUNT_MAX
			//vrati se u shift smaller samo jednom i onda postavi input_comb_s na 10 i tako ostane stabilan do kraja..
	
	sig_assert_7: assert property (rdy |=> !rdy); //proveravanje da li ready signal padne nakon samo jednog takta na visokom nivou

	sig_assert_8: assert property (n_count_s <= NORM_COUNT_MAX); //safety property

	sig_assert_9: assert property ((start && state_reg==IDLE) |=> ##[1:38]rdy ##1 !rdy);//kompletiranje izvrsavanja - safety assertion property

	sig_assert_10: assert property (!exp255_flag_s |-> input_comb_s!=2'b01);//ukoliko je exp255 zastavica jednaka nuli to znaci da u istom taktu ulazna kombinacija mora biti razlicita od 01 (NaN result)

	sig_assert_11: assert property ((state_reg==READY_STATE && input_comb_s==2'b01) |-> !res_sign); //uspostavljanje znaka u slucaju da na izlazu treba da bude qNaN

	sig_assert_12: assert property ((state_reg==NORM_BUFF && !exp255_flag_s && n_count_s<25) |-> hidden_value==2'b01); //pravilno generisanje skrivene vrednosti rezultata (hidden_value) nakon NORM iteracija

	sig_assert_13: assert property (state_reg==FRACTION_ADD |-> (norm_exp==op1_exp || norm_exp==op2_exp)); //potvrda da je exponent uskladjen pravilno u momentu sabiranja


	//*********************************************************
	//----------------- Sticky bit checking -------------------
	//---------------------------------------------------------
	sig_assert_sticky_1: assert property((state_reg==FRACTION_ADD && (count_temp_s==0 || count_temp_s==1 || count_temp_s==2)) |-> sticky_out_s==0); //ugaoni slucaj
	sig_assert_sticky_2: assert property((state_reg==FRACTION_ADD && count_temp_s==5 && op1_smaller_s && input_comb_s==2'b11) |-> sticky_out_s==(op1_fract[2] | op1_fract[1] | op1_fract[0])); //primer op1>op2
	sig_assert_sticky_3: assert property((state_reg==FRACTION_ADD && count_temp_s==5 && !op1_smaller_s && input_comb_s==2'b11) |-> sticky_out_s==(op2_fract[2] | op2_fract[1] | op2_fract[0])); //primer op2>op1
	sig_assert_sticky_4: assert property((state_reg==FRACTION_ADD && count_temp_s==26 && input_comb_s==2'b11) |-> sticky_out_s==1); //ugaoni slucaj



	//*********************************************************
	//------------------- deadlock checking -------------------
	//---------------------------------------------------------

	deadlock_assert_1: assert property (state_reg==SHIFT_SMALLER |-> ##[1:SHIFT_COUNT_MAX+1] state_reg!=SHIFT_SMALLER);//26 + 1 za final check vrednosti koja je dobijena dekrementiranjem u prethodnom ciklusu
	deadlock_assert_2: assert property (state_reg==NORM |-> ##[1:NORM_COUNT_MAX+1] state_reg!=NORM);//25+1=26 (brojac n_count_s krece od nule)


	//*********************************************************
	//------------------- fflags assertions -------------------
	//---------------------------------------------------------

	  //sNaN on input
	NV_flag_gen_1: assert property ((state_reg==INPUT_CHECK && ((op1_exp==255 && op1_fract[22]==1'b0 && op1_fract>0) || (op2_exp==255 && op2_fract[22]==1'b0 && op2_fract>0))) |=> nv_flag_s);
	NV_flag_gen_2: assert property ((state_reg==INPUT_CHECK && ((op1_exp==255 && op1_fract==0) && (op2_exp==255 && op2_fract==0)) && op1_sign!=op2_sign) |=> nv_flag_s);
	NV_flag_gen_3: assert property (input_comb_s!=2'b01 |-> !nv_flag_s);
	
	  //OF_flag_gen_1: assert property (of_flag_s |-> $past(state_reg==RESULT_OVERFLOW));
	OF_flag_gen_1: assert property (state_reg==RESULT_OVERFLOW |=> of_flag_s);

	UF_flag_gen_1: assert property (uf_flag_s |-> norm_exp==0);

	NX_flag_gen_1: assert property ((uf_flag_s || of_flag_s) |-> nx_flag_s);
	NX_flag_gen_2: assert property ((nx_flag_s && !uf_flag_s && !of_flag_s & state_reg==READY_STATE) |-> fflags==5'b00001);
	NX_flag_gen_3: assert property ((nx_flag_s && uf_flag_s && !of_flag_s & state_reg==READY_STATE) |-> fflags==5'b00011);
	NX_flag_gen_4: assert property ((nx_flag_s && !uf_flag_s && of_flag_s & state_reg==READY_STATE) |-> fflags==5'b00101);
	  //NX_flag_gen_1: assert property (); //generise se u okviru round bloka i besmisleno je tvrditi vrednost ovde.. osim u slucajevima za UF i OF flegove

	  //asserting allowed combinations of fflags
	fflags_assert_1: assert property ((state_reg==READY_STATE && nv_flag_s) |-> fflags==5'b10000);
	fflags_assert_2: assert property (dz_flag_s==1'b0);
	fflags_assert_3: assert property ((state_reg==READY_STATE && of_flag_s) |-> fflags==5'b00101); //za podignutu OF zastavicu bice podignuta i NX zastavica
	fflags_assert_4: assert property ((state_reg==READY_STATE && uf_flag_s) |-> fflags==5'b00011); //za podignutu UF zastavicu bice podignuta i NX zastavica
	fflags_assert_5: assert property ((state_reg==READY_STATE && nx_flag_s) |-> (fflags==5'b00001 || fflags==5'b00101 || fflags==5'b00011));  //dozvoljeni izlazi za slucaj da je NX zastavica podignuta



	//*********************************************************
	//------------------- cover points ------------------------
	//---------------------------------------------------------

	  //NORM_COUNT_MAX=25, SHIFT_COUNT_MAX=26

	//edge cases SHIFT_SMALLER
	cvr_count_sig_1: cover property(state_reg==SHIFT_SMALLER && count_s==SHIFT_COUNT_MAX);
	cvr_count_sig_2: cover property (state_reg==SHIFT_SMALLER && input_comb_s==2'b11 && count_s==24 && input_comb_s==2'b11 && op1_fract[22]==1'b1 && op2_fract[0]==1'b1 && op1_sign==op2_sign); //addition
	cvr_count_sig_3: cover property (state_reg==SHIFT_SMALLER && input_comb_s==2'b11 && count_s==25 && input_comb_s==2'b11 && op1_fract[22]==1'b1 && op2_fract[0]==1'b1 && op1_sign!=op2_sign); //subtraction
	
	
	//edge cases NORM
	cvr_ncount_sig_1: cover property (state_reg==NORM && n_count_s==NORM_COUNT_MAX && op1_fract!=0 && op2_fract!=0); //slucaj kada je norm_count=25 rezultat treba da je nula
	cvr_ncount_sig_2: cover property (state_reg==NORM && n_count_s==NORM_COUNT_MAX-3 && op1_fract!=0 && op2_fract!=0 && op1_fract!=op2_fract);//provereno tacno za N_COUNT_MAX-3 dobijen ispravan rezultat

	  //ugaoni slucaj kada se jedinica pronadje nakon ncount=23 i prosledi se vrednost u hidden_value, u sledecoj iteraciji ncount_s=24 hidden_value=01 sto je ukupno 25 iteracija
          //NORM stanje ubacuje MSB u hidden_value u svakom taktu, za ncount=24 znaci da je bilo 25 iteracija ukupno hidden_value=01 i zato prelazi na norm_buff i brojac ostaje na 24
	cvr_ncount_sig_3: cover property ((state_reg==NORM && n_count_s==NORM_COUNT_MAX-1) ##1 (state_reg==NORM_BUFF && hidden_value==2'b01)); //rezultat je razlicit od nule ali je rezultujuca frakcija nula
	
	cvr_ncount_sig_4: cover property (state_reg==NORM && n_count_s==NORM_COUNT_MAX);// ovde rezultat treba da je nula posto
	cvr_ncount_sig_5: cover property (state_reg==NORM && n_count_s==NORM_COUNT_MAX+1);//ova tacka pokrivenosti ne postoji u prostoru stanja dizajna i dobro je sto je alat nije pronasao
	cvr_ncount_sig_6: cover property ((state_reg==NORM && n_count_s==1) ##1 (state_reg==NORM_BUFF && hidden_value==2'b01)); //provera za vrednost ugaonog slucaja kada je ima samo jedno pomeranja dva NORM
	cvr_ncount_sig_7: cover property ((state_reg==NORM && n_count_s==0) ##1 (state_reg==NORM_BUFF && hidden_value==2'b01)); //provera za vrednost ugaonog slucaja kada nema pomeranja i ima samo jedno NORM
	
	
	cvr_rnd_carry_sig_1: cover property (state_reg==ROUND && round_carry==1'b1); // tacka pokrivenosti za slucaj kada dodje do generisanja bita prenosa prilikom zaokruzivanja rezultata
		
	cvr_rnd_carry_sig_2: cover property (state_reg==ROUND && round_carry==1'b0 && fflags==5'b00000 && exp255_flag_s==1'b0); //slucaj kada se ne generise prenos u okviru zaokruzivanja broja (redovan obican slucaj obican normalizovan rezultat)	

	cvr_ROUND: cover property (state_reg==ROUND && round_rdy==1'b0); //ovu tacku nije moguce pokriti jer ne postoji u prostoru stanja dizajna !
	


endchecker
