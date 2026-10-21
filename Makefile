SIM ?= iverilog
RUN ?= vvp
YOSYS ?= yosys
.PHONY: test synth clean

test:
	mkdir -p build
	$(SIM) -g2012 -Wall -s tb_tessera_dispatcher -o build/tessera_dispatcher.vvp rtl/tessera_dispatcher.sv tb/tb_tessera_dispatcher.sv
	$(RUN) build/tessera_dispatcher.vvp

synth:
	$(YOSYS) -p 'read_verilog -sv rtl/tessera_dispatcher.sv; hierarchy -check -top tessera_dispatcher; proc; check; synth -top tessera_dispatcher; check; stat'

clean:
	rm -rf build
