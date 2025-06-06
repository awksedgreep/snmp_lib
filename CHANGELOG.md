# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.2] - 2025-06-06

### Added

- **SNMP GETNEXT Support**: Implemented missing `get_next/3` function in `SnmpLib.Manager`
  - Full SNMP v1 compatibility using proper GETNEXT PDU operations
  - SNMP v2c+ efficiency using optimized GETBULK with `max_repetitions=1`
  - Automatic version detection and appropriate protocol selection
  - Consistent API following existing `get/3` and `get_bulk/3` patterns
  - Proper error handling for network errors and SNMP exceptions
  - Returns `{:ok, {next_oid, value}}` tuple format as specified
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