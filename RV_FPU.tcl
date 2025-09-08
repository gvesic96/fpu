#process for getting script file directory
variable dispScriptFile [file normalize [info script]]
proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

#change working directory to script file directory
cd [getScriptDirectory]
#set project directory
#set projectDir .\/RV32_FPU/RV_FPU_project
set projectDir .\/RV_FPU_project

file mkdir $projectDir

# MAKE A PROJECT
create_project RV_FPU_project $projectDir -part xc7z010clg400-1 -force
set_property board_part digilentinc.com:zybo-z7-10:part0:1.2 [current_project]

add_files -norecurse ./design/control_path_add.vhd
add_files -norecurse ./design/data_path_add.vhd
add_files -norecurse ./design/big_alu.vhd
add_files -norecurse ./design/small_alu.vhd
add_files -norecurse ./design/d_reg.vhd
add_files -norecurse ./design/incr_decr.vhd
add_files -norecurse ./design/mux2on1.vhd
add_files -norecurse ./design/shift_reg_d0.vhd
add_files -norecurse ./design/rounding_block.vhd
add_files -norecurse ./design/fract_extender.vhd
add_files -norecurse ./design/add_module.vhd


update_compile_order -fileset sources_1

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ./fpu_tb/fpu_add_tb.vhd

update_compile_order -fileset sim_1