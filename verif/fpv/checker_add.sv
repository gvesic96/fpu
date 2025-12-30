checker add_module_checker(clk, rst, op1, op2, start, rdy, result);

	default
	clocking @(posedge clk);
	endclocking

	default disable iff rst;


	//assume property (op1 == 32'b01000010000000100100000000000111);
	//assume property (op2 == 32'h00000000);
	//assume property (start == 1'b1);

	//output normalized number
	cover_norm_number: cover property (rdy==1'b1 && result==32'b01000010000000100100000000000111);
	//output qNaN
	cover_qNaN: cover property (rdy==1'b1 && result==32'b01111111110000000000000000000000);
	//output +0
	cover_plus_zero: cover property (rdy==1'b1 && result==32'b00000000000000000000000000000000);

	//output -0   --> Nije moguce pokriti ovu tacku jer dizajn uvek nulu postavlja sa pozitivnim znakom kao rezultat
	//cover property (result == 32'b10000000000000000000000000000000);	

	//output +inf
	cover_plus_inf: cover property (rdy==1'b1 && result==32'b01111111100000000000000000000000);
	//output -inf
	cover_minus_inf: cover property (rdy==1'b1 && result==32'b01111111100000000000000000000000);



endchecker
