bind add_module add_module_checker c0(.clk(clk), 
					.rst(rst), 
					.op1(op1), 
					.op2(op2), 
					.start(start), 
					.rdy(rdy),
					//.ed_val(control_path.ed_val),
					//.ba_op_1_s(control_path.ba_op_1_s),
					.result(result));
