SIM ?= iverilog
RUN ?= vvp
.PHONY: test clean

test:
	mkdir -p build
	$(SIM) -g2012 -Wall -s tb_tessera_dispatcher -o build/tessera_dispatcher.vvp rtl/tessera_dispatcher.sv tb/tb_tessera_dispatcher.sv
	$(RUN) build/tessera_dispatcher.vvp

clean:
	rm -rf build
