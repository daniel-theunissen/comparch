import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer
import random


@cocotb.test()
async def test_top(dut):
    clock = Clock(dut.clk, 80, units="ns")
    cocotb.start_soon(clock.start())

    await Timer(200, units="ms")
