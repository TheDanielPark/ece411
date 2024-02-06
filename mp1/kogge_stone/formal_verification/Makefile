run: clean compile verify

clean:
	qverify_clean
	rm -rf work log_ac transcript replay* modelsim.ini

compile:
	vlib work
	vlog -f filelist.f

verify:
	qverify -c -do "\
		onerror {exit 1 } ; \
		configure finish -exit ; \
		formal compile -d formal_tb ; \
		formal verify ;"

#netlist cutpoint dut.if_stage_i.instr_decompressed -cond 1 -driver instr_rdata_i.raw ; \
#netlist cutpoint dut.if_stage_i.instr_is_compressed -cond 1 -driver 1'b0 ; \
