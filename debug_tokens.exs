# Debug script to see tokens around the failure point
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

# Find the token that's causing the issue
target_string = "200612200000Z"
failure_index = Enum.find_index(tokens, fn 
  {:string, ^target_string, _} -> true
  _ -> false
end)

if failure_index do
  IO.puts("Found target string at index #{failure_index}")
  IO.puts("Context tokens (±10):")
  
  start_idx = max(0, failure_index - 10)
  end_idx = min(length(tokens) - 1, failure_index + 10)
  
  tokens
  |> Enum.slice(start_idx..end_idx) 
  |> Enum.with_index(start_idx)
  |> Enum.each(fn {token, idx} ->
    marker = if idx == failure_index, do: " <-- FAILURE", else: ""
    IO.puts("#{idx}: #{inspect(token)}#{marker}")
  end)
end