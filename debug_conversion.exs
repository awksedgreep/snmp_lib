# Debug the token conversion process
content = "TEST-MIB DEFINITIONS ::= BEGIN END"
{:ok, tokens} = SnmpLib.MIB.Lexer.tokenize(content)

IO.puts("Original tokens:")
tokens |> Enum.each(&IO.inspect/1)

# Apply conversion manually to see what happens
converted = SnmpLib.MIB.Parser.send(:convert_tokens_for_grammar, [tokens])
IO.puts("\nConverted tokens:")
converted |> Enum.take(10) |> Enum.each(&IO.inspect/1)