# Ticketing and Events API

## Overview

This is a simple bootloader with a second stage boot sector that gives a memory map

## Prerequisites

- **QEMU**: Emulator for testing
- **FASM**: assembler to assemble the code
- **MAKE**: Build automation tool

## Setup Instructions

### 1. Clone the repository

```bash
git clone git@github.com:nikolaospanagopoulos/memoryMapBoot.git
cd memoryMapBoot
```

#### 2. Make the Project

```bash
make
```

#### 3. emulate

```bash
qemu-system-i386 -fda ./bin/os.bin -nographic
```
