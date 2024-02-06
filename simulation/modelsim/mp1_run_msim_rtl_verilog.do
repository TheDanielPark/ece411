transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+/home/danielp7/ece411/mp1/setup/hdl {/home/danielp7/ece411/mp1/setup/hdl/regfile.sv}
vlog -sv -work work +incdir+/home/danielp7/ece411/mp1/setup/hdl {/home/danielp7/ece411/mp1/setup/hdl/mp1.sv}

vlog -sv -work work +incdir+/home/danielp7/ece411/mp1/setup/hvl {/home/danielp7/ece411/mp1/setup/hvl/mp1_tb.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L arriaii_hssi_ver -L arriaii_pcie_hip_ver -L arriaii_ver -L rtl_work -L work -voptargs="+acc"  mp1_tb

add wave *
view structure
view signals
run -all
