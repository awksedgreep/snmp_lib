#!/usr/bin/env elixir

alias SnmpLib.MIB.{Lexer, ParserPort}

mib_content = """
TEST-MIB DEFINITIONS ::= BEGIN

testObject OBJECT-TYPE
    SYNTAX       OCTET STRING (SIZE (0 | 36..260))
    MAX-ACCESS   read-only
    STATUS       current
    DESCRIPTION  "Test SIZE constraint"
    ::= { 1 2 3 }

END
"""

IO.puts("🔍 Debugging exception in SIZE constraint parsing...")

case Lexer.tokenize(mib_content) do
  {:ok, tokens} ->
    IO.puts("✅ Lexing successful, #{length(tokens)} tokens")
    
    try do
      case ParserPort.parse_tokens(tokens) do
        {:ok, mib} ->
          IO.puts("✅ Parsing successful!")
          IO.inspect(mib, label: "Parsed MIB")
          
        {:error, errors} ->
          IO.puts("❌ Parsing failed with errors:")
          Enum.each(errors, fn error ->
            IO.puts("  - Type: #{error.type}")
            IO.puts("  - Message: #{error.message}")
            IO.puts("  - Line: #{error.line}")
          end)
      end
    rescue
      exception ->
        IO.puts("❌ Exception during parsing:")
        IO.puts("  Exception: #{inspect(exception)}")
        IO.puts("  Stacktrace:")
        Exception.format_stacktrace(__STACKTRACE__) |> IO.puts()
    end
    
  {:error, error} ->
    IO.puts("❌ Lexing failed: #{inspect(error)}")
end