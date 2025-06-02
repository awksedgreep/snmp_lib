#!/usr/bin/env elixir

# Debug tokenization around line 99 of RFC1155-SMI.mib

# Change to the project directory and load the compiled modules
System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

# Test RFC1155-SMI.mib tokenization
mib_file = "test/fixtures/mibs/working/RFC1155-SMI.mib"

IO.puts("=== Tokenization Debug for #{Path.basename(mib_file)} ===")

case File.read(mib_file) do
  {:ok, content} ->
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
        
        # Find tokens around line 99 (look for IpAddress)
        IO.puts("\n=== Looking for tokens around IpAddress ===")
        
        tokens_with_index = Enum.with_index(tokens)
        
        ipaddress_tokens = Enum.filter(tokens_with_index, fn {{type, value, _pos}, _idx} ->
          type == :identifier and value == "IpAddress" or
          type == :keyword and value == :ipaddress or
          type == :variable and value == "IpAddress"
        end)
        
        if length(ipaddress_tokens) > 0 do
          {_, idx} = hd(ipaddress_tokens)
          IO.puts("Found IpAddress at token index #{idx}")
          
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
        else
          IO.puts("IpAddress not found in tokens!")
          # Show all tokens containing "address" or "APPLICATION"
          Enum.with_index(tokens)
          |> Enum.filter(fn {{_type, value, _pos}, _idx} ->
            is_binary(value) and (String.contains?(value, "address") or String.contains?(value, "APPLICATION"))
          end)
          |> Enum.each(fn {token, idx} ->
            IO.puts("#{idx}: #{inspect(token)}")
          end)
        end
      {:error, reason} ->
        IO.puts("✗ Tokenization failed: #{reason}")
    end
  {:error, reason} ->
    IO.puts("✗ File read failed: #{reason}")
end