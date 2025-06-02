# SNMP MIB Parser Examples

This directory contains example scripts demonstrating how to use the SnmpLib.MIB.Parser module.

## Files

### `simple_mibdirs_example.exs`
A basic example showing how to use the `mibdirs/1` function to compile MIBs from multiple directories:

```bash
mix run examples/simple_mibdirs_example.exs
```

### `mibdirs_example.exs`
A comprehensive example with detailed analysis of compilation results, including:
- Directory-by-directory breakdown
- MIB metadata inspection
- Object type analysis

```bash
mix run examples/mibdirs_example.exs
```

### `test_silent_compilation.exs`
Demonstrates that the MIB compiler now operates silently without stdout noise:

```bash
mix run examples/test_silent_compilation.exs
```

## Usage

All examples use `Logger.configure(level: :warn)` to suppress verbose output and showcase the clean compilation process. You can adjust the log level if you want to see more detailed information during compilation.

## API Reference

The main functions demonstrated in these examples:

- `SnmpLib.MIB.Parser.mibdirs(directories)` - Compile all MIBs in multiple directories
- `SnmpLib.MIB.Parser.parse(mib_content)` - Parse a single MIB string

Both functions return structured data that can be easily inspected and processed programmatically.