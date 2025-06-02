#!/usr/bin/env elixir

alias SnmpLib.MIB.{Lexer, ParserPort}

# Simple test that bypasses error handling
size_mib = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    SYNTAX       OCTET STRING (SIZE (0 | 36..260))
    MAX-ACCESS   read-only
    STATUS       current
    DESCRIPTION  "Test SIZE constraint"
    ::= { 1 2 3 }

END
"""

IO.puts("🔍 Testing SIZE constraint with direct parser call...")

case Lexer.tokenize(size_mib) do
  {:ok, tokens} ->
    IO.puts("✅ Tokenized successfully, #{length(tokens)} tokens")
    
    # Call the internal do_parse function directly to get the real exception
    try do
      result = :erlang.apply(ParserPort, :do_parse, [tokens])
      IO.puts("✅ Parsing successful!")
      IO.inspect(result, label: "Result")
    rescue
      exception ->
        IO.puts("❌ Exception caught:")
        IO.puts("Exception: #{inspect(exception)}")
        IO.puts("Exception type: #{inspect(exception.__struct__)}")
        IO.puts("Exception message: #{Exception.message(exception)}")
        IO.puts("Stacktrace:")
        Exception.format_stacktrace(__STACKTRACE__) |> IO.puts()
    end
    
  {:error, error} ->
    IO.puts("❌ Tokenization failed: #{inspect(error)}")
end