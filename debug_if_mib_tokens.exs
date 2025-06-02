#!/usr/bin/env elixir

# Debug the tokens around line 31 in IF-MIB to understand the parsing issue

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

docsis_dir = "test/fixtures/mibs/docsis"
mib_path = Path.join(docsis_dir, "IF-MIB")

IO.puts("=== Analyzing Tokens Around Line 31 in IF-MIB ===")

case File.read(mib_path) do
  {:ok, content} ->
    IO.puts("✓ File read: #{byte_size(content)} bytes")
    
    # Show lines around 31
    lines = String.split(content, "\n")
    IO.puts("\nLines 25-35:")
    lines
    |> Enum.with_index(1)
    |> Enum.slice(24, 11)  # Lines 25-35
    |> Enum.each(fn {line, num} ->
      IO.puts("#{String.pad_leading(to_string(num), 3)}: #{line}")
    end)
    
    # Test tokenization
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("\n✓ Tokenization successful: #{length(tokens)} tokens")
        
        # Find tokens around line 31
        IO.puts("\nTokens around line 31:")
        tokens
        |> Enum.with_index()
        |> Enum.filter(fn {token, _idx} ->
          case token do
            {_type, _value, %{line: line}} when line >= 25 and line <= 35 -> true
            _ -> false
          end
        end)
        |> Enum.each(fn {token, idx} ->
          IO.puts("  #{idx}: #{inspect(token)}")
        end)
        
        # Look for specific problematic pattern
        IO.puts("\nLooking for identifier 's' tokens:")
        tokens
        |> Enum.with_index()
        |> Enum.filter(fn {token, _idx} ->
          case token do
            {:identifier, "s", _} -> true
            _ -> false
          end
        end)
        |> Enum.take(5)  # First 5 occurrences
        |> Enum.each(fn {token, idx} ->
          IO.puts("  #{idx}: #{inspect(token)}")
          # Show surrounding tokens
          surrounding = Enum.slice(tokens, max(0, idx - 3), 7)
          surrounding
          |> Enum.with_index(max(0, idx - 3))
          |> Enum.each(fn {t, i} ->
            marker = if i == idx, do: " >>> ", else: "     "
            IO.puts("    #{marker}#{i}: #{inspect(t)}")
          end)
          IO.puts("")
        end)
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{reason}")
    end
    
  {:error, reason} ->
    IO.puts("❌ File read failed: #{reason}")
end