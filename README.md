# FPGA DSP Command Processor (OscilloGen-Analyzer)

## Overview
This project implements a **command-driven DSP engine on FPGA**.  
An external microcontroller (MCU) sends command bytes and raw data samples to the FPGA via UART.  
The FPGA executes heavy signal-processing tasks (FFT, filtering, edge detection, modulation, waveform generation) directly in hardware, then streams results back to the MCU.

This architecture offloads computationally expensive DSP operations from the MCU, enabling real-time performance in embedded systems.

---

## System Architecture
- **MCU → FPGA UART RX**: MCU sends `[CMD][LEN][DATA...]`.
- **Command Decoder**: Decodes command byte and enables the corresponding DSP block.
- **DSP Blocks**:
  - `block_fft.vhd` – Fast Fourier Transform
  - `block_filter.vhd` – FIR/IIR filtering
  - `block_edge.vhd` – Edge detection (derivative/convolution)
  - `block_mod.vhd` – Modulation (carrier multiply)
  - `block_wave.vhd` – Waveform generator (DDS/LUT)
- **Output MUX**: Routes processed data from the active block.
- **FPGA → MCU UART TX**: Streams `[RESULT...]` back to MCU.

---

## File Structure
```
/src
  dsp_top.vhd            -- Top-level integration
  uart_rx.vhd            -- UART receiver
  uart_tx.vhd            -- UART transmitter
  command_splitter.vhd   -- Protocol parser (command + payload)
  stream_to_uart.vhd     -- Packs processed samples into UART bytes
  block_fft.vhd          -- FFT block
  block_filter.vhd       -- Filtering block
  block_edge.vhd         -- Edge detection block
  block_mod.vhd          -- Modulation block
  block_wave.vhd         -- Waveform generator block

/testbench
  tb_dsp_top.vhd         -- System-level testbench
  tb_block_fft.vhd       -- Unit test for FFT
  tb_block_filter.vhd    -- Unit test for filter
  ...
```

---

## Commands
| Command Byte | Function            |
|--------------|---------------------|
| `0x01`       | FFT                 |
| `0x02`       | Filtering           |
| `0x03`       | Edge Detection      |
| `0x04`       | Modulation          |
| `0x05`       | Waveform Generation |

---

## Usage
1. **Synthesize & program FPGA** with `dsp_top.vhd`.
2. **MCU sends command** byte followed by data samples:
   ```
   [CMD][LEN][DATA...]
   ```
   - `CMD`: one of the command bytes above
   - `LEN`: number of samples (16-bit words)
   - `DATA`: raw input samples
3. **FPGA processes data** in the selected DSP block.
4. **Results returned** over UART as 16-bit words.

---

## Testing
- Run **unit testbenches** for each DSP block (`tb_block_fft.vhd`, etc.).
- Use **system testbench** (`tb_dsp_top.vhd`) to simulate MCU → FPGA → MCU flow.
- Verify UART framing and DSP outputs against expected results.
