# SNMP Library Examples

This directory contains example scripts demonstrating how to use the SnmpLib modules.

## SNMP Manager Examples (NEW)

### `manager_basic_example.exs`
Demonstrates basic SNMP Manager operations with the new type-preserving return formats:

```bash
mix run examples/manager_basic_example.exs
```

**Features shown:**
- Basic GET operations returning `{:ok, {type, value}}`
- GET BULK operations returning `{:ok, [{oid, type, value}, ...]}`
- GET NEXT operations returning `{:ok, {next_oid, {type, value}}}`
- SET operations with type-aware value handling
- Multiple GET operations with proper type preservation
- Type-aware value processing and formatting

### `manager_advanced_example.exs`
Advanced SNMP management scenarios with comprehensive type handling:

```bash
mix run examples/manager_advanced_example.exs
```

**Features shown:**
- Multi-device monitoring with type preservation
- Interface statistics collection with proper Counter32/Gauge32 handling
- SNMP table walking with type information
- Performance monitoring with type-aware calculations
- Robust error handling patterns
- Production-ready monitoring strategies

### `type_handling_example.exs`
Comprehensive guide to SNMP type system and type-aware programming:

```bash
mix run examples/type_handling_example.exs
```

**Features shown:**
- Complete SNMP type system overview
- Encoding/decoding with type preservation
- Type-aware value formatting functions
- Automatic type detection and validation
- Handling of SNMPv2c exception values
- Best practices for type-aware SNMP applications

## MIB Parser Examples

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

## Usage Notes

**SNMP Manager Examples:**
- Replace IP addresses (192.168.1.1) with your actual SNMP devices
- Update community strings as needed for your environment
- Most operations will show errors unless you have SNMP-enabled devices
- Examples demonstrate proper error handling for production use

**MIB Parser Examples:**
- All examples use `Logger.configure(level: :warn)` to suppress verbose output
- You can adjust the log level if you want to see more detailed information during compilation

## API Reference

### SNMP Manager Functions
- `SnmpLib.Manager.get/3` - Returns `{:ok, {type, value}} | {:error, reason}`
- `SnmpLib.Manager.get_bulk/3` - Returns `{:ok, [{oid, type, value}, ...]} | {:error, reason}`
- `SnmpLib.Manager.get_next/3` - Returns `{:ok, {next_oid, {type, value}}} | {:error, reason}`
- `SnmpLib.Manager.set/4` - Returns `{:ok, :success} | {:error, reason}`
- `SnmpLib.Manager.get_multi/3` - Returns `{:ok, [{oid, type, value}, ...]} | {:error, reason}`

### MIB Parser Functions
- `SnmpLib.MIB.Parser.mibdirs(directories)` - Compile all MIBs in multiple directories
- `SnmpLib.MIB.Parser.parse(mib_content)` - Parse a single MIB string

All functions return structured data that can be easily inspected and processed programmatically.

## Key Changes in v1.0.3+

**New Return Formats:**
- GET operations now return type information: `{:ok, {type, value}}`
- Bulk operations preserve full varbind format: `{oid, type, value}`
- Type information enables proper formatting and semantic understanding
- All SNMP types are preserved through encode/decode cycles

**Supported SNMP Types:**
- Basic: `:integer`, `:octet_string`, `:null`, `:object_identifier`
- Application: `:counter32`, `:gauge32`, `:timeticks`, `:counter64`, `:ip_address`, `:opaque`
- SNMPv2c Exceptions: `:no_such_object`, `:no_such_instance`, `:end_of_mib_view`