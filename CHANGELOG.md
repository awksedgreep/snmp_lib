# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.7] - 2025-06-12

### Improved

- **MAJOR: Refactored Error Handling to Idiomatic Elixir Patterns**
  - Removed excessive try/rescue blocks throughout the codebase ("java in my elixir code")
  - Replaced 12 try/rescue blocks with `{:ok, result} | {:error, reason}` patterns
  - Enhanced error handling in ASN.1, OID, Config, and Error modules
  - Improved error messages with specific error reasons instead of generic failures
  - Added helper functions for safer error propagation and validation
  - Preserved justified try/rescue usage for external libraries, resource cleanup, and crypto operations
  - All 776 tests passing with zero regressions and full backward compatibility

### Technical Details

- **ASN.1 Module**: Removed 4 try/rescue blocks, improved encoding/decoding error handling
- **OID Module**: Removed 4 try/rescue blocks, enhanced string parsing and table index operations
- **Config Module**: Removed 2 try/rescue blocks, improved configuration loading and validation
- **Error Module**: Removed 1 try/rescue block, added proper PDU validation
- **Transport/Security**: Analyzed and preserved justified try/rescue for network and crypto operations
- **Code Quality**: Better error propagation, cleaner control flow, enhanced maintainability

## [1.0.6] - 2025-06-12

### Fixed

- **CRITICAL: Fixed Return Format Inconsistencies Throughout Project**
  - Fixed Walker module expecting incorrect 2-tuple format from `get_next/3` (would cause crashes)
  - Updated Walker to properly handle `{:ok, {next_oid, type, value}}` format and preserve type information
  - Fixed CHANGELOG documentation showing incorrect `{:ok, {next_oid, value}}` format
  - Fixed test documentation reflecting wrong expected return formats
  - Removed obsolete bug report file with outdated return format examples
  - Removed problematic test file calling private Manager functions
  - **All Manager API functions now consistently preserve SNMP type information**

### Verified

- **776 tests, 0 failures** - All functionality verified working
- **Walker module no longer crashes** when using `get_next/3`
- **100% consistent return formats** across all Manager API functions
- **Type information preserved** throughout the entire SNMP operation chain

## [1.0.5] - 2025-06-08

### Added

- **String OID Support**: Complete support for string OID encoding in all contexts
  - Added string OID parsing and encoding for `:auto` type detection
  - Added string OID support for explicit `:object_identifier` type
  - Graceful fallback to `:null` encoding for invalid OID strings

### Fixed

- **PDU Encoder Robustness**: Enhanced error handling and type support
  - Fixed missing specific type handlers for `:counter32`, `:gauge32`, `:timeticks`, `:counter64`, `:ip_address`, and `:opaque` in `:auto` encoding
  - Fixed opaque type encoding to use proper ASN.1 opaque tag instead of octet string
  - Enhanced exception value tuple encoding (`:no_such_object`, `:no_such_instance`, `:end_of_mib_view`)
  - Improved catch-all clause to encode unknown types as `:null` instead of raising errors

- **OID Validation**: Enhanced OID string parsing with graceful error handling
  - Updated `Constants.normalize_oid/1` to use `Integer.parse/1` with safe fallback
  - Invalid OID strings now fallback to safe default `[1, 3, 6, 1]` instead of raising exceptions

- **Test Suite Stability**: Resolved all encoding-related test failures
  - Updated tests to reflect new string OID support capabilities
  - Fixed outdated test expectations that assumed errors for now-supported features
  - Achieved zero functional test failures (776 tests passing)

### Changed

- **Error Handling Philosophy**: Shifted from "fail fast" to "graceful degradation"
  - Invalid SNMP values now encode as ASN.1 `:null` instead of raising exceptions
  - String OIDs are parsed and validated with fallback to `:null` for invalid formats
  - Enhanced robustness for production environments

## [1.0.4] - 2025-06-08

### Fixed

- **Transport Module**: Fixed compilation errors and warnings
  - Corrected `close_socket/1` to handle `:gen_udp.close/1` return value properly
  - Removed duplicate private function definitions
  - Consolidated logging to use public `format_endpoint/2` function

- **Walker Module**: Eliminated unreachable code warnings
  - Removed redundant SNMP v1 version checks in bulk walk functions
  - Restored missing `bulk_walk_loop/1` and `bulk_walk_subtree_loop/1` functions
  - Removed unused retry logic functions (`should_retry?/1` and `should_retry_error?/2`)
  - Simplified error handling patterns

- **Dialyzer Configuration**: Set up proper warning suppression
  - Created `.dialyzer_ignore.exs` file for known false positives
  - Configured PLT storage in `priv/plts/` directory
  - Reduced noise from false positive "unused function" warnings

### Changed

- **Code Quality**: Improved overall code maintainability
  - Eliminated all Elixir compiler warnings
  - Cleaned up redundant code paths
  - All 772 tests continue to pass

## [1.0.2] - 2025-06-06

### Added

- **SNMP GETNEXT Support**: Implemented missing `get_next/3` function in `SnmpLib.Manager`
  - Full SNMP v1 compatibility using proper GETNEXT PDU operations
  - SNMP v2c+ efficiency using optimized GETBULK with `max_repetitions=1`
  - Automatic version detection and appropriate protocol selection
  - Consistent API following existing `get/3` and `get_bulk/3` patterns
  - Proper error handling for network errors and SNMP exceptions
  - Returns `{:ok, {next_oid, type, value}}` tuple format as specified
  - Comprehensive test coverage with 10 test cases
  - Enables proper MIB walking operations for all SNMP versions
  - Allows higher-level libraries like `snmp_mgr` to remove version-forcing workarounds

## [1.0.1] - 2025-06-05

### Fixed

- **Critical SNMP Encoding Bug**: Fixed Counter32 and Gauge32 types incorrectly encoding as ASN.1 NULL values
  - Counter32 now properly encodes with ASN.1 application tag 0x41
  - Gauge32 now properly encodes with ASN.1 application tag 0x42
  - Also fixed TimeTicks (0x43) and Counter64 (0x46) atom type encoding
  - SNMP clients will now receive correct Counter32/Gauge32 values instead of NULL
  - Added comprehensive test coverage to prevent regressions

## [0.4.0] - 2025-01-06

### Added

- **100% Pure Native MIB Parsing**: Achieved complete native parsing success across all MIB categories
  - **Working MIBs**: 66/66 (100.0%) 
  - **DOCSIS MIBs**: 28/28 (100.0%)
  - **Previously Broken MIBs**: 11/11 (100.0%)
  - **Total**: 105/105 MIBs (100.0%)

### Fixed

- **Hex Conversion Logic**: Fixed overly aggressive hex atom conversion that was incorrectly converting BITS enumeration identifiers
  - Fixed `d1`, `d2`, etc. being converted to hex integers instead of staying as atoms
  - Now only converts long hex strings (8+ characters) to preserve short identifiers
  - Resolves parsing failures in DISMAN-SCHEDULE-MIB, IANA-ADDRESS-FAMILY-NUMBERS-MIB, IANAifType-MIB, and RFC1213-MIB

### Removed

- **Fallback Parsing**: Completely removed all fallback parsing mechanisms and references
  - No preprocessing of MIB content
  - No fallback parsing with incomplete results
  - Ensures complete data integrity for SNMP managers and simulators
  - All MIBs are now parsed natively or rejected if malformed

## [0.3.0] - 2025-01-06

### Fixed

- **Symbolic OID Resolution**: Fixed symbolic SNMP OID resolution in Manager module
  - Fixed `normalize_oid` function to properly resolve symbolic names like "sysDescr.0" using MIB Registry
  - Symbolic names now resolve to complete OIDs (e.g., "sysDescr.0" → [1, 3, 6, 1, 2, 1, 1, 1, 0]) instead of incomplete fallback [1, 3, 6, 1]
  - Added MIB Registry integration with fallback to numeric string parsing
  - Fixes SNMP simulator rejections due to incomplete OID resolution
  - Maintains backward compatibility for existing numeric OID usage

## [0.2.9] - 2025-01-06

### Fixed

- **Critical Bug Fix**: Fixed SNMP response corruption in Manager module
  - Resolved issue where successful SNMP responses (error_status: 0) were being corrupted to generic errors (error_status: 5)
  - Fixed incorrect pattern matching in `send_and_receive` function that was passing tuple `{data, address, port}` to PDU decoder instead of just `data`
  - Enhanced debug logging throughout SNMP pipeline for better troubleshooting
  - All SNMP operations now correctly preserve error status codes and varbind data

### Enhanced

- **Debug Logging**: Added comprehensive debug logging to Manager module
  - Detailed logging for PDU processing pipeline
  - Transport layer operation logging
  - Result extraction logging for better troubleshooting

## [0.1.0] - 2025-01-06

### Added

- **SnmpLib.PDU** - Complete SNMP PDU encoding/decoding module
  - Support for SNMPv1 and SNMPv2c protocols
  - GET, GETNEXT, GETBULK, SET operations
  - High-performance optimized encoding paths
  - Pure Elixir ASN.1 BER implementation
  - Community string validation
  - Error response generation
  - Backward compatibility with SnmpSim struct format

- **SnmpLib.OID** - Basic OID manipulation utilities (placeholder for Phase 2)
  - String to list conversion
  - List to string conversion

- **Core Features**:
  - `build_get_request/2` - Build GET request PDU
  - `build_get_next_request/2` - Build GETNEXT request PDU
  - `build_set_request/3` - Build SET request PDU
  - `build_get_bulk_request/4` - Build GETBULK request PDU (SNMPv2c only)
  - `build_get_request_multi/2` - Build GET request with multiple varbinds
  - `build_response/4` - Build response PDU
  - `build_message/3` - Build SNMP message structure
  - `encode_message/1` - Encode message to binary format
  - `decode_message/1` - Decode message from binary format
  - `validate_community/2` - Validate community string in packet
  - `create_error_response/3` - Create error response from request
  - `validate/1` - Validate PDU structure

- **Backward Compatibility**:
  - `decode/1` - Legacy decode function for SnmpSim compatibility
  - `encode/1` - Legacy encode function for SnmpSim compatibility
  - `decode_snmp_packet/1` - Alias for decode
  - `encode_snmp_packet/1` - Alias for encode

- **SNMP Data Types Support**:
  - INTEGER, OCTET STRING, NULL, OBJECT IDENTIFIER
  - Counter32, Gauge32, TimeTicks, Counter64
  - IpAddress, Opaque
  - NoSuchObject, NoSuchInstance, EndOfMibView

- **Comprehensive Testing**:
  - 42 test cases covering all functionality
  - Round-trip encoding/decoding tests
  - Edge case and error condition testing
  - Performance and boundary testing
  - Concurrent operation testing

### Technical Details

- **Performance Optimizations**:
  - Fast-path encoding for common integer values (0-127)
  - Efficient iodata usage for binary construction
  - Optimized OID encoding with multi-byte sub-identifier support
  - Minimal memory allocation patterns

- **Error Handling**:
  - Graceful handling of malformed packets
  - Comprehensive parameter validation
  - Clear error messages for debugging

- **Standards Compliance**:
  - Full ASN.1 BER encoding/decoding
  - RFC-compliant SNMP message structure
  - Proper handling of SNMP error codes

### Dependencies

- ExDoc 0.29+ (dev only)
- Dialyxir 1.3+ (dev only) 
- Credo 1.7+ (dev/test only)
- ExCoveralls 0.18+ (test only)
- Benchee 1.1+ (dev only)

### Known Issues

- One test failure in complex OID encoding with large values (>127) - to be addressed in Phase 2
- Unused module attributes for error codes (will be used in Phase 2)

## Phase Roadmap

### Phase 1 (Current) - PDU Library 
- Complete PDU encoding/decoding functionality
- Backward compatibility with existing projects
- Comprehensive testing

### Phase 2 (Next) - OID and Transport
- Full OID manipulation library
- UDP transport layer
- SNMP data types library
- ASN.1 improvements

### Phase 3 (Future) - Advanced Features
- SNMP table operations
- Tree walking functionality
- Error handling library
- Utilities including pretty printing