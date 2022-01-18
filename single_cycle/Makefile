# MIT License
#
# Copyright (c) 2022 Ashwin-Rajesh
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Source files used
sources 		= rtl/core.v rtl/design.v rtl/mem_data.v rtl/mem_reg.v

# Testbench code
testbench	= tb/testbench.sv

# Result of compilation
# object		= out/$(proj_name).out

# Waveform file
# wave		= out/$(proj_name).vcd
# wave_save   = out/$(proj_name).gtkw

# Symbiyosys file
sby_conf	= formal.sby

# compile: $(object)
# .PHONY: compile

# $(object): $(sources) $(testbench)
# 	iverilog $(testbench) $(sources) -o $(object)

# $(wave): $(object) $(data)
# 	./$(object)

# view: $(wave)
# 	gtkwave $(wave) $(wave_save)
# .PHONY: simulate

# run: $(object)
# 	./$(object)
# .PHONY:run

formal: $(sources) $(sby_conf)
	sby -f $(sby_conf)
.PHONY:formal

view_fail:
	gtkwave formal/engine_0/trace.vcd out/formal.gtkw
.PHONY:view_fail

view_induct:
	gtkwave formal/engine_0/trace_induct.vcd out/formal.gtkw
.PHONY:view_induct

view_cover:
	gtkwave formal/engine_0/trace0.vcd out/formal.gtkw
.PHONY:view_cover
