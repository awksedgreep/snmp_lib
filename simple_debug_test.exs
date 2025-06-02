
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

# Find docsDev token position
docs_dev_position = tokens
  |> Enum.with_index()
  |> Enum.find(fn {{type, value, _line}, _idx} -> type == :identifier and value == "docsDev" end)
  |> elem(1)

IO.puts("docsDev found at position: #{docs_dev_position}")

# Get tokens around that position
module_identity_tokens = tokens
  |> Enum.slice(docs_dev_position, 15)

IO.puts("Module Identity section tokens:")
Enum.with_index(module_identity_tokens) |> Enum.each(fn {token, idx} ->
  IO.puts("#{idx}: #{inspect(token)}")
end)

# The issue might be with an incomplete error creation somewhere
# Let me check if there are any unusual patterns in the error creation
IO.puts("
=== CHECKING ERROR CREATION ===")
IO.puts("The error message was: Expected , but found")
IO.puts("This suggests expected=comma, actual=empty_string")
IO.puts("This typically happens when expect_symbol is called with :comma but gets something else")

