bind control_path_add checker_cpath c1(.clk(clk), 
					.rst(rst), 
					.state_reg(state_reg), 
					.state_next(state_next), 
					.start(start),
					.ed_val(ed_val), 
					.count_s(count_s),
					.input_comb_s(input_comb_s),
					.norm_exp(norm_exp),
					.hidden_value(hidden_value)
);
