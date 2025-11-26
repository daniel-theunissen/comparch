import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer
import random


# async def reset(dut):
#     dut.BTN_N = 0

#     await ClockCycles(dut.CLK, 5)
#     dut.BTN_N = 1


@cocotb.test()
async def test_top(dut):
    dut.clk = 0
    await Timer(83.3, units="ns")
    clock = Clock(dut.clk, 83.3, units="ns")
    cocotb.start_soon(clock.start())
    regfile = dut.regfile.RegisterFile
    dmem = dut.memory.dmem0.memory
    pc = dut.pc
    # await reset(dut)
    await ClockCycles(dut.clk, 25)
    print(regfile.value)
    print(pc.value)
    # print(dmem.value)
    # await Timer(20, units="us")
