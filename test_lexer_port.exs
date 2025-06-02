# Test the ported lexer on a DOCSIS MIB
Code.require_file("lib/snmp_lib/mib/lexer.ex")

{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")

# Take just first 500 characters to test
sample = String.slice(content, 0, 500)

IO.puts("Testing on DOCS-CABLE-DEVICE-MIB sample:")
IO.puts(sample)
IO.puts("\n" <> String.duplicate("=", 50))

case SnmpLib.MIB.Lexer.tokenize(sample) do
  {:ok, tokens} ->
    IO.puts("✅ Tokenization successful! #{length(tokens)} tokens")
    Enum.take(tokens, 20) |> Enum.each(fn token -> IO.inspect(token) end)
  {:error, reason} ->
    IO.puts("❌ Tokenization failed: #{reason}")
end