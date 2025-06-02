#!/usr/bin/env elixir

# Debug the parsing failure in IF-MIB after tokenization fix

System.cmd("mix", ["compile"], cd: "/Users/mcotner/Documents/elixir/snmp_lib")
Code.prepend_path("/Users/mcotner/Documents/elixir/snmp_lib/_build/dev/lib/snmp_lib/ebin")

docsis_dir = "test/fixtures/mibs/docsis"
mib_path = Path.join(docsis_dir, "IF-MIB")

IO.puts("=== Debugging IF-MIB Parsing Issue ===")

case File.read(mib_path) do
  {:ok, content} ->
    IO.puts("✓ File read: #{byte_size(content)} bytes")
    
    # Test tokenization
    case SnmpLib.MIB.LexerErlangPort.tokenize(content) do
      {:ok, tokens} ->
        IO.puts("✓ Tokenization successful: #{length(tokens)} tokens")
        
        # Test parsing
        case SnmpLib.MIB.Parser.parse_tokens(tokens) do
          {:ok, mib} ->
            IO.puts("✓ Parsing successful: #{length(mib.definitions)} definitions")
          {:error, errors} ->
            IO.puts("❌ Parsing failed!")
            IO.puts("Error details:")
            if is_list(errors) do
              Enum.each(errors, fn error ->
                IO.puts("  - #{inspect(error)}")
              end)
            else
              IO.puts("  - #{inspect(errors)}")
            end
            
            # Let's see the first few tokens to understand the structure
            IO.puts("\nFirst 20 tokens:")
            tokens
            |> Enum.take(20)
            |> Enum.with_index()
            |> Enum.each(fn {token, idx} ->
              IO.puts("  #{idx}: #{inspect(token)}")
            end)
        end
        
      {:error, reason} ->
        IO.puts("❌ Tokenization failed: #{reason}")
    end
    
  {:error, reason} ->
    IO.puts("❌ File read failed: #{reason}")
end