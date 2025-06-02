# Test parser against real-world MIB files
defmodule TestRealWorldMibs do
  alias SnmpLib.MIB.{Parser, Lexer}

  def test_real_world_mibs do
    # Standard MIBs that our parser should be able to handle
    test_files = [
      # Core SNMPv2 MIBs
      {"SNMPv2-SMI", "test/fixtures/mibs/working/SNMPv2-SMI.mib"},
      {"SNMPv2-TC", "test/fixtures/mibs/working/SNMPv2-TC.mib"},
      {"SNMPv2-MIB", "test/fixtures/mibs/working/SNMPv2-MIB.mib"},
      
      # Classic RFC MIBs
      {"RFC1213-MIB", "test/fixtures/mibs/working/RFC1213-MIB.mib"},
      {"RFC1155-SMI", "test/fixtures/mibs/working/RFC1155-SMI.mib"},
      
      # Interface MIBs
      {"IF-MIB", "test/fixtures/mibs/working/IF-MIB.mib"},
      {"IANAifType-MIB", "test/fixtures/mibs/working/IANAifType-MIB.mib"},
      
      # Standard application MIBs
      {"HOST-RESOURCES-MIB", "test/fixtures/mibs/working/HOST-RESOURCES-MIB.mib"},
      {"NOTIFICATION-LOG-MIB", "test/fixtures/mibs/working/NOTIFICATION-LOG-MIB.mib"},
      
      # Network protocol MIBs
      {"IP-MIB", "test/fixtures/mibs/working/IP-MIB.mib"},
      {"TCP-MIB", "test/fixtures/mibs/working/TCP-MIB.mib"},
      {"UDP-MIB", "test/fixtures/mibs/working/UDP-MIB.mib"}
    ]

    IO.puts "\n=== Real-World MIB Parsing Tests ==="
    IO.puts "Testing parser compatibility with standard production MIBs\n"
    
    total = length(test_files)
    
    results = Enum.map(test_files, fn {name, file_path} ->
      IO.puts "#{name}:"
      
      case File.exists?(file_path) do
        false ->
          IO.puts "  ⚠️  FILE NOT FOUND: #{file_path}"
          {:file_not_found, file_path}
          
        true ->
          case File.read(file_path) do
            {:ok, content} ->
              IO.puts "  📁 FILE READ: #{String.length(content)} characters"
              
              case Lexer.tokenize(content) do
                {:ok, tokens} ->
                  IO.puts "  ✅ TOKENIZATION SUCCESS: #{length(tokens)} tokens"
                  
                  case Parser.parse_tokens(tokens) do
                    {:ok, mib} ->
                      IO.puts "  ✅ PARSING SUCCESS: #{length(mib.definitions)} definitions"
                      IO.puts "     Module: #{mib.name}"
                      IO.puts "     Imports: #{length(mib.imports)} import groups"
                      
                      # Count different definition types
                      type_counts = count_definition_types(mib.definitions)
                      IO.puts "     Definition types:"
                      Enum.each(type_counts, fn {type, count} ->
                        IO.puts "       #{type}: #{count}"
                      end)
                      
                      {:success, mib}
                      
                    {:error, errors} ->
                      IO.puts "  ❌ PARSING FAILED: #{length(errors)} errors"
                      Enum.take(errors, 3) |> Enum.each(fn error ->
                        IO.puts "     #{SnmpLib.MIB.Error.format(error)}"
                      end)
                      if length(errors) > 3 do
                        IO.puts "     ... and #{length(errors) - 3} more errors"
                      end
                      {:parsing_failed, errors}
                      
                    {:warning, mib, warnings} ->
                      IO.puts "  ⚠️  PARSED WITH WARNINGS: #{length(warnings)} warnings"
                      Enum.take(warnings, 2) |> Enum.each(fn warning ->
                        IO.puts "     #{SnmpLib.MIB.Error.format(warning)}"
                      end)
                      IO.puts "  ✅ Definitions parsed: #{length(mib.definitions)}"
                      {:success_with_warnings, mib}
                  end
                  
                {:error, error} ->
                  IO.puts "  ❌ TOKENIZATION FAILED: #{SnmpLib.MIB.Error.format(error)}"
                  {:tokenization_failed, error}
              end
              
            {:error, reason} ->
              IO.puts "  ❌ FILE READ ERROR: #{reason}"
              {:file_read_error, reason}
          end
      end
    end)
    
    # Calculate success statistics
    successful = Enum.count(results, fn 
      {:success, _} -> true
      {:success_with_warnings, _} -> true
      _ -> false
    end)
    
    failed = Enum.count(results, fn 
      {:parsing_failed, _} -> true
      {:tokenization_failed, _} -> true
      _ -> false
    end)
    
    missing = Enum.count(results, fn 
      {:file_not_found, _} -> true
      {:file_read_error, _} -> true
      _ -> false
    end)
    
    IO.puts "\n=== Test Summary ==="
    IO.puts "Total MIBs tested: #{total}"
    IO.puts "✅ Successfully parsed: #{successful}/#{total} (#{Float.round(successful/total*100, 1)}%)"
    IO.puts "❌ Failed to parse: #{failed}/#{total}"
    IO.puts "⚠️  Missing/unreadable: #{missing}/#{total}"
    
    # Detailed success analysis
    if successful > 0 do
      successful_mibs = results
      |> Enum.filter(fn 
        {:success, _} -> true
        {:success_with_warnings, _} -> true
        _ -> false
      end)
      |> Enum.map(fn 
        {:success, mib} -> mib
        {:success_with_warnings, mib} -> mib
      end)
      
      total_definitions = Enum.reduce(successful_mibs, 0, fn mib, acc -> 
        acc + length(mib.definitions) 
      end)
      
      IO.puts "\n📊 Successfully parsed MIBs contain:"
      IO.puts "   Total definitions: #{total_definitions}"
      IO.puts "   Average definitions per MIB: #{Float.round(total_definitions/successful, 1)}"
    end
    
    if successful == total do
      IO.puts "\n🎉 ALL real-world MIB parsing tests PASSED!"
      IO.puts "Parser is production-ready for standard MIB files!"
    elsif successful >= total * 0.8 do
      IO.puts "\n🟡 GOOD compatibility with real-world MIBs (#{Float.round(successful/total*100, 1)}% success rate)"
      IO.puts "Parser handles the majority of standard MIB files successfully."
    else
      IO.puts "\n🔴 NEEDS IMPROVEMENT: Low compatibility with real-world MIBs"
      IO.puts "Parser requires additional work to handle standard MIB files."
    end
    
    {successful, failed, missing, total, results}
  end
  
  defp count_definition_types(definitions) do
    definitions
    |> Enum.group_by(& &1.__type__)
    |> Enum.map(fn {type, list} -> {type, length(list)} end)
    |> Enum.sort_by(fn {_type, count} -> -count end)
  end
end

TestRealWorldMibs.test_real_world_mibs()