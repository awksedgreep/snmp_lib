# Debug enumeration tokenization issue
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Lexer}

# Test the specific enumeration that's causing issues
test_content = """
TEST-MIB DEFINITIONS ::= BEGIN

docsDevRole OBJECT-TYPE
        SYNTAX INTEGER {
            cm(1),
            cmtsActive(2),
            cmtsBackup(3)
        }
        MAX-ACCESS  read-only
        STATUS      current
        DESCRIPTION "Test"
        ::= { test 1 }

END
"""

IO.puts "Testing enumeration tokenization..."

case Lexer.tokenize(test_content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    # Find and show the enumeration tokens
    IO.puts "\nTokens around the enumeration:"
    enum_start = Enum.find_index(tokens, fn 
      {:symbol, :open_brace, _} -> true
      _ -> false
    end)
    
    if enum_start do
      # Show tokens around the enumeration
      relevant_tokens = Enum.slice(tokens, enum_start, 15)
      Enum.with_index(relevant_tokens, enum_start) |> Enum.each(fn {{type, value, pos}, idx} ->
        line_info = if Map.has_key?(pos || %{}, :line), do: " (line #{pos.line})", else: ""
        IO.puts "   #{idx}: #{type} = #{inspect(value)}#{line_info}"
      end)
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    error_msg = SnmpLib.MIB.Error.format(error)
    IO.puts "   Error: #{error_msg}"
end