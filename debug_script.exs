
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
IO.puts("File read successfully, content length: #{String.length(content)}")
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)
IO.puts("Tokenization successful, token count: #{length(tokens)}")
result = SnmpLib.MIB.Parser.parse_tokens(tokens)
IO.puts("Parse result: #{inspect(result)}")

