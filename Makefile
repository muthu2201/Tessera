SIM ?= iverilog
RUN ?= vvp
YOSYS ?= yosys
NEXTPNR_ECP5 ?= nextpnr-ecp5
.PHONY: test synth ecp5 clean

test:
	mkdir -p build
	$(SIM) -g2012 -Wall -s tb_tessera_dispatcher -o build/tessera_dispatcher.vvp rtl/tessera_dispatcher.sv tb/tb_tessera_dispatcher.sv
	$(RUN) build/tessera_dispatcher.vvp

synth:
	$(YOSYS) -p 'read_verilog -sv rtl/tessera_dispatcher.sv; hierarchy -check -top tessera_dispatcher; proc; check; synth -top tessera_dispatcher; check; stat'

ecp5:
	mkdir -p build
	$(YOSYS) -p 'read_verilog -sv rtl/tessera_dispatcher.sv; synth_ecp5 -top tessera_dispatcher -json build/tessera_ecp5.json'
	$(NEXTPNR_ECP5) --25k --package CABGA381 --speed 6 --json build/tessera_ecp5.json --textcfg build/tessera_ecp5.config --lpf-allow-unconstrained --freq 50

clean:
	rm -rf build
