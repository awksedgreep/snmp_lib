#!/usr/bin/env elixir

# Debug the specific description parsing issue in IF-MIB

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

docsis_dir = "test/fixtures/mibs/docsis"
mib_path = Path.join(docsis_dir, "IF-MIB")

IO.puts("=== Debugging Description Parsing in IF-MIB ==")

case File.read(mib_path) do
  {:ok, content} ->
    IO.puts("✓ File read: #{byte_size(content)} bytes")
    
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
        
        # Find the DESCRIPTION token before "Clarifications"
        description_indices = tokens
        |> Enum.with_index()
        |> Enum.filter(fn {{type, value, _}, _idx} ->
          type == :keyword and value == :description
        end)
        
        IO.puts("\nFound #{length(description_indices)} DESCRIPTION tokens:")
        Enum.each(description_indices, fn {{_type, _value, meta}, idx} ->
          IO.puts("  Index #{idx}: line #{meta.line}")
        end)
        
        # Find the problematic DESCRIPTION (the one before Clarifications)
        # Look for the one around line 42
        problematic_desc = Enum.find(description_indices, fn {{_type, _value, meta}, _idx} ->
          meta.line >= 40 and meta.line <= 45
        end)
        
        case problematic_desc do
          {{_type, _value, _meta}, desc_idx} ->
            IO.puts("\nProblematic DESCRIPTION at index #{desc_idx}")
            
            # Show tokens around this DESCRIPTION
            context_tokens = Enum.slice(tokens, desc_idx, 20)
            
            IO.puts("\nTokens from DESCRIPTION:")
            context_tokens
            |> Enum.with_index(desc_idx)
            |> Enum.each(fn {token, i} ->
              marker = if i == desc_idx, do: " >>> ", else: "     "
              IO.puts("#{marker}#{i}: #{inspect(token)}")
            end)
            
            # Try parsing just the description clause starting from this point
            IO.puts("\nTesting description parsing from this point...")
            desc_tokens = Enum.drop(tokens, desc_idx)
            
            try do
              case SnmpLib.MIB.Parser.parse_description_clause(desc_tokens) do
                {:ok, {description, remaining_tokens}} ->
                  IO.puts("✓ Description parsing succeeded!")
                  IO.puts("Description: #{inspect(description)}")
                  IO.puts("Remaining tokens (first 10): #{inspect(Enum.take(remaining_tokens, 10))}")
                {:error, reason} ->
                  IO.puts("❌ Description parsing failed: #{inspect(reason)}")
              end
            rescue
              error ->
                IO.puts("❌ Exception during description parsing: #{inspect(error)}")
            end
            
          nil ->
            IO.puts("Could not find problematic DESCRIPTION token")
        end
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{reason}")
    end
    
  {:error, reason} ->
    IO.puts("❌ File read failed: #{reason}")
end