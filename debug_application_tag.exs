#!/usr/bin/env elixir

# Debug APPLICATION tag parsing issue

# Change to the project directory and load the compiled modules
System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

mib_file = "test/fixtures/mibs/working/SNMPv2-SMI.mib"

IO.puts("=== APPLICATION Tag Debug ===")

case File.read(mib_file) do
  {:ok, content} ->
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
        
        # Find tokens around APPLICATION tag
        IO.puts("\n=== Looking for APPLICATION tokens ===")
        
        tokens_with_index = Enum.with_index(tokens)
        
        # Find APPLICATION tokens
        application_tokens = Enum.filter(tokens_with_index, fn {{_type, value, _pos}, _idx} ->
          (is_binary(value) and String.contains?(value, "APPLICATION")) or
          (is_binary(value) and String.downcase(value) == "application")
        end)
        
        IO.puts("Found #{length(application_tokens)} APPLICATION tokens")
        
        Enum.each(application_tokens, fn {{_type, value, pos}, idx} ->
          IO.puts("APPLICATION token at index #{idx}: value=#{value}, line=#{Map.get(pos, :line, "unknown")}")
          
          # Show tokens around this index
          start_idx = max(0, idx - 5)
          end_idx = min(length(tokens) - 1, idx + 15)
          
          IO.puts("\nTokens #{start_idx} to #{end_idx}:")
          tokens
          |> Enum.slice(start_idx..end_idx)
          |> Enum.with_index(start_idx)
          |> Enum.each(fn {token, token_idx} ->
            marker = if token_idx == idx, do: ">>> ", else: "    "
            IO.puts("#{marker}#{token_idx}: #{inspect(token)}")
          end)
          IO.puts("")
        end)
        
      {:error, reason} ->
        IO.puts("✗ Tokenization failed: #{reason}")
    end
  {:error, reason} ->
    IO.puts("✗ File read failed: #{reason}")
end