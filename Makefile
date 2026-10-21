SIM ?= iverilog
RUN ?= vvp
YOSYS ?= yosys
NEXTPNR_ECP5 ?= nextpnr-ecp5
.PHONY: test synth ecp5 clean

test:
	mkdir -p build
	$(SIM) -g2012 -Wall -s tb_tessera_dispatcher -o build/tessera_dispatcher.vvp rtl/tessera_dispatcher.sv tb/tb_tessera_dispatcher.sv
	$(RUN) build/tessera_dispatcher.vvp
	$(SIM) -g2012 -Wall -s tb_tessera_command_fifo -o build/tessera_command_fifo.vvp rtl/tessera_command_fifo.sv tb/tb_tessera_command_fifo.sv
	$(RUN) build/tessera_command_fifo.vvp
	$(SIM) -g2012 -Wall -s tb_tessera_vec_system -o build/tessera_vec_system.vvp rtl/tessera_dispatcher.sv rtl/tessera_command_fifo.sv rtl/tessera_dependency_scoreboard.sv rtl/tessera_vec_tile.sv rtl/tessera_vec_system.sv tb/tb_tessera_vec_system.sv
	$(RUN) build/tessera_vec_system.vvp
	$(SIM) -g2012 -Wall -s tb_tessera_tensor_tile -o build/tessera_tensor_tile.vvp rtl/tessera_tensor_tile.sv tb/tb_tessera_tensor_tile.sv
	$(RUN) build/tessera_tensor_tile.vvp
	$(SIM) -g2012 -Wall -s tb_tessera_dependency_scoreboard -o build/tessera_dependency_scoreboard.vvp rtl/tessera_dependency_scoreboard.sv tb/tb_tessera_dependency_scoreboard.sv
	$(RUN) build/tessera_dependency_scoreboard.vvp

synth:
	$(YOSYS) -p 'read_verilog -sv rtl/tessera_dispatcher.sv; hierarchy -check -top tessera_dispatcher; proc; check; synth -top tessera_dispatcher; check; stat'
	$(YOSYS) -p 'read_verilog -sv rtl/tessera_command_fifo.sv; hierarchy -check -top tessera_command_fifo; proc; check; synth -top tessera_command_fifo; check; stat'
	$(YOSYS) -p 'read_verilog -sv rtl/tessera_command_fifo.sv rtl/tessera_completion_queue.sv; hierarchy -check -top tessera_completion_queue; proc; check; synth -top tessera_completion_queue; check; stat'
	$(YOSYS) -p 'read_verilog -sv rtl/tessera_dispatcher.sv rtl/tessera_command_fifo.sv rtl/tessera_dependency_scoreboard.sv rtl/tessera_vec_tile.sv rtl/tessera_vec_system.sv; hierarchy -check -top tessera_vec_system; proc; check; synth -top tessera_vec_system; check; stat'

ecp5:
	mkdir -p build
	$(YOSYS) -p 'read_verilog -sv rtl/tessera_dispatcher.sv; synth_ecp5 -top tessera_dispatcher -json build/tessera_ecp5.json'
	$(NEXTPNR_ECP5) --25k --package CABGA381 --speed 6 --json build/tessera_ecp5.json --textcfg build/tessera_ecp5.config --lpf-allow-unconstrained --freq 50

clean:
	rm -rf build

	$(YOSYS) -p 'read_verilog -sv rtl/tessera_tensor_tile.sv; hierarchy -check -top tessera_tensor_tile; proc; check; synth -top tessera_tensor_tile; check; stat'
	$(YOSYS) -p 'read_verilog -sv rtl/tessera_dependency_scoreboard.sv; hierarchy -check -top tessera_dependency_scoreboard; proc; check; synth -top tessera_dependency_scoreboard; check; stat'
