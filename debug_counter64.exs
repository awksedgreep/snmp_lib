#!/usr/bin/env elixir

# Debug Counter64 tagged type parsing issue

# Change to the project directory and load the compiled modules
System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

mib_file = "test/fixtures/mibs/working/SNMPv2-SMI.mib"

IO.puts("=== Counter64 Debug ===")

case File.read(mib_file) do
  {:ok, content} ->
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
        
        # Find tokens around Counter64 definition (should be around line 206-208)
        IO.puts("\n=== Looking for Counter64 tokens ===")
        
        tokens_with_index = Enum.with_index(tokens)
        
        # Find Counter64 token
        counter64_tokens = Enum.filter(tokens_with_index, fn {{_type, value, _pos}, _idx} ->
          is_binary(value) and String.contains?(value, "Counter64")
        end)
        
        if length(counter64_tokens) > 0 do
          {_, idx} = hd(counter64_tokens)
          IO.puts("Found Counter64 at token index #{idx}")
          
          # Show tokens around this index
          start_idx = max(0, idx - 3)
          end_idx = min(length(tokens) - 1, idx + 25)
          
          IO.puts("\nTokens #{start_idx} to #{end_idx}:")
          tokens
          |> Enum.slice(start_idx..end_idx)
          |> Enum.with_index(start_idx)
          |> Enum.each(fn {token, token_idx} ->
            marker = if token_idx == idx, do: ">>> ", else: "    "
            IO.puts("#{marker}#{token_idx}: #{inspect(token)}")
          end)
        else
          IO.puts("Counter64 not found!")
        end
        
      {:error, reason} ->
        IO.puts("✗ Tokenization failed: #{reason}")
    end
  {:error, reason} ->
    IO.puts("✗ File read failed: #{reason}")
end