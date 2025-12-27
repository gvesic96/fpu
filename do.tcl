clear -all

#analyze -sv09 checker.sv bind.sv
analyze -sv09 ./verif/fpv/checker_cpath.sv 
analyze -sv09 ./verif/fpv/bind_cpath.sv

analyze -vhdl ./design/big_alu.vhd
analyze -vhdl ./design/d_reg.vhd
analyze -vhdl ./design/fract_extender.vhd
analyze -vhdl ./design/incr_decr.vhd
analyze -vhdl ./design/mux2on1.vhd
analyze -vhdl ./design/rounding_block.vhd
analyze -vhdl ./design/shift_reg_d0.vhd
analyze -vhdl ./design/small_alu.vhd
analyze -vhdl ./design/data_path_add.vhd
analyze -vhdl ./design/control_path_add.vhd
analyze -vhdl ./design/add_module.vhd

#u slucaju da se koriste VHDL i SystemVerilog ili Verilog neophodno je naglasiti u kom jeziku treba da se elaborira hardver posto ce alat kreirati model u oba jezika prilikom analiziranja
elaborate -vhdl -top add_module

clock clk
reset rst

prove -bg -all
