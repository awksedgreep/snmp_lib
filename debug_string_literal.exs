# Debug string literal parsing issue
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Lexer}

# Test the specific problematic string from DOCS-CABLE-DEVICE-MIB
test_content = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    DESCRIPTION
        "This is a long description that spans
         multiple lines and might contain
         special characters or quotes like
         this text about docsDevMaxCpe"
    ::= { 1 2 3 }

END
"""

IO.puts "Testing multi-line string literal..."

case Lexer.tokenize(test_content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    # Find the DESCRIPTION token and its string value
    description_found = Enum.find_index(tokens, fn 
      {:keyword, :description, _} -> true
      _ -> false
    end)
    
    if description_found do
      string_token = Enum.at(tokens, description_found + 1)
      case string_token do
        {:string, value, _} ->
          IO.puts "   Description string: #{String.slice(value, 0, 100)}..."
        _ ->
          IO.puts "   Next token after DESCRIPTION: #{inspect(string_token)}"
      end
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    error_msg = SnmpLib.MIB.Error.format(error)
    IO.puts "   Error: #{error_msg}"
end