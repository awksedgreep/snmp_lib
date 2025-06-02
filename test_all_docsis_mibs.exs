#!/usr/bin/env elixir

Application.put_env(:snmp_lib, :environment, :test)

defmodule DocsisMibSuite do
  @moduledoc "Test all DOCSIS MIBs comprehensively"

  def test_all_docsis_mibs do
    IO.puts("🧪 DOCSIS MIB Parsing Test Suite")
    IO.puts("================================\n")
    
    # DOCSIS Critical MIBs
    critical_mibs = [
      "DOCS-IF-MIB",
      "DOCS-CABLE-DEVICE-MIB"
    ]
    
    # DOCSIS Important MIBs  
    important_mibs = [
      "DOCS-QOS-MIB",
      "DOCS-BPI-MIB"
    ]
    
    # DOCSIS Extended MIBs
    extended_mibs = [
      "DOCS-IETF-BPI2-MIB",
      "DOCS-IETF-QOS-MIB",
      "DOCS-IETF-SUBMGT-MIB"
    ]
    
    # DOCSIS Supporting MIBs
    supporting_mibs = [
      "DOCS-IETF-CABLE-DEVICE-NOTIFICATION-MIB",
      "DOCS-LOADBAL-MIB",
      "DOCS-MCAST-MIB"
    ]
    
    # Test each category
    critical_results = test_mib_category("Critical DOCSIS MIBs", critical_mibs)
    important_results = test_mib_category("Important DOCSIS MIBs", important_mibs)  
    extended_results = test_mib_category("Extended DOCSIS MIBs", extended_mibs)
    supporting_results = test_mib_category("Supporting DOCSIS MIBs", supporting_mibs)
    
    # Calculate overall stats
    all_results = critical_results ++ important_results ++ extended_results ++ supporting_results
    total_mibs = length(all_results)
    successful_mibs = all_results |> Enum.count(fn {_name, success} -> success end)
    
    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("📊 FINAL RESULTS")
    IO.puts(String.duplicate("=", 50))
    
    success_rate = Float.round(successful_mibs / total_mibs * 100, 1)
    IO.puts("Overall Success Rate: #{successful_mibs}/#{total_mibs} (#{success_rate}%)")
    
    # Category breakdowns
    print_category_summary("Critical", critical_results)
    print_category_summary("Important", important_results)
    print_category_summary("Extended", extended_results)
    print_category_summary("Supporting", supporting_results)
    
    IO.puts("\n🎯 TARGET THRESHOLDS:")
    IO.puts("- Critical DOCSIS MIBs: 100%")
    IO.puts("- Important DOCSIS MIBs: 80%+")
    IO.puts("- Extended DOCSIS MIBs: 70%+")  
    IO.puts("- Supporting MIBs: 60%+")
    
    # Check if we've met our targets
    critical_rate = calculate_success_rate(critical_results)
    important_rate = calculate_success_rate(important_results)
    extended_rate = calculate_success_rate(extended_results)
    supporting_rate = calculate_success_rate(supporting_results)
    
    IO.puts("\n🏆 STATUS:")
    IO.puts("- Critical: #{format_status(critical_rate, 100.0)}")
    IO.puts("- Important: #{format_status(important_rate, 80.0)}")
    IO.puts("- Extended: #{format_status(extended_rate, 70.0)}")
    IO.puts("- Supporting: #{format_status(supporting_rate, 60.0)}")
  end
  
  defp test_mib_category(category_name, mibs) do
    IO.puts("📂 #{category_name}")
    IO.puts(String.duplicate("-", String.length(category_name) + 3))
    
    results = Enum.map(mibs, fn mib_name ->
      result = test_single_mib(mib_name)
      {mib_name, result}
    end)
    
    successful = results |> Enum.count(fn {_name, success} -> success end)
    total = length(results)
    rate = Float.round(successful / total * 100, 1)
    
    IO.puts("Category Success Rate: #{successful}/#{total} (#{rate}%)\n")
    
    results
  end
  
  defp test_single_mib(mib_name) do
    mib_path = "test/fixtures/mibs/docsis/#{mib_name}"
    
    case File.exists?(mib_path) do
      false ->
        IO.puts("  ❓ #{mib_name}: File not found")
        false
        
      true ->
        case File.read(mib_path) do
          {:ok, content} ->
            case SnmpLib.MIB.Parser.parse(content) do
              {:ok, mib} ->
                definition_count = length(mib.definitions)
                IO.puts("  ✅ #{mib_name}: #{definition_count} definitions")
                true
                
              {:error, [error]} ->
                error_msg = String.slice(error.message, 0, 60)
                IO.puts("  ❌ #{mib_name}: #{error_msg}...")
                false
            end
            
          {:error, reason} ->
            IO.puts("  ❌ #{mib_name}: Read error - #{reason}")
            false
        end
    end
  end
  
  defp print_category_summary(category, results) do
    successful = results |> Enum.count(fn {_name, success} -> success end)
    total = length(results)
    rate = Float.round(successful / total * 100, 1)
    IO.puts("#{category}: #{successful}/#{total} (#{rate}%)")
  end
  
  defp calculate_success_rate(results) do
    successful = results |> Enum.count(fn {_name, success} -> success end)
    total = length(results)
    Float.round(successful / total * 100, 1)
  end
  
  defp format_status(actual_rate, target_rate) do
    if actual_rate >= target_rate do
      "✅ #{actual_rate}% (Target: #{target_rate}%)"
    else
      "❌ #{actual_rate}% (Target: #{target_rate}%)"
    end
  end
end

DocsisMibSuite.test_all_docsis_mibs()