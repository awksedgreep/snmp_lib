# Test broken MIBs to identify parsing issues
alias SnmpLib.MIB.{Parser, Lexer}

defmodule BrokenMibAnalysis do
  alias SnmpLib.MIB.{Parser, Lexer}
  
  def analyze_broken_mibs do
    IO.puts "\n" <> String.duplicate("=", 60)
    IO.puts "BROKEN MIB ANALYSIS - IDENTIFYING NEXT PRIORITIES"
    IO.puts String.duplicate("=", 60)
    
    broken_mibs = [
      {"IPV6-TC", "test/fixtures/mibs/broken/IPV6-TC.mib"},
      {"IPV6-MIB", "test/fixtures/mibs/broken/IPV6-MIB.mib"},
      {"UCD-SNMP-MIB", "test/fixtures/mibs/broken/UCD-SNMP-MIB.mib"},
      {"DISMAN-EVENT-MIB", "test/fixtures/mibs/broken/DISMAN-EVENT-MIB.mib"}
    ]
    
    results = Enum.map(broken_mibs, fn {name, path} ->
      IO.puts "\n🔍 Testing #{name}:"
      analyze_single_mib(name, path)
    end)
    
    summarize_issues(results)
  end
  
  defp analyze_single_mib(name, path) do
    case File.read(path) do
      {:ok, content} ->
        case Lexer.tokenize(content) do
          {:ok, tokens} ->
            IO.puts "  ✅ Tokenization: #{length(tokens)} tokens"
            
            case Parser.parse_tokens(tokens) do
              {:ok, mib} ->
                IO.puts "  ✅ Parsing: #{length(mib.definitions)} definitions"
                {:success, name, nil}
              {:warning, mib, warnings} ->
                IO.puts "  ⚠️  Parsing: #{length(mib.definitions)} definitions with #{length(warnings)} warnings"
                first_warning = List.first(warnings)
                {:warning, name, SnmpLib.MIB.Error.format(first_warning)}
              {:error, errors} ->
                IO.puts "  ❌ Parsing failed: #{length(errors)} errors"
                first_error = List.first(errors)
                error_msg = SnmpLib.MIB.Error.format(first_error)
                IO.puts "     First error: #{error_msg}"
                {:error, name, error_msg}
            end
          {:error, error} ->
            IO.puts "  ❌ Tokenization failed"
            error_msg = SnmpLib.MIB.Error.format(error)
            IO.puts "     Error: #{error_msg}"
            {:tokenize_error, name, error_msg}
        end
      {:error, reason} ->
        IO.puts "  ❌ File read failed: #{reason}"
        {:file_error, name, reason}
    end
  end
  
  defp summarize_issues(results) do
    IO.puts "\n" <> String.duplicate("=", 60)
    IO.puts "ISSUE SUMMARY & NEXT PRIORITIES"
    IO.puts String.duplicate("=", 60)
    
    successes = Enum.filter(results, fn {status, _, _} -> status == :success end)
    warnings = Enum.filter(results, fn {status, _, _} -> status == :warning end)
    errors = Enum.filter(results, fn {status, _, _} -> status == :error end)
    tokenize_errors = Enum.filter(results, fn {status, _, _} -> status == :tokenize_error end)
    
    IO.puts "\n📊 Results Summary:"
    IO.puts "  ✅ Successful parses: #{length(successes)}"
    IO.puts "  ⚠️  Warnings: #{length(warnings)}"
    IO.puts "  ❌ Parse errors: #{length(errors)}"
    IO.puts "  🔴 Tokenize errors: #{length(tokenize_errors)}"
    
    if length(errors) > 0 do
      IO.puts "\n🔧 PARSE ERRORS TO ADDRESS:"
      Enum.each(errors, fn {_, name, error} ->
        IO.puts "  • #{name}: #{error}"
      end)
    end
    
    if length(tokenize_errors) > 0 do
      IO.puts "\n🚨 TOKENIZATION ERRORS (HIGH PRIORITY):"
      Enum.each(tokenize_errors, fn {_, name, error} ->
        IO.puts "  • #{name}: #{error}"
      end)
    end
    
    if length(warnings) > 0 do
      IO.puts "\n⚠️  WARNINGS (LOW PRIORITY):"
      Enum.each(warnings, fn {_, name, warning} ->
        IO.puts "  • #{name}: #{warning}"
      end)
    end
    
    suggest_next_steps(results)
  end
  
  defp suggest_next_steps(results) do
    IO.puts "\n🎯 RECOMMENDED NEXT STEPS:"
    
    errors = Enum.filter(results, fn {status, _, _} -> status in [:error, :tokenize_error] end)
    
    if length(errors) == 0 do
      IO.puts "  🎉 All tested MIBs parse successfully!"
      IO.puts "  ✅ No immediate parsing issues to address"
      IO.puts "  💡 Consider testing more complex vendor MIBs"
    else
      IO.puts "  1. Address parsing errors in order of frequency"
      IO.puts "  2. Focus on tokenization errors first (higher impact)"
      IO.puts "  3. Implement missing MIB constructs identified"
      IO.puts "  4. Add error recovery for malformed MIB patterns"
    end
  end
end

BrokenMibAnalysis.analyze_broken_mibs()