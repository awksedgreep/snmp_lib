# Debug TruthValue parsing specifically
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Test TruthValue specifically
test_content = """
TEST-MIB DEFINITIONS ::= BEGIN

docsDevResetNow OBJECT-TYPE
        SYNTAX      TruthValue
        MAX-ACCESS  read-write
        STATUS      current
        DESCRIPTION
            "Setting this object to true(1) causes the device to
             reset.  Reading this object always returns false(2)."
        ::= { test 1 }

END
"""

IO.puts "Testing TruthValue syntax parsing..."

case Lexer.tokenize(test_content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    # Find the TruthValue token
    truth_value_index = Enum.find_index(tokens, fn 
      {:keyword, :truth_value, _} -> true
      {:identifier, "TruthValue", _} -> true
      _ -> false
    end)
    
    if truth_value_index do
      IO.puts "\nTokens around TruthValue:"
      relevant_tokens = Enum.slice(tokens, max(0, truth_value_index - 5), 11)
      Enum.with_index(relevant_tokens, max(0, truth_value_index - 5)) |> Enum.each(fn {{type, value, pos}, idx} ->
        line_info = if Map.has_key?(pos || %{}, :line), do: " (line #{pos.line})", else: ""
        marker = if idx == truth_value_index, do: " <<<< TruthValue", else: ""
        IO.puts "   #{idx}: #{type} = #{inspect(value)}#{line_info}#{marker}"
      end)
    else
      IO.puts "❌ TruthValue token not found!"
    end
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Parsing successful!"
        IO.puts "   MIB: #{mib.name}"
        IO.puts "   Definitions: #{length(mib.definitions)}"
        
        object_type = List.first(mib.definitions)
        IO.puts "   Object type: #{object_type.name}"
        IO.puts "   Syntax: #{inspect(object_type.syntax)}"
        
      {:warning, mib, warnings} ->
        IO.puts "⚠️  Parsing with warnings"
        IO.puts "   Warnings: #{length(warnings)}"
        first_warning = List.first(warnings)
        IO.puts "   First warning: #{SnmpLib.MIB.Error.format(first_warning)}"
        
      {:error, errors} ->
        IO.puts "❌ Parsing failed: #{length(errors)} errors"
        first_error = List.first(errors)
        error_msg = SnmpLib.MIB.Error.format(first_error)
        IO.puts "   Error: #{error_msg}"
        
        if first_error.line do
          IO.puts "   Error line: #{first_error.line}"
        end
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    error_msg = SnmpLib.MIB.Error.format(error)
    IO.puts "   Error: #{error_msg}"
end

# Also test the exact context from the failing MIB
IO.puts "\n" <> String.duplicate("=", 50)
IO.puts "Testing the exact context around the failure point..."

# Get the exact content around line 248-255
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
lines = String.split(content, "\n")

# Create a test with just the problematic section plus some context
test_context = """
DOCS-CABLE-DEVICE-MIB DEFINITIONS ::= BEGIN

docsDevDateTime OBJECT-TYPE
        SYNTAX      DateAndTime
        MAX-ACCESS  read-write
        STATUS      current
        DESCRIPTION
            "The current date and time.
             For example: Tuesday May 26, 1992 at 1:30:15 PM EDT would be
             displayed as: 1992-5-26,13:30:15.0,-4:0"
        ::= { docsDevBase 2 }

docsDevResetNow OBJECT-TYPE
        SYNTAX      TruthValue
        MAX-ACCESS  read-write
        STATUS      current
        DESCRIPTION
            "Setting this object to true(1) causes the device to
             reset.  Reading this object always returns false(2)."
        ::= { docsDevBase 3 }

END
"""

case Lexer.tokenize(test_context) do
  {:ok, tokens} ->
    IO.puts "✅ Context tokenization successful: #{length(tokens)} tokens"
    
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Context parsing successful! #{length(mib.definitions)} definitions"
        
      {:error, errors} ->
        IO.puts "❌ Context parsing failed: #{length(errors)} errors"
        first_error = List.first(errors)
        IO.puts "   Error: #{first_error.type} - #{first_error.message}"
        if first_error.line do
          IO.puts "   Error line: #{first_error.line}"
        end
    end
    
  {:error, error} ->
    IO.puts "❌ Context tokenization failed"
    IO.puts "   Error: #{inspect(error)}"
end