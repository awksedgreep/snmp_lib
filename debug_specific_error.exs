#!/usr/bin/env elixir

defmodule DebugSpecificError do
  def run do
    IO.puts("🔍 Debugging specific parsing error to identify next fix...")
    
    # Let's test one of the failing MIBs to see what exact error we get
    failing_mib = "/Users/mcotner/Documents/elixir/snmp_lib/test/fixtures/mibs/working/CISCO-VTP-MIB.mib"
    
    IO.puts("📄 Testing: #{Path.basename(failing_mib)}")
    
    case File.read(failing_mib) do
      {:ok, content} ->
        IO.puts("✅ File read successfully (#{byte_size(content)} bytes)")
        
        # Test the full parsing process
        IO.puts("\n🔍 Testing full parsing...")
        case SnmpLib.MIB.ActualParser.parse(content) do
          {:ok, result} ->
            def_count = length(result.definitions || [])
            IO.puts("✅ Parse successful! #{def_count} definitions")
            
          {:error, reason} ->
            IO.puts("❌ Parse failed: #{inspect(reason)}")
            
            # Try to get more detailed error information
            case reason do
              {line, module, message} when is_list(message) ->
                msg_str = message |> Enum.map(&to_string/1) |> Enum.join("")
                IO.puts("\n🔍 Detailed error:")
                IO.puts("   Line: #{line}")
                IO.puts("   Module: #{module}")
                IO.puts("   Message: #{msg_str}")
                
              other ->
                IO.puts("\n🔍 Error details: #{inspect(other)}")
            end
        end
        
      {:error, reason} ->
        IO.puts("❌ Failed to read file: #{inspect(reason)}")
    end
  end
end

DebugSpecificError.run()