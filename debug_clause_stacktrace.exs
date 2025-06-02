# Debug with stack trace to find exact location of missing clause error
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

IO.puts "Debugging 'Missing clause' error with stack trace..."

# Read the file
{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")

case Lexer.tokenize(content) do
  {:ok, tokens} ->
    IO.puts "✅ Tokenization successful: #{length(tokens)} tokens"
    
    try do
      case Parser.parse_tokens(tokens) do
        {:ok, mib} ->
          IO.puts "✅ Unexpected success! #{length(mib.definitions)} definitions"
          
        {:warning, mib, warnings} ->
          IO.puts "⚠️  Parsing with warnings: #{length(warnings)} warnings"
          
        {:error, errors} ->
          IO.puts "❌ Expected error: #{length(errors)} errors"
          first_error = List.first(errors)
          IO.puts "   Error: #{first_error.type} - #{first_error.message}"
      end
    catch
      error ->
        IO.puts "❌ Caught runtime error: #{inspect(error)}"
        IO.puts "\nStack trace:"
        Process.info(self(), :current_stacktrace)
        |> elem(1)
        |> Enum.take(10)
        |> Enum.each(fn {module, function, arity, location} ->
          IO.puts "   #{module}.#{function}/#{arity} at #{inspect(location)}"
        end)
    end
    
  {:error, error} ->
    IO.puts "❌ Tokenization failed"
    IO.puts "   Error: #{inspect(error)}"
end

# Let me also try parsing just the first few definitions to see where it breaks
IO.puts "\n" <> String.duplicate("=", 50)
IO.puts "Testing incremental parsing to find the breaking point..."

{:ok, content} = File.read("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
lines = String.split(content, "\n")

# Try parsing progressively larger chunks to find where it breaks
Enum.find([50, 100, 150, 200, 250, 300, 350], fn chunk_size ->
  test_content = (Enum.take(lines, chunk_size) |> Enum.join("\n")) <> "\nEND"
  
  case Lexer.tokenize(test_content) do
    {:ok, tokens} ->
      case Parser.parse_tokens(tokens) do
        {:ok, mib} ->
          IO.puts "✅ #{chunk_size} lines: SUCCESS - #{length(mib.definitions)} definitions"
          false # Continue searching
        {:warning, mib, warnings} ->
          IO.puts "⚠️  #{chunk_size} lines: SUCCESS with warnings - #{length(mib.definitions)} definitions, #{length(warnings)} warnings"
          false # Continue searching
        {:error, errors} ->
          first_error = List.first(errors)
          IO.puts "❌ #{chunk_size} lines: FAILED - #{first_error.type}: #{first_error.message}"
          if first_error.line do
            IO.puts "   Error at line: #{first_error.line}"
          end
          
          # This is the breaking point - let's analyze this chunk
          if first_error.type == :missing_clause do
            IO.puts "   Found the breaking point at #{chunk_size} lines!"
            IO.puts "   Lines #{chunk_size-10} to #{chunk_size}:"
            for i <- (chunk_size-10)..(chunk_size-1) do
              line = Enum.at(lines, i)
              if line do
                IO.puts "     #{i+1}: #{line}"
              end
            end
            true # Found the issue, stop searching
          else
            false # Different error, continue searching
          end
      end
    {:error, _error} ->
      IO.puts "❌ #{chunk_size} lines: TOKENIZATION FAILED"
      false # Continue searching
  end
end)