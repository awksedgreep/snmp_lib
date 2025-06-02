#!/usr/bin/env elixir

# Debug the specific context where the IF-MIB parsing fails

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

docsis_dir = "test/fixtures/mibs/docsis"
mib_path = Path.join(docsis_dir, "IF-MIB")

IO.puts("=== Debugging IF-MIB Context Around Error ==")

case File.read(mib_path) do
  {:ok, content} ->
    IO.puts("✓ File read: #{byte_size(content)} bytes")
    
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
        
        # Find the MODULE-IDENTITY token and show context around it
        IO.puts("\nLooking for MODULE-IDENTITY context:")
        
        tokens
        |> Enum.with_index()
        |> Enum.find(fn {token, _idx} ->
          case token do
            {:variable, "ifMIB", _} -> true
            _ -> false
          end
        end)
        |> case do
          {_token, idx} ->
            IO.puts("Found ifMIB at index #{idx}")
            
            # Show tokens around ifMIB definition (should include MODULE-IDENTITY)
            context_tokens = Enum.slice(tokens, idx, 50)
            
            IO.puts("\nTokens around ifMIB definition:")
            context_tokens
            |> Enum.with_index(idx)
            |> Enum.each(fn {token, i} ->
              IO.puts("  #{i}: #{inspect(token)}")
            end)
            
          nil ->
            IO.puts("ifMIB not found")
        end
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{reason}")
    end
    
  {:error, reason} ->
    IO.puts("❌ File read failed: #{reason}")
end