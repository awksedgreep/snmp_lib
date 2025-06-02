
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
IO.puts("File read successfully, content length: #{String.length(content)}")

# Get the first few lines to see what the file looks like
lines = String.split(content, "
")
IO.puts("First 10 lines of the file:")
Enum.take(lines, 10) |> Enum.with_index(1) |> Enum.each(fn {line, num} ->
  IO.puts("#{num}: #{line}")
end)

{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
IO.puts("Tokenization successful, token count: #{length(tokens)}")

# Show first few tokens
IO.puts("First 20 tokens:")
Enum.take(tokens, 20) |> Enum.with_index(1) |> Enum.each(fn {token, idx} ->
  IO.puts("#{idx}: #{inspect(token)}")
end)

result = SnmpLib.MIB.Parser.parse_tokens(tokens)
case result do
  {:error, errors} ->
    IO.puts("Parse errors:")
    Enum.each(errors, fn error ->
      IO.puts("  - #{inspect(error)}")
    end)
  {:ok, parsed} ->
    IO.puts("Parse successful: #{inspect(parsed)}")
end

