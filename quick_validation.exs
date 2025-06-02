# Quick validation test
alias SnmpLib.MIB.{Parser, Lexer}

# Test a comprehensive real-world MIB pattern
mib_content = """
EXAMPLE-MIB DEFINITIONS ::= BEGIN

IMPORTS
    MODULE-IDENTITY, OBJECT-TYPE, NOTIFICATION-TYPE,
    Counter32, Gauge32, TimeTicks FROM SNMPv2-SMI
    DisplayString, RowStatus FROM SNMPv2-TC;

exampleMIB MODULE-IDENTITY
    LAST-UPDATED "202401150000Z"
    ORGANIZATION "Example Corp"
    CONTACT-INFO "support@example.com"
    DESCRIPTION "Example enterprise MIB"
    ::= { enterprises 99999 }
    
sysUpTime OBJECT-TYPE
    SYNTAX TimeTicks
    MAX-ACCESS read-only
    STATUS current
    DESCRIPTION "System uptime"
    ::= { system 3 }

ifEntry OBJECT-TYPE
    SYNTAX IfEntry
    MAX-ACCESS not-accessible
    STATUS current
    DESCRIPTION "Interface entry"
    INDEX { ifIndex }
    ::= { ifTable 1 }

linkDown NOTIFICATION-TYPE
    OBJECTS { ifIndex, ifAdminStatus }
    STATUS current
    DESCRIPTION "Link down notification"
    ::= { snmpTraps 3 }

systemGroup OBJECT-GROUP
    OBJECTS { sysDescr, sysUpTime }
    STATUS current
    DESCRIPTION "System objects group"
    ::= { groups 1 }

END
"""

IO.puts "🔍 Testing Real-World MIB Pattern..."

case Lexer.tokenize(mib_content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization: #{length(tokens)} tokens"
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Parsing: #{length(mib.definitions)} definitions"
        IO.puts "  📋 Module: #{mib.name}"
        IO.puts "  📋 Imports: #{length(mib.imports)} groups"
        
        # Count definition types
        type_counts = mib.definitions
        |> Enum.group_by(& &1.__type__)
        |> Enum.map(fn {type, list} -> {type, length(list)} end)
        
        IO.puts "  📋 Definition types:"
        Enum.each(type_counts, fn {type, count} ->
          IO.puts "     #{type}: #{count}"
        end)
        
        IO.puts "\n🎉 REAL-WORLD VALIDATION SUCCESSFUL!"
        IO.puts "Parser successfully handles complex production MIB patterns."
        
      {:warning, mib, warnings} ->
        IO.puts "⚠️  Parsing: #{length(mib.definitions)} definitions with #{length(warnings)} warnings"
        IO.puts "🎉 VALIDATION SUCCESSFUL (with warnings)"
        
      {:error, errors} ->
        IO.puts "❌ Parsing failed: #{length(errors)} errors"
        Enum.take(errors, 3) |> Enum.each(fn error ->
          IO.puts "   #{SnmpLib.MIB.Error.format(error)}"
        end)
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed: #{SnmpLib.MIB.Error.format(error)}"
end