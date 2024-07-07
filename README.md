# gatemate_experiments

**RISC_V**: 

Status: Incomplete

Based on https://github.com/BrunoLevy/learn-fpga/blob/master/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/README.md and https://github.com/fm4dd/gatemate-riscv

Assumes you have the olimex gatemate evaluation board:
https://www.olimex.com/Products/FPGA/GateMate/GateMateA1-EVB/open-source-hardware

The ultimate plan is to implement a basic 32 bit risc-v computer that can run doom via vga, controlled by ps/2 keyboard.

**VGA**:

Status: Incomplete

Based on Olimex's video generation articles [part 1](https://olimex.wordpress.com/2016/07/13/fpga-tutorial-vga-video-generation-with-ice40hx1k-evb-ice40-io-in-verilog/) and [part2](https://olimex.wordpress.com/2016/07/19/fpga-tutorial-vga-video-generation-with-fpga-and-verilog-add-video-memory-to-the-project-and-object-animation/)

## Instructions

You'll need to download the linux toolchain from cologne chip: https://www.colognechip.com/programmable-logic/gatemate/gatemate-download/ and modify the config.mk BIN_HOME to environment variable to point to the cc-toolchain-linux/bin folder.

You should also install iverilog, vvp and openFPGALoader via apt:
```
sudo apt install iverilog vvp openFPGALoader
```
