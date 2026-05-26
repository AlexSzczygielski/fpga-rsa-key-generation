# fpga-rsa-key-generation
RSA key generation using FPGA - Verilog, Vivado 2023.1. Final project for [Systemy Dedykowane w Układach Programowalnych](https://github.com/AlexSzczygielski/sdup-labs) laboratories.

## Repository Structure

```text
.
├── src/                # Verilog/SystemVerilog source files
├── constraints/        # XDC constraint files
├── sim/                # Testbenches
├── ip/                 # Vivado IP configuration files (*.xci)
├── scripts/            # Tcl scripts
├── docs/               # Documentation
├── .gitignore
└── README.md
```

## Requirements

- Vivado 2023.1 or newer
- TCL usage

> **TCL (Tool Command Language)** is a scripting language used by Vivado to automate project setup and builds.  
> Instead of manually creating the project in the GUI, the `create_project.tcl` script automatically adds sources, constraints, IP, and settings so the project can be recreated on any machine with one command.

## First-Time Setup (Run the Project)

```bash
git clone <repository-url>
cd fpga-rsa-key-generation
```

After cloning the repository:

### 1. Open Vivado

Start Vivado 2023.1.

### 2. Load Project from Script

Instead of manually creating a project, generate it from the repository:

- In Vivado GUI:
  ```
  Tools → Run Tcl Script
  ```

- Select:
  ```
  scripts/create_project.tcl
  ```

OR run from terminal:

```bash
vivado -mode batch -source scripts/create_project.tcl
```

### 3. Open the Generated Project

Vivado will create the project environment automatically.

You can now:
- Synthesize
- Implement
- Generate bitstream
- Run simulation

---

## Commiting Changes (Daily Workflow)

### Step 1: Finish your work in Vivado and save changes
---

### Step 2: Check filepaths

Important rule:

👉 Always make sure your files are saved inside the repository folders:

```text
src/
constraints/
sim/
ip/
```

Do NOT work only inside Vivado’s generated folders like `.runs/`.

---

### Step 3: Update Project File List (IMPORTANT)

If you:
- added a new Verilog file
- removed a file
- added IP

**Then you MUST regenerate the project script:**

In Vivado:
```
File → Write Project Tcl
```

Overwrite:
```text
scripts/create_project.tcl
```

> This ensures Git knows about your changes.

---

### Step 4: Commit Changes to Git

After closing or saving Vivado work:

Check what changed:

```bash
git status
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Add new module / fix bug / update design"
```

Push to GitHub:

```bash
git push
```

---

## Full Workflow Summary

Every time you work:

```text
1. Open Vivado using create_project.tcl
2. Modify Verilog / constraints / IP
3. Save files into src/ constraints/ ip/
4. Regenerate create_project.tcl (if structure changed)
5. git add .
6. git commit -m "message"
7. git push
```

---

## ⚠️ Golden Rules

### ✔️ Commit:
- src/*.v
- constraints/*.xdc
- sim/*
- ip/*.xci
- scripts/create_project.tcl

### ❌ Never commit:
- .runs/
- .cache/
- .gen/
- .xil/
- bitstreams (*.bit)
- logs (*.log)

---

## Rebuilding on Another Machine

To rebuild everything:

```bash
git clone <repo>
cd fpga-rsa-key-generation
vivado -mode batch -source scripts/create_project.tcl
```

Then open Vivado and continue working normally.