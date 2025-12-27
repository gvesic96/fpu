checker checker_cpath(clk, rst, state_reg, state_next, start, input_comb_s, ed_val, count_s, norm_exp, hidden_value);

	default
	clocking @(posedge clk);
	endclocking

	default disable iff rst;


	typedef enum logic [3:0]{
	  IDLE            = 4'b0000,
	  LOAD_BUFF       = 4'b0001,
	  INPUT_CHECK     = 4'b0010,
	  EXP_COMPARE_1   = 4'b0011,
	  EXP_COMPARE_2   = 4'b0100,
	  SHIFT_SMALLER   = 4'b0101,
	  FRACTION_ADD    = 4'b0110,
	  NORM            = 4'b0111,
	  NORM_BUFF       = 4'b1000,
	  RESULT_OVERFLOW = 4'b1001,
	  ROUND           = 4'b1010,
	  FINAL_CHECK     = 4'b1011,
	  RESULT_ZERO     = 4'b1100,
	  READY_STATE     = 4'b1101
	} add_state_type;


	//state transitions assertions
	assert property ((state_reg == IDLE && start) |-> state_next==LOAD_BUFF);
	//assert property (state_reg==LOAD_BUFF |=> state_reg==INPUT_CHECK);
	assert property (state_reg==LOAD_BUFF |-> state_next==INPUT_CHECK);
	
	
	assert property (state_reg==INPUT_CHECK |-> state_next==EXP_COMPARE_1);
	assert property ((state_reg==EXP_COMPARE_1 && input_comb_s==2'b00) |-> state_next==RESULT_ZERO);
	assert property ((state_reg==EXP_COMPARE_1 && (input_comb_s!=2'b00)) |-> state_next==EXP_COMPARE_2);
	
	assert property ((state_reg==EXP_COMPARE_2 && ed_val==9'b000000000) |-> state_next==FRACTION_ADD);
	assert property ((state_reg==EXP_COMPARE_2 && ed_val!=9'b000000000) |-> state_next==SHIFT_SMALLER);
	assert property ((state_reg==SHIFT_SMALLER && count_s>0) |=> state_reg==SHIFT_SMALLER);
	assert property ((state_reg==SHIFT_SMALLER && count_s==0) |=> state_reg==FRACTION_ADD);
	assert property (state_reg==FRACTION_ADD |=> state_reg==NORM);
	
	assert property ((state_reg==NORM && norm_exp==0) |=> state_reg==RESULT_ZERO);
	
	assert property ((state_reg==NORM && (hidden_value==2'b10 || hidden_value==2'b11) && norm_exp==254) |=> state_reg==RESULT_OVERFLOW );
	//assert property ((state_reg==NORM && hidden_value==2'b10 && norm_exp!=254) |=> state_reg==NORM_BUFF);

	//assert property (state_reg==LOAD_BUFF |-> state_next==IDLE); //ovaj property i treba da padne


endchecker
