# toolchain
BIN_HOME = /home/devtim/gatemate/cc-toolchain-linux/bin
YOSYS = $(BIN_HOME)/yosys/yosys
PR = $(BIN_HOME)/p_r/p_r
OFL = openFPGALoader

IVL = iverilog
VVP = vvp

RM = rm -rf

VLOG_SRC = $(shell find ./src/ -type f \( -iname \*.v -o -iname \*.sv \))

synth: $(VLOG_SRC)
	$(YOSYS) -qql log/synth.log -p 'read -sv $^; synth_gatemate -top $(TOP) -nomx8 -vlog net/$(TOP)_synth.v'

impl:
	$(PR) -i net/$(TOP)_synth.v -o $(TOP) $(PRFLAGS) > log/$@.log

jtag:
	$(OFL) -c dirtyJtag $(TOP)_00.cfg

test: $(VLOG_SRC)
	$(IVL) -DBENCH ../bench.v $^ -o sim/a.out
	$(VVP) sim/a.out

clean:
	$(RM) log/*.log
	$(RM) net/*_synth.v
	$(RM) *.history
	$(RM) *.txt
	$(RM) *.refwire
	$(RM) *.refparam
	$(RM) *.refcomp
	$(RM) *.pos
	$(RM) *.pathes
	$(RM) *.path_struc
	$(RM) *.net
	$(RM) *.id
	$(RM) *.prn
	$(RM) *_00.v
	$(RM) *.used
	$(RM) *.sdf
	$(RM) *.place
	$(RM) *.pin
	$(RM) *.cfg*
	$(RM) *.cdf
	$(RM) sim/*.out