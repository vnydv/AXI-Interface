# A simple subordinator AXI-Lite Interface

### tldr
  > Curiously picked up an ARM SoC manual, the interconnects grabbed the attention. LOL, it was good, why not try implementing one, but why AXI-Lite, hmmm... was starting out with PYNQ-ZU FPGA, AXI kinda felt familiar, from that old Inter-IIT Tech meet Chiplet Design Challenge....


The Advanced eXtensible Interface 4 (AXI4) is a family of interconnect buses defined as part of the fourth generation of the ARM Advanced Microcontroller Bus Architecture (AMBA) standard.

This repo is the implementation for AXI-lite.

Though AXI-Lite is a subset of AXI, it lacks burst access capability but has a simpler interface than the full AXI4 interface.




## Port definition
![image](https://github.com/vnydv/AXI-Interface/blob/main/docs_images/axi-lite_interface.png)

## Read Transaction Waveform
![image](https://github.com/vnydv/AXI-Interface/blob/main/docs_images/read_transaction.png)

### Read Transaction logs

![image](https://github.com/vnydv/AXI-Interface/blob/main/docs_images/read_logs.png)

## Write Transaction Waveform
![image](https://github.com/vnydv/AXI-Interface/blob/main/docs_images/write_transaction.png)

### Write Transaction logs

![image](https://github.com/vnydv/AXI-Interface/blob/main/docs_images/write_logs.png)









## Scope for Improvement
1. Add strobe signals
2. Optimise further
3. Multiple Subordinator access via ID field
4. Create a master transaction
5. Pack the module as an IP


## References

[Timing diagram reference](https://docs.amd.com/r/en-US/pg202-mipi-dphy/AXI4-Lite-Interface)

[Doc reference for Registers and Signals](https://www.realdigital.org/doc/a9fee931f7a172423e1ba73f66ca4081)

[Theory reference](https://www.arm.com/resources/education/books/fundamentals-soc)


