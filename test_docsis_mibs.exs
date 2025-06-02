# Comprehensive DOCSIS MIB Parsing Test
Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser.ex")
Code.require_file("lib/snmp_lib/mib/ast.ex")
Code.require_file("lib/snmp_lib/mib/error.ex")
Code.require_file("lib/snmp_lib/mib/logger.ex")

alias SnmpLib.MIB.{Parser, Lexer}

defmodule DocsisTestSuite do
  alias SnmpLib.MIB.{Parser, Lexer}
  
  def run_docsis_tests do
    IO.puts "\n" <> String.duplicate("=", 70)
    IO.puts "🏢 DOCSIS MIB COMPATIBILITY TEST SUITE"
    IO.puts String.duplicate("=", 70)
    IO.puts "Testing critical DOCSIS MIBs for cable modem management\n"
    
    # Core DOCSIS MIBs in order of importance
    docsis_mibs = [
      # Core Cable Modem MIBs
      {"DOCS-CABLE-DEVICE-MIB", "test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB", :critical},
      {"DOCS-IF-MIB", "test/fixtures/mibs/docsis/DOCS-IF-MIB", :critical},
      {"DOCS-QOS-MIB", "test/fixtures/mibs/docsis/DOCS-QOS-MIB", :critical},
      
      # Security & Management
      {"DOCS-BPI2-MIB", "test/fixtures/mibs/docsis/DOCS-BPI2-MIB", :important},
      {"DOCS-BPI-MIB", "test/fixtures/mibs/docsis/DOCS-BPI-MIB", :important},
      {"DOCS-SUBMGT-MIB", "test/fixtures/mibs/docsis/DOCS-SUBMGT-MIB", :important},
      
      # Extended Features
      {"DOCS-IF-EXT-MIB", "test/fixtures/mibs/docsis/DOCS-IF-EXT-MIB", :useful},
      {"DOCS-CABLE-DEVICE-TRAP-MIB", "test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-TRAP-MIB", :useful},
      
      # PacketCable (VoIP over Cable)
      {"PKTC-MTA-MIB", "test/fixtures/mibs/docsis/PKTC-MTA-MIB", :useful},
      {"PKTC-IETF-SIG-MIB", "test/fixtures/mibs/docsis/PKTC-IETF-SIG-MIB", :useful},
      {"PKTC-EVENT-MIB", "test/fixtures/mibs/docsis/PKTC-EVENT-MIB", :useful},
      
      # Supporting MIBs
      {"CLAB-DEF-MIB", "test/fixtures/mibs/docsis/CLAB-DEF-MIB", :foundation},
      {"DIFFSERV-MIB", "test/fixtures/mibs/docsis/DIFFSERV-MIB", :foundation},
      {"DIFFSERV-DSCP-TC", "test/fixtures/mibs/docsis/DIFFSERV-DSCP-TC", :foundation},
    ]
    
    results = test_mib_suite(docsis_mibs)
    analyze_docsis_results(results)
  end
  
  defp test_mib_suite(mibs) do
    Enum.map(mibs, fn {name, path, priority} ->
      IO.puts "🔍 Testing #{name} (#{priority}):"
      result = test_single_docsis_mib(path)
      {name, priority, result}
    end)
  end
  
  defp test_single_docsis_mib(path) do
    case File.read(path) do
      {:ok, content} ->
        case Lexer.tokenize(content) do
          {:ok, tokens} ->
            IO.puts "  ✅ Tokenization: #{length(tokens)} tokens"
            
            case Parser.parse_tokens(tokens) do
              {:ok, mib} ->
                definitions = mib.definitions
                imports = mib.imports
                
                # Analyze MIB structure
                type_counts = definitions
                |> Enum.group_by(& &1.__type__)
                |> Enum.map(fn {type, list} -> {type, length(list)} end)
                |> Enum.sort_by(fn {_, count} -> count end, :desc)
                
                IO.puts "  ✅ Parsing: #{length(definitions)} definitions, #{length(imports)} import groups"
                IO.puts "  📊 Definition breakdown:"
                Enum.each(type_counts, fn {type, count} ->
                  IO.puts "     • #{type}: #{count}"
                end)
                
                # Specific DOCSIS validation
                validate_docsis_features(mib)
                
                {:success, %{
                  definitions: length(definitions),
                  imports: length(imports),
                  types: type_counts
                }}
                
              {:warning, mib, warnings} ->
                IO.puts "  ⚠️  Parsing: #{length(mib.definitions)} definitions with #{length(warnings)} warnings"
                first_warning = List.first(warnings)
                IO.puts "     Warning: #{SnmpLib.MIB.Error.format(first_warning)}"
                {:warning, %{definitions: length(mib.definitions), warning: first_warning}}
                
              {:error, errors} ->
                IO.puts "  ❌ Parsing failed: #{length(errors)} errors"
                first_error = List.first(errors)
                error_msg = SnmpLib.MIB.Error.format(first_error)
                IO.puts "     Error: #{error_msg}"
                {:error, error_msg}
            end
            
          {:error, error} ->
            IO.puts "  ❌ Tokenization failed"
            error_msg = SnmpLib.MIB.Error.format(error)
            IO.puts "     Error: #{error_msg}"
            {:tokenize_error, error_msg}
        end
        
      {:error, reason} ->
        IO.puts "  ❌ File not found: #{reason}"
        {:file_error, reason}
    end
  end
  
  defp validate_docsis_features(mib) do
    # Check for common DOCSIS patterns
    has_compliance = Enum.any?(mib.definitions, &(&1.__type__ == :module_compliance))
    has_groups = Enum.any?(mib.definitions, &(&1.__type__ == :object_group))
    has_notifications = Enum.any?(mib.definitions, &(&1.__type__ == :notification_type))
    has_textual_conventions = Enum.any?(mib.definitions, &(&1.__type__ == :textual_convention))
    
    docsis_features = []
    docsis_features = if has_compliance, do: ["MODULE-COMPLIANCE" | docsis_features], else: docsis_features
    docsis_features = if has_groups, do: ["OBJECT-GROUP" | docsis_features], else: docsis_features
    docsis_features = if has_notifications, do: ["NOTIFICATION-TYPE" | docsis_features], else: docsis_features
    docsis_features = if has_textual_conventions, do: ["TEXTUAL-CONVENTION" | docsis_features], else: docsis_features
    
    if length(docsis_features) > 0 do
      IO.puts "  🎯 DOCSIS features: #{Enum.join(docsis_features, ", ")}"
    end
  end
  
  defp analyze_docsis_results(results) do
    IO.puts "\n" <> String.duplicate("=", 70)
    IO.puts "📊 DOCSIS MIB TEST RESULTS"
    IO.puts String.duplicate("=", 70)
    
    # Group by priority and status
    critical_results = Enum.filter(results, fn {_, priority, _} -> priority == :critical end)
    important_results = Enum.filter(results, fn {_, priority, _} -> priority == :important end)
    useful_results = Enum.filter(results, fn {_, priority, _} -> priority == :useful end)
    foundation_results = Enum.filter(results, fn {_, priority, _} -> priority == :foundation end)
    
    # Analyze success rates
    analyze_priority_group("🚨 CRITICAL MIBs", critical_results)
    analyze_priority_group("🔧 IMPORTANT MIBs", important_results)  
    analyze_priority_group("📈 USEFUL MIBs", useful_results)
    analyze_priority_group("🏗️ FOUNDATION MIBs", foundation_results)
    
    # Overall assessment
    provide_docsis_assessment(results)
  end
  
  defp analyze_priority_group(label, results) do
    if length(results) > 0 do
      IO.puts "\n#{label} (#{length(results)} MIBs):"
      
      successes = Enum.count(results, fn {_, _, {status, _}} -> status == :success end)
      warnings = Enum.count(results, fn {_, _, {status, _}} -> status == :warning end)
      failures = length(results) - successes - warnings
      
      IO.puts "  ✅ Success: #{successes}"
      if warnings > 0, do: IO.puts "  ⚠️  Warnings: #{warnings}"
      if failures > 0, do: IO.puts "  ❌ Failures: #{failures}"
      
      # Show specific failures
      Enum.each(results, fn {name, _, {status, data}} ->
        case status do
          :error -> IO.puts "    ❌ #{name}: #{data}"
          :tokenize_error -> IO.puts "    🔴 #{name}: #{data}"
          :file_error -> IO.puts "    📁 #{name}: #{data}"
          _ -> nil
        end
      end)
    end
  end
  
  defp provide_docsis_assessment(results) do
    IO.puts "\n🎯 DOCSIS DEPLOYMENT READINESS ASSESSMENT:"
    
    critical_successes = results
    |> Enum.filter(fn {_, priority, _} -> priority == :critical end)
    |> Enum.count(fn {_, _, {status, _}} -> status in [:success, :warning] end)
    
    total_critical = results
    |> Enum.filter(fn {_, priority, _} -> priority == :critical end)
    |> length()
    
    critical_rate = if total_critical > 0, do: (critical_successes / total_critical * 100), else: 0
    
    total_successes = Enum.count(results, fn {_, _, {status, _}} -> status in [:success, :warning] end)
    overall_rate = total_successes / length(results) * 100
    
    IO.puts "  🚨 Critical MIB Success Rate: #{critical_successes}/#{total_critical} (#{Float.round(critical_rate, 1)}%)"
    IO.puts "  📊 Overall Success Rate: #{total_successes}/#{length(results)} (#{Float.round(overall_rate, 1)}%)"
    
    cond do
      critical_rate >= 100 ->
        IO.puts "\n  🎉 EXCELLENT: All critical DOCSIS MIBs parse successfully!"
        IO.puts "  ✅ Ready for production DOCSIS cable modem management"
        IO.puts "  💡 Your SNMP library can handle core DOCSIS operations"
        
      critical_rate >= 75 ->
        IO.puts "\n  👍 GOOD: Most critical DOCSIS MIBs parse successfully"
        IO.puts "  ⚠️  Some minor issues may need attention for full DOCSIS support"
        IO.puts "  🔧 Consider addressing critical MIB failures before deployment"
        
      critical_rate >= 50 ->
        IO.puts "\n  ⚠️  PARTIAL: Some critical DOCSIS MIBs have issues"
        IO.puts "  🔧 Recommend fixing critical MIB parsing before DOCSIS deployment"
        IO.puts "  📋 Focus on DOCS-CABLE-DEVICE-MIB and DOCS-IF-MIB first"
        
      true ->
        IO.puts "\n  🚨 NEEDS WORK: Critical DOCSIS MIBs require attention"
        IO.puts "  🔧 Parser needs enhancement for DOCSIS cable modem management"
        IO.puts "  📋 Address critical parsing issues before production use"
    end
    
    if overall_rate >= 80 do
      IO.puts "\n  🚀 DOCSIS MIB support is production-ready for cable management!"
    end
  end
end

DocsisTestSuite.run_docsis_tests()