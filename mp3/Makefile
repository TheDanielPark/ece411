VCS=vcs
VCSFLAGS=-sverilog -timescale=1ns/10ps -full64 -debug_access+all +v2k -nc -lca
VCSGUIFLAGS=-gui -kdb
.DEFAULT_GOAL:=mp3

HVL_SRC=hvl
HDL_SRC=hdl
HDL_DEPS=rv32i_mux_types.sv rv32i_types.sv
HDL=$(addprefix $(HDL_SRC)/, $(HDL_DEPS)) $(shell find $(HDL_SRC)/ -type f -name '*.sv' | sort)
HVL=$(wildcard $(HVL_SRC)/*.v) $(wildcard $(HVL_SRC)/*.sv)
GOLDEN_VP=$(HDL_SRC)/cpu/cpu_golden_vcs.vp

.PHONY: mp3
mp3: $(HDL) $(HVL) $(GOLDEN_VP)
	$(VCS) $(VCSFLAGS) -top mp3_tb $^
	./simv

.PHONY: mp3_gui
mp3_gui: $(HDL) $(HVL) $(GOLDEN_VP)
	$(VCS) $(VCSFLAGS) $(VCSGUIFLAGS) -top mp3_tb $^
	./simv

.PHONY: clean
clean:
	rm -f *.vcd simv ucli.key
	rm -rf csrc/ simv.daidir/
