# Debug the exact tokens around the failure point
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

# Get the exact failing content from the DOCS-CABLE-DEVICE-MIB
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
lines = String.split(content, "\n")

# Get content that includes the failure point
failing_content = (Enum.take(lines, 210) |> Enum.join("\n")) <> "\nEND"

IO.puts "Examining tokens around the failure point..."

case Lexer.tokenize(failing_content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    # Find the docsDevRole definition tokens
    docs_dev_role_start = Enum.find_index(tokens, fn 
      {:identifier, "docsDevRole", _} -> true
      _ -> false
    end)
    
    if docs_dev_role_start do
      IO.puts "\nTokens around docsDevRole definition:"
      relevant_tokens = Enum.slice(tokens, docs_dev_role_start, 25)
      Enum.with_index(relevant_tokens, docs_dev_role_start) |> Enum.each(fn {{type, value, pos}, idx} ->
        line_info = if Map.has_key?(pos || %{}, :line), do: " (line #{pos.line})", else: ""
        IO.puts "   #{idx}: #{type} = #{inspect(value)}#{line_info}"
      end)
    end
    
    # Try to parse and see exactly where it fails
    IO.puts "\nAttempting to parse..."
    case Parser.parse_tokens(tokens) do
      {:ok, mib} ->
        IO.puts "✅ Unexpected success!"
      {:error, errors} ->
        IO.puts "❌ Expected failure occurred"
        first_error = List.first(errors)
        error_msg = SnmpLib.MIB.Error.format(first_error)
        IO.puts "   Error: #{error_msg}"
        
        # Try to find which specific token caused the issue
        IO.puts "\nLooking for the specific problematic token..."
        
        # Find tokens around cmtsActive
        cmts_active_index = Enum.find_index(tokens, fn 
          {:identifier, "cmtsActive", _} -> true
          _ -> false
        end)
        
        if cmts_active_index do
          IO.puts "\nTokens around 'cmtsActive':"
          context_tokens = Enum.slice(tokens, max(0, cmts_active_index - 5), 11)
          Enum.with_index(context_tokens, max(0, cmts_active_index - 5)) |> Enum.each(fn {{type, value, pos}, idx} ->
            line_info = if Map.has_key?(pos || %{}, :line), do: " (line #{pos.line})", else: ""
            marker = if idx == cmts_active_index, do: " <<<< HERE", else: ""
            IO.puts "   #{idx}: #{type} = #{inspect(value)}#{line_info}#{marker}"
          end)
        end
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    error_msg = SnmpLib.MIB.Error.format(error)
    IO.puts "   Error: #{error_msg}"
end