#!/usr/bin/env elixir

alias SnmpLib.MIB.{Lexer, ParserPort}

# Test OCTET STRING (SIZE (0 | 36..260)) parsing specifically
tokens = [
  {:keyword, :octet, %{line: 1, column: nil}},
  {:keyword, :string, %{line: 1, column: nil}},
  {:symbol, :open_paren, %{line: 1, column: nil}},
  {:keyword, :size, %{line: 1, column: nil}},
  {:symbol, :open_paren, %{line: 1, column: nil}},
  {:integer, 0, %{line: 1, column: nil}},
  {:symbol, :pipe, %{line: 1, column: nil}},
  {:integer, 36, %{line: 1, column: nil}},
  {:symbol, :range, %{line: 1, column: nil}},
  {:integer, 260, %{line: 1, column: nil}},
  {:symbol, :close_paren, %{line: 1, column: nil}},
  {:symbol, :close_paren, %{line: 1, column: nil}}
]

IO.puts("🔍 Testing OCTET STRING SIZE constraint parsing step by step...")
IO.puts("Tokens to parse:")
Enum.with_index(tokens) |> Enum.each(fn {token, idx} ->
  IO.puts("  #{idx}: #{inspect(token)}")
end)

# Manually test the syntax parsing
try do
  # This should call parse_syntax_type which then calls parse_size_constraint
  case :erlang.apply(ParserPort, :parse_syntax_type, [tokens]) do
    {:ok, result} ->
      IO.puts("✅ Syntax type parsing successful!")
      IO.inspect(result, label: "Result")
    {:error, reason} ->
      IO.puts("❌ Syntax type parsing failed: #{reason}")
  end
rescue
  exception ->
    IO.puts("❌ Exception in syntax type parsing:")
    IO.puts("Exception: #{inspect(exception)}")
    IO.puts("Exception type: #{inspect(exception.__struct__)}")
    IO.puts("Exception message: #{Exception.message(exception)}")
    IO.puts("Stacktrace:")
    Exception.format_stacktrace(__STACKTRACE__) |> IO.puts()
end