import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer
import random


async def reset(dut):
    dut.BTN_N = 0

    await ClockCycles(dut.CLK, 5)
    dut.BTN_N = 1


@cocotb.test()
async def test_blinky(dut):
    clock = Clock(dut.CLK, 83.3, units="ns")
    cocotb.start_soon(clock.start())

    await reset(dut)

    await Timer(20, units="us")
