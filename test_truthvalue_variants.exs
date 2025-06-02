# Test different variants and capitalizations of TruthValue
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Test different variants that might cause issues
test_variants = [
  {"Standard TruthValue", "TruthValue"},
  {"Lowercase truthvalue", "truthvalue"},
  {"All caps TRUTHVALUE", "TRUTHVALUE"},
  {"Mixed case truthValue", "truthValue"},
  {"Spaced Truth Value", "Truth Value"},
  {"Hyphenated Truth-Value", "Truth-Value"}
]

Enum.each(test_variants, fn {description, variant} ->
  test_mib = """
  TEST-MIB DEFINITIONS ::= BEGIN
  testObj OBJECT-TYPE
      SYNTAX      #{variant}
      MAX-ACCESS  read-write
      STATUS      current
      DESCRIPTION "Test with #{variant}"
      ::= { iso 1 }
  END
  """
  
  IO.puts "Testing #{description} (#{variant}):"
  IO.puts String.duplicate("=", 50)
  
  case Lexer.tokenize(test_mib) do
    {:ok, tokens} ->
      # Find tokens related to our variant
      variant_tokens = Enum.filter(tokens, fn
        {:keyword, keyword, _} -> 
          keyword_str = Atom.to_string(keyword)
          String.contains?(String.downcase(keyword_str), "truth")
        {:identifier, id, _} -> 
          String.contains?(String.downcase(id), "truth")
        _ -> false
      end)
      
      IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
      IO.puts "   Variant tokens found: #{length(variant_tokens)}"
      
      Enum.each(variant_tokens, fn token ->
        IO.puts "   Token: #{inspect(token)}"
      end)
      
      # If no variant tokens found, show what the SYNTAX token was
      if length(variant_tokens) == 0 do
        syntax_area_tokens = tokens
        |> Enum.with_index()
        |> Enum.find_value(fn {{type, value, _}, idx} ->
          if type == :keyword and value == :syntax do
            # Get next few tokens after SYNTAX
            tokens
            |> Enum.drop(idx + 1)
            |> Enum.take(3)
          else
            nil
          end
        end)
        
        if syntax_area_tokens do
          IO.puts "   Tokens after SYNTAX: #{inspect(syntax_area_tokens)}"
        end
      end
      
      case Parser.parse_tokens(tokens) do
        {:ok, mib} ->
          IO.puts "✅ Parsing successful!"
          
        {:warning, mib, warnings} ->
          IO.puts "⚠️  Parsing with warnings: #{length(warnings)}"
          
        {:error, errors} ->
          IO.puts "❌ Parsing failed: #{length(errors)} errors"
          first_error = List.first(errors)
          IO.puts "   First error: #{inspect(first_error)}"
      end
      
    {:error, error} ->
      IO.puts "❌ Tokenization failed"
      IO.puts "   Error: #{inspect(error)}"
  end
  
  IO.puts ""
end)