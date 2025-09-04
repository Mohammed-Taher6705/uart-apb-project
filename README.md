# uart-apb-project
UART Transmitter, Receiver, and APB Wrapper in Verilog with FPGA synthesis and verification

# UART with APB Wrapper

This project implements a **Universal Asynchronous Receiver-Transmitter (UART)** with an **AMBA APB interface** in Verilog HDL.  
It includes RTL design, verification testbenches, FPGA synthesis results, and project documentation.

---

## 📂 Repository Structure
- `src/`  → RTL design files (Verilog)
- `dv/`   → Testbenches files
- `fpga/` → FPGA synthesis runs (Quartus Prime)
- `docs/` → Project report, diagrams, and documentation

---

## 🛠️ Features
- UART Transmitter (8N1 format, start/data/stop bits)
- UART Receiver with sampling
- APB Wrapper for register access
- Self-checking testbenches
- Verified in ModelSim & synthesized on Quartus Prime



