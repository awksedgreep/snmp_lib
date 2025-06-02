#!/usr/bin/env elixir

defmodule TestAllMibs do
  def run do
    IO.puts("🧪 Testing 1:1 parser with all MIBs in three directories...")
    
    # Get all MIB files
    mib_files = [
      # DOCSIS directory
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/docsis/INET-ADDRESS-MIB.mib",
      
      # Working directory
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/AGENTX-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/BRIDGE-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/CISCO-SMI.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/CISCO-VTP-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/DISMAN-EVENT-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/DISMAN-SCHEDULE-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/DISMAN-SCRIPT-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/EtherLike-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/HCNUM-TC.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/HOST-RESOURCES-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/HOST-RESOURCES-TYPES.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANA-ADDRESS-FAMILY-NUMBERS-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANA-LANGUAGE-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANA-RTPROTO-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IANAifType-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IF-INVERTED-STACK-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IF-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/INET-ADDRESS-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IP-FORWARD-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IP-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/IPV6-FLOW-LABEL-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/NET-SNMP-AGENT-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/NET-SNMP-EXAMPLES-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/NET-SNMP-EXTEND-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/NET-SNMP-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/NET-SNMP-PASS-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/NET-SNMP-TC.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/NET-SNMP-VACM-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/NOTIFICATION-LOG-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/RFC-1215.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/RFC1155-SMI.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/RFC1213-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/RMON-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SCTP-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SMUX-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-COMMUNITY-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-FRAMEWORK-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-MPD-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-NOTIFICATION-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-PROXY-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-TARGET-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-TLS-TM-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-TSM-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-USER-BASED-SM-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-USM-AES-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-USM-DH-OBJECTS-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMP-VIEW-BASED-ACM-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMPv2-CONF.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMPv2-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMPv2-SMI.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMPv2-TC.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/SNMPv2-TM.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/TCP-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/TRANSPORT-ADDRESS-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/TUNNEL-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/UCD-DEMO-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/UCD-DISKIO-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/UCD-DLMOD-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/UCD-IPFWACC-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/UCD-SNMP-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/UDP-MIB.mib",
      
      # Broken directory 
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/DISMAN-EVENT-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/IPV6-ICMP-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/IPV6-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/IPV6-TC.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/IPV6-TCP-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/IPV6-UDP-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/UCD-DEMO-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/UCD-DISKIO-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/UCD-DLMOD-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/UCD-IPFWACC-MIB.mib",
      "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/broken/UCD-SNMP-MIB.mib"
    ]
    
    total_files = length(mib_files)
    IO.puts("📁 Found #{total_files} MIB files to test")
    
    results = %{
      success: [],
      failed: [],
      tokenization_failed: [],
      parsing_failed: [],
      conversion_failed: []
    }
    
    results = Enum.reduce(mib_files, results, fn mib_file, acc ->
      test_mib_file(mib_file, acc)
    end)
    
    print_summary(results, total_files)
  end
  
  defp test_mib_file(mib_file, results) do
    filename = Path.basename(mib_file)
    directory = mib_file |> Path.dirname() |> Path.basename()
    
    IO.write("🔍 Testing #{directory}/#{filename}...")
    
    case File.read(mib_file) do
      {:ok, content} ->
        case SnmpLib.MIB.ActualParser.parse(content) do
          {:ok, parsed_result} ->
            definitions_count = length(Map.get(parsed_result, :definitions, []))
            IO.puts(" ✅ SUCCESS (#{definitions_count} definitions)")
            %{results | success: [{filename, directory, definitions_count} | results.success]}
            
          {:error, reason} ->
            case SnmpLib.MIB.Lexer.tokenize(content) do
              {:ok, _tokens} ->
                # Tokenization worked, parsing failed
                IO.puts(" ❌ PARSING_FAILED: #{inspect(reason)}")
                %{results | parsing_failed: [{filename, directory, reason} | results.parsing_failed]}
              {:error, token_error} ->
                # Tokenization failed
                IO.puts(" ❌ TOKENIZATION_FAILED: #{inspect(token_error)}")
                %{results | tokenization_failed: [{filename, directory, token_error} | results.tokenization_failed]}
            end
        end
        
      {:error, file_error} ->
        IO.puts(" ❌ FILE_READ_FAILED: #{inspect(file_error)}")
        %{results | failed: [{filename, directory, file_error} | results.failed]}
    end
  rescue
    e ->
      filename = Path.basename(mib_file)
      directory = mib_file |> Path.dirname() |> Path.basename()
      IO.puts(" ❌ EXCEPTION: #{inspect(e)}")
      %{results | conversion_failed: [{filename, directory, e} | results.conversion_failed]}
  end
  
  defp print_summary(results, total_files) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("🎯 COMPREHENSIVE 1:1 PARSER TEST RESULTS")
    IO.puts(String.duplicate("=", 80))
    
    success_count = length(results.success)
    failed_count = length(results.failed)
    tokenization_failed_count = length(results.tokenization_failed)
    parsing_failed_count = length(results.parsing_failed)
    conversion_failed_count = length(results.conversion_failed)
    
    IO.puts("📊 SUMMARY:")
    IO.puts("   Total files tested: #{total_files}")
    IO.puts("   ✅ Successful parses: #{success_count}")
    IO.puts("   ❌ File read failures: #{failed_count}")
    IO.puts("   ❌ Tokenization failures: #{tokenization_failed_count}")
    IO.puts("   ❌ Parsing failures: #{parsing_failed_count}")
    IO.puts("   ❌ Conversion failures: #{conversion_failed_count}")
    
    success_rate = Float.round(success_count / total_files * 100, 1)
    IO.puts("   🎯 Success rate: #{success_rate}%")
    
    if success_count > 0 do
      IO.puts("\n✅ SUCCESSFUL PARSES:")
      results.success
      |> Enum.reverse()
      |> Enum.each(fn {filename, directory, defs} ->
        IO.puts("   #{directory}/#{filename} (#{defs} definitions)")
      end)
    end
    
    if parsing_failed_count > 0 do
      IO.puts("\n❌ PARSING FAILURES:")
      results.parsing_failed
      |> Enum.reverse() 
      |> Enum.take(10)  # Show first 10 to avoid spam
      |> Enum.each(fn {filename, directory, reason} ->
        short_reason = case reason do
          {line, module, msg} when is_integer(line) -> "Line #{line}: #{inspect(msg)}"
          _ -> inspect(reason) |> String.slice(0, 100)
        end
        IO.puts("   #{directory}/#{filename}: #{short_reason}")
      end)
      
      if parsing_failed_count > 10 do
        IO.puts("   ... and #{parsing_failed_count - 10} more parsing failures")
      end
    end
    
    if tokenization_failed_count > 0 do
      IO.puts("\n❌ TOKENIZATION FAILURES:")
      results.tokenization_failed
      |> Enum.reverse()
      |> Enum.take(10)  # Show first 10
      |> Enum.each(fn {filename, directory, reason} ->
        short_reason = inspect(reason) |> String.slice(0, 100)
        IO.puts("   #{directory}/#{filename}: #{short_reason}")
      end)
      
      if tokenization_failed_count > 10 do
        IO.puts("   ... and #{tokenization_failed_count - 10} more tokenization failures")
      end
    end
    
    if conversion_failed_count > 0 do
      IO.puts("\n❌ CONVERSION FAILURES:")
      results.conversion_failed
      |> Enum.reverse()
      |> Enum.take(10)  # Show first 10
      |> Enum.each(fn {filename, directory, error} ->
        short_error = inspect(error) |> String.slice(0, 100)
        IO.puts("   #{directory}/#{filename}: #{short_error}")
      end)
      
      if conversion_failed_count > 10 do
        IO.puts("   ... and #{conversion_failed_count - 10} more conversion failures")
      end
    end
    
    IO.puts("\n" <> String.duplicate("=", 80))
    
    cond do
      success_rate >= 90.0 ->
        IO.puts("🎉 EXCELLENT: 1:1 parser shows high compatibility!")
      success_rate >= 70.0 ->
        IO.puts("👍 GOOD: 1:1 parser works well with most MIBs")
      success_rate >= 50.0 ->
        IO.puts("⚠️  MODERATE: 1:1 parser needs improvement")
      true ->
        IO.puts("🚨 POOR: 1:1 parser needs significant work")
    end
  end
end

TestAllMibs.run()