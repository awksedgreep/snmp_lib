
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

# Examine tokens to find potential issues
IO.puts("=== EXAMINING TOKENS FOR PARSING ISSUES ===")

# Look for any tokens that might cause parsing problems
problematic_tokens = tokens
  |> Enum.with_index()
  |> Enum.filter(fn {{type, value, line}, _idx} ->
    case {type, value} do
      # Look for empty strings or nil values
      {_type, ""} -> true
      {_type, nil} -> true
      # Look for unexpected token types
      {:error, _} -> true
      _ -> false
    end
  end)

if length(problematic_tokens) > 0 do
  IO.puts("Found problematic tokens:")
  Enum.each(problematic_tokens, fn {{type, value, line}, idx} ->
    IO.puts("  Index #{idx}: {:#{type}, #{inspect(value)}, #{line}}")
  end)
else
  IO.puts("No obviously problematic tokens found")
end

# Try to parse and catch the exact error
try do
  result = SnmpLib.MIB.Parser.parse_tokens(tokens)
  IO.puts("Parse result: #{inspect(result)}")
catch
  error_type, error ->
    IO.puts("Caught #{error_type}: #{inspect(error)}")
    IO.puts("Stacktrace:")
    IO.puts(Exception.format_stacktrace(__STACKTRACE__))
rescue
  e ->
    IO.puts("Rescued exception: #{inspect(e)}")
    IO.puts("Stacktrace:")
    IO.puts(Exception.format_stacktrace(__STACKTRACE__))
end

