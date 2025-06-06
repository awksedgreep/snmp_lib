# Individual MIB File Error Analysis Report

This report provides detailed error information for the 5 MIB files that are failing to parse correctly.

## Error Summary

| File | Line | Error | Issue Type |
|------|------|-------|------------|
| DISMAN-SCHEDULE-MIB.mib | 296 | syntax error before: 209 | BITS enumeration |
| IANA-ADDRESS-FAMILY-NUMBERS-MIB.mib | 130 | syntax error before: 57699 | Enumeration value |
| IANAifType-MIB.mib | 329 | syntax error before: 225 | Enumeration value |
| RFC1155-SMI.mib | 103 | syntax error before: 'Counter' | Type definition |
| RFC1213-MIB.mib | 302 | syntax error before: 225 | Enumeration value |

## Detailed Analysis

### 1. DISMAN-SCHEDULE-MIB.mib (Line 296)
```asn1
schedDay OBJECT-TYPE
    SYNTAX      BITS {
                    d1(0),   d2(1),   d3(2),   d4(3),   d5(4),  <-- ERROR HERE
                    d6(5),   d7(6),   d8(7),   d9(8),   d10(9),
```
**Issue**: Parser fails on BITS type enumeration syntax. The error "209" might be an internal token number.

### 2. IANA-ADDRESS-FAMILY-NUMBERS-MIB.mib (Line 130)
```asn1
                  hdlc(4),
                  bbn1822(5),
                  all802(6),
                  e163(7),  <-- ERROR HERE
```
**Issue**: Parser fails on enumeration value. The error "57699" suggests a large internal token number.

### 3. IANAifType-MIB.mib (Line 329)
```asn1
                   lapb(16),
                   sdlc(17),
                   ds1(18),            -- DS1-MIB
                   e1(19),             -- Obsolete see DS1-MIB  <-- ERROR HERE
```
**Issue**: Similar enumeration parsing issue with comments on the same line.

### 4. RFC1155-SMI.mib (Line 103)
```asn1
       Counter ::=  <-- ERROR HERE
           [APPLICATION 1]
               IMPLICIT INTEGER (0..4294967295)
```
**Issue**: Parser doesn't recognize "Counter" as a valid type name in type definitions.

### 5. RFC1213-MIB.mib (Line 302)
```asn1
                lapb(16),
                sdlc(17),
                ds1(18),           -- T-1
                e1(19),            -- european equiv. of T-1  <-- ERROR HERE
```
**Issue**: Same enumeration parsing issue as others.

## Root Cause Analysis

The errors fall into two main categories:

### 1. Enumeration Parsing Issues (4 files)
- Lines with enumeration values like `e163(7)`, `e1(19)` are failing
- The parser seems to have trouble with certain identifier patterns in enumerations
- Comments on the same line might be contributing to the issue

### 2. Type Definition Issues (1 file)
- `Counter ::=` type definition not recognized
- This is a fundamental ASN.1 type that should be supported

## Technical Issues

All errors come from the `mib_grammar_elixir` parser with "syntax error before: X" messages, indicating:

1. **Lexer/Tokenizer Issues**: The tokenizer may not be properly handling certain identifier patterns
2. **Grammar Issues**: The grammar rules may not cover all ASN.1 constructs properly
3. **Token Recognition**: Numeric tokens (209, 57699, 225) suggest internal parser state issues

## Recommended Fixes

1. **Check Grammar Rules**: Review `/src/mib_grammar_elixir.yrl` for:
   - BITS type syntax support
   - Enumeration value parsing
   - Type definition syntax (`Counter ::=`)

2. **Check Lexer**: Review tokenizer for:
   - Identifier pattern recognition
   - Comment handling in enumeration contexts
   - Numeric literal parsing

3. **Specific Issues to Address**:
   - Support for `BITS { identifier(number), ... }` syntax
   - Support for type definitions like `Counter ::=`
   - Better handling of comments in enumeration contexts
   - Proper parsing of identifiers that might conflict with keywords

4. **Testing Strategy**:
   - Create minimal test cases for each failing construct
   - Test BITS syntax specifically
   - Test type definitions with ::= operator
   - Test enumeration parsing with comments

This individual analysis provides much clearer error attribution than the batch test and shows specific ASN.1 constructs that need attention in the parser.