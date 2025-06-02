
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

# Get the specific tokens that will be used for the first MODULE-IDENTITY
first_def_tokens = tokens
  |> Enum.drop_while(fn token -> token \!= {:identifier, "docsDev", 0} end)
  |> Enum.drop(1)  # Skip the identifier itself
  |> Enum.take(20)  # Take first 20 tokens after docsDev

IO.puts("First definition tokens:")
Enum.with_index(first_def_tokens) |> Enum.each(fn {token, idx} ->
  IO.puts("#{idx}: #{inspect(token)}")
end)

IO.puts("
=== DIRECT PARSING TEST ===")

# Try parsing the MODULE-IDENTITY directly
try do
  # Mock parse_module_identity by calling each clause parser directly
  test_tokens = first_def_tokens
  
  IO.puts("Testing parse_last_updated_clause...")
  case test_tokens do
    [{:keyword, :last_updated, _}, {:string, value, _} | rest] ->
      IO.puts("LAST-UPDATED parsed successfully: #{inspect(value)}")
      IO.puts("Remaining tokens: #{length(rest)}")
      IO.puts("Next 5 tokens: #{inspect(Enum.take(rest, 5))}")
    other ->
      IO.puts("Failed to match LAST-UPDATED pattern")
      IO.puts("Got: #{inspect(Enum.take(other, 3))}")
  end
  
rescue
  e ->
    IO.puts("Exception: #{inspect(e)}")
    IO.puts(Exception.format_stacktrace(__STACKTRACE__))
end

