PROJECT = top
SOURCES = src/top.sv src/game_controller.sv src/game_processor.sv src/memory.sv src/display_controller.sv src/ws2812b.sv
TOP_MODULE = top
ICEBREAKER_DEVICE = up5k
ICEBREAKER_PIN_DEF = iceBlinkPico.pcf
ICEBREAKER_PACKAGE = sg48

# COCOTB variables
export COCOTB_REDUCED_LOG_FMT=1
export PYTHONPATH := test:$(PYTHONPATH)
export LIBPYTHON_LOC=$(shell cocotb-config --libpython)

# FPGA pipeline
%.json: $(SOURCES)
	yosys -l yosys.log -p 'synth_ice40 -top $(TOP_MODULE) -json $(PROJECT).json' $(SOURCES)

%.asc: %.json $(ICEBREAKER_PIN_DEF) 
	nextpnr-ice40 --pcf-allow-unconstrained -l nextpnr.log --freq 12 --package $(ICEBREAKER_PACKAGE) --$(ICEBREAKER_DEVICE) --asc $@ --pcf $(ICEBREAKER_PIN_DEF) --json $<

%.bin: %.asc
	icepack $< $@

prog: $(PROJECT).bin #for sram
	dfu-util --device 1d50:6146 --alt 0 -D $< -R

# Testing
test_$(PROJECT):
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -o sim_build/sim.vvp -s $(TOP_MODULE) -s dump -g2012 $(SOURCES) test/dump_$(TOP_MODULE).sv
	PYTHONOPTIMIZE=${NOASSERT} MODULE=test.test_$(TOP_MODULE) vvp -M $$(cocotb-config --prefix)/cocotb/libs -m libcocotbvpi_icarus sim_build/sim.vvp
	! grep failure results.xml
test_brad:
	rm -rf sim_build/
	mkdir sim_build/
	iverilog -g2012 -o sim_build/top_tb $(SOURCES) src/top_tb.sv
	vvp sim_build/top_tb
# gtkwave top_tb.vcd top_tb.gtkw
show_%: %.vcd %.gtkw
	gtkwave $^

# general recipes
lint:
	verible-verilog-lint *v --rules_config verible.rules

clean:
	rm -rf *vcd *log *bin test/__pycache__ sim_build *.history *.xml
