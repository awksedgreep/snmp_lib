# SnmpLib.PDU Module Refactoring Plan

## Overview

The current `SnmpLib.PDU` module is 1,310 lines and contains multiple responsibilities. This plan outlines how to split it into smaller, more focused modules while maintaining backward compatibility and improving maintainability.

## Current Module Analysis

**Total Lines**: 1,310
**Main Responsibilities**:
- Constants and type definitions
- Public API for building PDUs and messages
- Encoding logic (ASN.1 BER)
- Decoding logic (ASN.1 BER parsing)
- Validation functions
- Utility functions

## Proposed Module Structure

### 1. SnmpLib.PDU.Constants (150-200 lines)
**Purpose**: All constants, type definitions, and simple utility functions

**Functions to Move**:
- All `@` module attributes (constants)
- Type definitions (`@type` declarations)
- Error status accessors:
  - `no_error/0`
  - `too_big/0`
  - `no_such_name/0`
  - `bad_value/0`
  - `read_only/0`
  - `gen_err/0`
- Utility functions:
  - `normalize_version/1` (private)
  - `normalize_oid/1` (private)

**New Functions to Add**:
- `pdu_type_to_tag/1` - Convert PDU type atoms to ASN.1 tags
- `tag_to_pdu_type/1` - Convert ASN.1 tags to PDU type atoms
- `data_type_to_tag/1` - Convert data type atoms to ASN.1 tags
- `tag_to_data_type/1` - Convert ASN.1 tags to data type atoms

### 2. SnmpLib.PDU.Builder (300-400 lines)
**Purpose**: High-level PDU and message building functions

**Functions to Move**:
- `build_get_request/2`
- `build_get_next_request/2`
- `build_set_request/3`
- `build_get_bulk_request/4`
- `build_get_request_multi/2` (all clauses)
- `build_response/4`
- `build_message/3`
- `create_error_response/3`

**Private Functions to Move**:
- `validate_request_id!/1`
- `validate_bulk_params!/2`
- `validate_community!/1`
- `validate_bulk_version!/2`
- `validate_varbinds_format/1`

### 3. SnmpLib.PDU.Encoder (400-500 lines)
**Purpose**: All encoding logic for converting Elixir data structures to binary ASN.1 BER

**Functions to Move**:
- `encode_message/1`
- `encode/1`
- `encode_snmp_packet/1` (alias)

**Private Functions to Move**:
- `encode_snmp_message_fast/3`
- `encode_pdu_fast/1`
- `encode_standard_pdu_fast/2`
- `encode_bulk_pdu_fast/1`
- `encode_varbinds_fast/1`
- `encode_varbind_fast/1`
- `encode_snmp_value_fast/2` (all clauses)
- `encode_sequence_fast/1`
- `encode_length_fast/1`
- `encode_integer_fast/1`
- `encode_octet_string_fast/1`
- `encode_null_fast/0`
- `encode_oid_fast/1`
- `encode_unsigned_integer/2`
- `encode_counter64/2`
- `integer_to_bytes/1`
- `encode_oid_subids_fast/2`
- `encode_subid_multibyte/2`

### 4. SnmpLib.PDU.Decoder (400-500 lines)
**Purpose**: All decoding logic for parsing binary ASN.1 BER to Elixir data structures

**Functions to Move**:
- `decode_message/1`
- `decode/1`
- `decode_snmp_packet/1` (alias)

**Private Functions to Move**:
- `parse_snmp_message/1`
- `parse_pdu_comprehensive/1`
- `parse_sequence/1`
- `parse_varbinds/1`
- `parse_varbind/1`
- `parse_value_with_type/1` (all clauses)
- `parse_integer/1`
- `parse_octet_string/1`
- `parse_null/1`
- `parse_oid/1`
- `parse_counter32/1`
- `parse_gauge32/1`
- `parse_timeticks/1`
- `parse_counter64/1`
- `parse_ip_address/1`
- `parse_opaque/1`
- `parse_exception_value/1`
- `decode_integer_value/1`
- `decode_oid_subids/2`
- `decode_subid_multibyte/2`

### 5. SnmpLib.PDU (Main Module) (200-300 lines)
**Purpose**: Public API facade and high-level operations

**Functions to Keep**:
- `validate/1`
- `validate_community/2`

**Private Functions to Keep**:
- `validate_pdu_type_only/1`

**New Functions to Add**:
- Delegation functions that call the appropriate sub-modules
- Any backward compatibility shims if needed

## Implementation Strategy

### Phase 1: Create New Modules
1. Create `SnmpLib.PDU.Constants` with all constants and types
2. Create `SnmpLib.PDU.Builder` with PDU building functions
3. Create `SnmpLib.PDU.Encoder` with encoding logic
4. Create `SnmpLib.PDU.Decoder` with decoding logic

### Phase 2: Update Main Module
1. Update `SnmpLib.PDU` to import/alias the new modules
2. Add delegation functions for backward compatibility
3. Remove moved functions from the main module

### Phase 3: Update Dependencies
1. Update any internal modules that directly call private functions
2. Update tests to use the new module structure where appropriate
3. Update documentation

### Phase 4: Testing and Validation
1. Run full test suite to ensure no regressions
2. Performance testing to ensure no significant slowdowns
3. Update any benchmarks or performance tests

## Module Dependencies

```
SnmpLib.PDU (main)
├── SnmpLib.PDU.Constants
├── SnmpLib.PDU.Builder
│   └── depends on Constants
├── SnmpLib.PDU.Encoder
│   └── depends on Constants
└── SnmpLib.PDU.Decoder
    └── depends on Constants
```

## Backward Compatibility

All existing public functions will remain available in `SnmpLib.PDU` through delegation:

```elixir
# In SnmpLib.PDU
defdelegate build_get_request(oid_list, request_id), to: SnmpLib.PDU.Builder
defdelegate encode_message(message), to: SnmpLib.PDU.Encoder
defdelegate decode_message(binary), to: SnmpLib.PDU.Decoder
```

## Benefits

1. **Maintainability**: Smaller, focused modules are easier to understand and modify
2. **Testing**: Each module can have focused test suites
3. **Performance**: Potential for better compilation and hot code loading
4. **Collaboration**: Multiple developers can work on different modules simultaneously
5. **Documentation**: Each module can have focused documentation
6. **Reusability**: Individual components can be used independently if needed

## File Structure After Split

```
lib/snmp_lib/
├── pdu.ex                    # Main module (~250 lines)
└── pdu/
    ├── constants.ex          # Constants and types (~180 lines)
    ├── builder.ex            # PDU building (~350 lines)
    ├── encoder.ex            # Encoding logic (~450 lines)
    └── decoder.ex            # Decoding logic (~450 lines)
```

## Detailed Function Mapping

### Constants Module Functions
```elixir
# Public constants accessors
no_error/0, too_big/0, no_such_name/0, bad_value/0, read_only/0, gen_err/0

# Type conversion utilities
pdu_type_to_tag/1, tag_to_pdu_type/1
data_type_to_tag/1, tag_to_data_type/1

# Normalization utilities  
normalize_version/1, normalize_oid/1
```

### Builder Module Functions
```elixir
# Public PDU builders
build_get_request/2, build_get_next_request/2, build_set_request/3
build_get_bulk_request/4, build_get_request_multi/2, build_response/4
build_message/3, create_error_response/3

# Private validation helpers
validate_request_id!/1, validate_bulk_params!/2, validate_community!/1
validate_bulk_version!/2, validate_varbinds_format/1
```

### Encoder Module Functions
```elixir
# Public encoding functions
encode_message/1, encode/1, encode_snmp_packet/1

# Private encoding implementation
encode_snmp_message_fast/3, encode_pdu_fast/1, encode_standard_pdu_fast/2
encode_bulk_pdu_fast/1, encode_varbinds_fast/1, encode_varbind_fast/1
encode_snmp_value_fast/2, encode_sequence_fast/1, encode_length_fast/1
encode_integer_fast/1, encode_octet_string_fast/1, encode_null_fast/0
encode_oid_fast/1, encode_unsigned_integer/2, encode_counter64/2
integer_to_bytes/1, encode_oid_subids_fast/2, encode_subid_multibyte/2
```

### Decoder Module Functions
```elixir
# Public decoding functions
decode_message/1, decode/1, decode_snmp_packet/1

# Private decoding implementation
parse_snmp_message/1, parse_pdu_comprehensive/1, parse_sequence/1
parse_varbinds/1, parse_varbind/1, parse_value_with_type/1
parse_integer/1, parse_octet_string/1, parse_null/1, parse_oid/1
parse_counter32/1, parse_gauge32/1, parse_timeticks/1, parse_counter64/1
parse_ip_address/1, parse_opaque/1, parse_exception_value/1
decode_integer_value/1, decode_oid_subids/2, decode_subid_multibyte/2
```

## Notes for Implementation

1. **Import Strategy**: Use `import` for frequently used functions and `alias` for module references
2. **Error Handling**: Ensure all error tuples and exceptions are preserved exactly
3. **Performance**: Monitor compilation times and runtime performance during split
4. **Documentation**: Each new module should have comprehensive `@moduledoc` and `@doc` strings
5. **Testing**: Create focused test files for each new module while maintaining integration tests

This refactoring will significantly improve the maintainability and organization of the SNMP PDU handling code while preserving all existing functionality and performance characteristics.
