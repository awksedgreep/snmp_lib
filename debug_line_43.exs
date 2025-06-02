#!/usr/bin/env elixir

# Debug the tokens around line 43 in IF-MIB to understand the next parsing issue

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

docsis_dir = "test/fixtures/mibs/docsis"
mib_path = Path.join(docsis_dir, "IF-MIB")

IO.puts("=== Analyzing Tokens Around Line 43 in IF-MIB ===")

case File.read(mib_path) do
  {:ok, content} ->
    IO.puts("✓ File read: #{byte_size(content)} bytes")
    
    # Show lines around 43
    lines = String.split(content, "\n")
    IO.puts("\nLines 38-48:")
    lines
    |> Enum.with_index(1)
    |> Enum.slice(37, 11)  # Lines 38-48
    |> Enum.each(fn {line, num} ->
      IO.puts("#{String.pad_leading(to_string(num), 3)}: #{line}")
    end)
    
    # Test tokenization
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("\n✓ Tokenization successful: #{length(tokens)} tokens")
        
        # Find tokens around line 43
        IO.puts("\nTokens around line 43:")
        tokens
        |> Enum.with_index()
        |> Enum.filter(fn {token, _idx} ->
          case token do
            {_type, _value, %{line: line}} when line >= 38 and line <= 48 -> true
            _ -> false
          end
        end)
        |> Enum.each(fn {token, idx} ->
          IO.puts("  #{idx}: #{inspect(token)}")
        end)
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{reason}")
    end
    
  {:error, reason} ->
    IO.puts("❌ File read failed: #{reason}")
end