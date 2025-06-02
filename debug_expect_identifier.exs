# Debug expect_identifier function
defmodule DebugExpectIdentifier do
  # Import the private function for testing
  import SnmpLib.MIB.Parser, only: []
  
  # Test expect_identifier behavior
  def test_expect_identifier do
    # First test - regular identifier
    token1 = {:identifier, "test", %{line: 1, column: 1}}
    context = %{errors: []}
    
    IO.puts "Testing regular identifier:"
    result1 = call_expect_identifier([token1], context)
    IO.puts "Result: #{inspect(result1)}"
    
    # Second test - display_string keyword
    token2 = {:keyword, :display_string, %{line: 1, column: 1}}
    
    IO.puts "\nTesting :display_string keyword:"
    result2 = call_expect_identifier([token2], context)
    IO.puts "Result: #{inspect(result2)}"
    
    # Third test - random keyword that should fail
    token3 = {:keyword, :syntax, %{line: 1, column: 1}}
    
    IO.puts "\nTesting :syntax keyword (should fail):"
    result3 = call_expect_identifier([token3], context)
    IO.puts "Result: #{inspect(result3)}"
  end
  
  # Helper to call the private function
  defp call_expect_identifier(tokens, context) do
    # We can't call private functions directly, so let's use a simple MIB that will trigger expect_identifier
    simple_mib = """
      TEST-MIB DEFINITIONS ::= BEGIN
      DisplayString TEXTUAL-CONVENTION
        STATUS current
        DESCRIPTION "Test"
        SYNTAX OCTET STRING
      END
    """
    
    case SnmpLib.MIB.Lexer.tokenize(simple_mib) do
      {:ok, tokens} ->
        # Find the DisplayString token and test the parsing
        IO.puts "Tokens: #{inspect(tokens)}"
        case SnmpLib.MIB.Parser.parse_tokens(tokens) do
          {:ok, mib} ->
            {:ok, "Parsing succeeded"}
          {:error, errors} ->
            {:error, "Parsing failed: #{inspect(errors)}"}
          {:warning, mib, warnings} ->
            {:warning, "Parsing with warnings: #{inspect(warnings)}"}
        end
      {:error, error} ->
        {:error, "Tokenization failed: #{inspect(error)}"}
    end
  end
end

DebugExpectIdentifier.test_expect_identifier()