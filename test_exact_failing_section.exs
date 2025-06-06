#!/usr/bin/env elixir

# Test the exact section that's failing

# First test: simple enumeration that should work
simple_test = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    TEXTUAL-CONVENTION  FROM SNMPv2-TC;

TestType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test"
    SYNTAX      INTEGER {
                    other(1),
                    regular1822(2),
                    hdh1822(3)
                }

END
"""

# Second test: longer enumeration like IANAifType
longer_test = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    TEXTUAL-CONVENTION  FROM SNMPv2-TC;

TestType ::= TEXTUAL-CONVENTION
    STATUS      current
    DESCRIPTION "Test"
    SYNTAX      INTEGER {
                    other(1),          -- none of the following
                    regular1822(2),
                    hdh1822(3),
                    ddnX25(4),
                    rfc877x25(5),
                    ethernetCsmacd(6), -- for all ethernet-like interfaces,
                                       -- regardless of speed, as per RFC3635
                    iso88023Csmacd(7), -- Deprecated via RFC3635
                                       -- ethernetCsmacd (6) should be used instead
                    iso88024TokenBus(8),
                    iso88025TokenRing(9),
                    iso88026Man(10),
                    starLan(11), -- Deprecated via RFC3635
                                 -- ethernetCsmacd (6) should be used instead
                    proteon10Mbit(12),
                    proteon80Mbit(13),
                    hyperchannel(14),
                    fddi(15),
                    lapb(16),
                    sdlc(17),
                    ds1(18),            -- DS1-MIB
                    e1(19)              -- Obsolete see DS1-MIB
                }

END
"""

IO.puts("Testing simple enumeration:")
case SnmpLib.MIB.Parser.parse(simple_test) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end

IO.puts("\nTesting longer enumeration (like IANAifType):")
case SnmpLib.MIB.Parser.parse(longer_test) do
  {:ok, _} -> IO.puts("✓ SUCCESS")
  {:error, e} -> IO.puts("✗ FAILED: #{inspect(e)}")
end