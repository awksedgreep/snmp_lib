#!/usr/bin/env elixir

# Debug SNMPv2-SMI.mib parsing issue at line 36

# Change to the project directory and load the compiled modules
System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

mib_file = "test/fixtures/mibs/working/SNMPv2-SMI.mib"

IO.puts("=== SNMPv2-SMI.mib Debug ===")

case File.read(mib_file) do
  {:ok, content} ->
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
        
        # Find tokens around line 36 (ExtUTCTime)
        IO.puts("\n=== Looking for tokens around line 36 (ExtUTCTime) ===")
        
        tokens_with_index = Enum.with_index(tokens)
        
        # Find ExtUTCTime token
        extutctime_tokens = Enum.filter(tokens_with_index, fn {{_type, value, _pos}, _idx} ->
          is_binary(value) and String.contains?(value, "ExtUTCTime")
        end)
        
        if length(extutctime_tokens) > 0 do
          {_, idx} = hd(extutctime_tokens)
          IO.puts("Found ExtUTCTime at token index #{idx}")
          
          # Show tokens around this index
          start_idx = max(0, idx - 3)
          end_idx = min(length(tokens) - 1, idx + 15)
          
          IO.puts("\nTokens #{start_idx} to #{end_idx}:")
          tokens
          |> Enum.slice(start_idx..end_idx)
          |> Enum.with_index(start_idx)
          |> Enum.each(fn {token, token_idx} ->
            marker = if token_idx == idx, do: ">>> ", else: "    "
            IO.puts("#{marker}#{token_idx}: #{inspect(token)}")
          end)
        else
          IO.puts("ExtUTCTime not found!")
        end
        
        # Try parsing
        IO.puts("\n=== Parsing ===")
        case SnmpLib.MIB.Parser.parse_tokens(tokens) do
          {:ok, mib} ->
            IO.puts("✓ Parsing: SUCCESS - #{length(mib.definitions)} definitions")
          {:error, errors} when is_list(errors) ->
            IO.puts("✗ Parsing: FAILED with #{length(errors)} errors:")
            Enum.each(errors, fn error ->
              IO.puts("  - #{inspect(error)}")
            end)
          {:error, error} ->
            IO.puts("✗ Parsing: FAILED")
            IO.puts("  #{inspect(error)}")
        end
      {:error, reason} ->
        IO.puts("✗ Tokenization failed: #{reason}")
    end
  {:error, reason} ->
    IO.puts("✗ File read failed: #{reason}")
end