# SNMP Library Interactive Testing and Performance Benchmarking
# Use these functions in IEx for testing and performance analysis

defmodule SnmpBenchmark do
  @moduledoc """
  Performance benchmarking utilities for SNMP Library.
  
  Usage in IEx:
    iex> encoding_perf = SnmpBenchmark.benchmark_encoding(50_000)
    iex> bulk_perf = SnmpBenchmark.benchmark_bulk_operations(200)
    iex> oid_perf = SnmpBenchmark.benchmark_oid_operations(100_000)
  """

  def benchmark_encoding(iterations \\ 10_000) do
    IO.puts("🔄 Benchmarking encoding/decoding with #{iterations} iterations...")
    
    # Prepare test data
    pdu = SnmpLib.PDU.build_get_request([1, 3, 6, 1, 2, 1, 1, 1, 0], 12345)
    message = SnmpLib.PDU.build_message(pdu, "public", :v2c)

    # Benchmark encoding
    {encode_time, _} = :timer.tc(fn ->
      for _ <- 1..iterations do
        {:ok, _encoded} = SnmpLib.PDU.encode_message(message)
      end
    end)

    # Encode once for decoding benchmark
    {:ok, encoded} = SnmpLib.PDU.encode_message(message)

    # Benchmark decoding
    {decode_time, _} = :timer.tc(fn ->
      for _ <- 1..iterations do
        {:ok, _decoded} = SnmpLib.PDU.decode_message(encoded)
      end
    end)

    result = %{
      iterations: iterations,
      encode_time_ms: encode_time / 1000,
      decode_time_ms: decode_time / 1000,
      encode_ops_per_sec: iterations / (encode_time / 1_000_000),
      decode_ops_per_sec: iterations / (decode_time / 1_000_000),
      encode_time_per_op_us: encode_time / iterations,
      decode_time_per_op_us: decode_time / iterations,
      message_size_bytes: byte_size(encoded)
    }
    
    print_encoding_results(result)
    result
  end

  def benchmark_bulk_operations(device_count \\ 100) do
    IO.puts("🌐 Benchmarking bulk operations with #{device_count} devices...")
    
    devices = for i <- 1..device_count, do: "192.168.1.#{i}"

    # Benchmark sequential operations (will fail but shows timing)
    {seq_time, seq_results} = :timer.tc(fn ->
      Enum.map(devices, fn device ->
        SnmpLib.Manager.get(device, [1, 3, 6, 1, 2, 1, 1, 3, 0], timeout: 100)
      end)
    end)

    # Benchmark concurrent operations
    {conc_time, conc_results} = :timer.tc(fn ->
      devices
      |> Task.async_stream(fn device ->
        SnmpLib.Manager.get(device, [1, 3, 6, 1, 2, 1, 1, 3, 0], timeout: 100)
      end, max_concurrency: 50, timeout: 1000)
      |> Enum.map(fn {:ok, result} -> result end)
    end)

    result = %{
      device_count: device_count,
      sequential: %{
        time_ms: seq_time / 1000,
        ops_per_sec: device_count / (seq_time / 1_000_000),
        success_count: count_successes(seq_results)
      },
      concurrent: %{
        time_ms: conc_time / 1000,
        ops_per_sec: device_count / (conc_time / 1_000_000),
        success_count: count_successes(conc_results),
        speedup: seq_time / conc_time
      }
    }
    
    print_bulk_results(result)
    result
  end

  def benchmark_oid_operations(iterations \\ 100_000) do
    IO.puts("🔍 Benchmarking OID operations with #{iterations} iterations...")
    
    test_oids = [
      "1.3.6.1.2.1.1.1.0",
      "1.3.6.1.4.1.8072.1.3.2.3.1.2.8.110.101.116.45.115.110.109.112",
      "1.3.6.1.2.1.2.2.1.10.1000"
    ]

    results = for oid_string <- test_oids do
      # Benchmark string to list conversion
      {str_to_list_time, _} = :timer.tc(fn ->
        for _ <- 1..iterations do
          {:ok, _list} = SnmpLib.OID.string_to_list(oid_string)
        end
      end)

      # Convert once for reverse benchmark
      {:ok, oid_list} = SnmpLib.OID.string_to_list(oid_string)

      # Benchmark list to string conversion
      {list_to_str_time, _} = :timer.tc(fn ->
        for _ <- 1..iterations do
          {:ok, _string} = SnmpLib.OID.list_to_string(oid_list)
        end
      end)

      %{
        oid: oid_string,
        oid_length: length(oid_list),
        str_to_list_us_per_op: str_to_list_time / iterations,
        list_to_str_us_per_op: list_to_str_time / iterations,
        str_to_list_ops_per_sec: iterations / (str_to_list_time / 1_000_000),
        list_to_str_ops_per_sec: iterations / (list_to_str_time / 1_000_000)
      }
    end

    result = %{
      iterations: iterations,
      oid_benchmarks: results,
      average_str_to_list_us: Enum.reduce(results, 0, &(&1.str_to_list_us_per_op + &2)) / length(results),
      average_list_to_str_us: Enum.reduce(results, 0, &(&1.list_to_str_us_per_op + &2)) / length(results)
    }
    
    print_oid_results(result)
    result
  end

  def benchmark_memory_usage do
    IO.puts("💾 Benchmarking memory usage...")
    
    scenarios = [
      {:small_message, fn -> create_small_test_message() end},
      {:large_bulk_response, fn -> create_large_bulk_response() end},
      {:many_small_messages, fn -> create_many_small_messages(1000) end}
    ]

    results = Enum.map(scenarios, fn {name, scenario_fn} ->
      # Force garbage collection before measurement
      :erlang.garbage_collect()

      {memory_before, _} = :erlang.process_info(self(), :memory)

      result = scenario_fn.()

      {memory_after, _} = :erlang.process_info(self(), :memory)

      memory_used = memory_after - memory_before

      %{
        scenario: name,
        memory_used_bytes: memory_used,
        memory_used_kb: memory_used / 1024,
        result_size: estimate_result_size(result)
      }
    end)
    
    print_memory_results(results)
    results
  end

  # Helper functions for creating test data
  defp create_small_test_message do
    pdu = SnmpLib.PDU.build_get_request([1, 3, 6, 1, 2, 1, 1, 1, 0], 12345)
    message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
    {:ok, encoded} = SnmpLib.PDU.encode_message(message)
    encoded
  end

  defp create_large_bulk_response do
    # Create a large bulk response with many varbinds
    varbinds = for i <- 1..100 do
      {[1, 3, 6, 1, 2, 1, 2, 2, 1, 2, i], :octet_string, "interface#{i}"}
    end
    
    pdu = %{
      type: :get_response,
      request_id: 12345,
      error_status: 0,
      error_index: 0,
      varbinds: varbinds
    }
    
    message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
    {:ok, encoded} = SnmpLib.PDU.encode_message(message)
    encoded
  end

  defp create_many_small_messages(count) do
    for i <- 1..count do
      pdu = SnmpLib.PDU.build_get_request([1, 3, 6, 1, 2, 1, 1, 1, i], i)
      message = SnmpLib.PDU.build_message(pdu, "public", :v2c)
      {:ok, encoded} = SnmpLib.PDU.encode_message(message)
      encoded
    end
  end

  defp estimate_result_size(result) when is_binary(result), do: byte_size(result)
  defp estimate_result_size(result) when is_list(result), do: length(result)
  defp estimate_result_size(_), do: 0

  defp count_successes(results) do
    Enum.count(results, fn
      {:ok, _} -> true
      _ -> false
    end)
  end

  # Pretty printing functions
  defp print_encoding_results(result) do
    IO.puts("\n📊 Encoding/Decoding Performance Results:")
    IO.puts("┌─────────────────┬──────────────┬─────────────────┐")
    IO.puts("│ Operation       │ Ops/Second   │ Time per Op     │")
    IO.puts("├─────────────────┼──────────────┼─────────────────┤")
    IO.puts("│ Encoding        │ #{pad_number(trunc(result.encode_ops_per_sec), 12)} │ #{pad_number(trunc(result.encode_time_per_op_us), 13)}μs │")
    IO.puts("│ Decoding        │ #{pad_number(trunc(result.decode_ops_per_sec), 12)} │ #{pad_number(trunc(result.decode_time_per_op_us), 13)}μs │")
    IO.puts("└─────────────────┴──────────────┴─────────────────┘")
    IO.puts("Message size: #{result.message_size_bytes} bytes")
  end

  defp print_bulk_results(result) do
    IO.puts("\n🌐 Bulk Operations Performance Results:")
    IO.puts("┌──────────────┬─────────────┬─────────────┬──────────────┬──────────────┐")
    IO.puts("│ Device Count │ Sequential  │ Concurrent  │ Success Rate │ Speedup      │")
    IO.puts("├──────────────┼─────────────┼─────────────┼──────────────┼──────────────┤")
    
    seq_success_rate = (result.sequential.success_count / result.device_count) * 100
    conc_success_rate = (result.concurrent.success_count / result.device_count) * 100
    
    IO.puts("│ #{pad_number(result.device_count, 12)} │ #{pad_number(trunc(result.sequential.time_ms), 9)}ms │ #{pad_number(trunc(result.concurrent.time_ms), 9)}ms │ #{pad_number(Float.round(conc_success_rate, 1), 10)}% │ #{pad_number(Float.round(result.concurrent.speedup, 1), 10)}x │")
    IO.puts("└──────────────┴─────────────┴─────────────┴──────────────┴──────────────┘")
    
    if seq_success_rate == 0 and conc_success_rate == 0 do
      IO.puts("Note: All operations failed (expected without real SNMP devices)")
    end
  end

  defp print_oid_results(result) do
    IO.puts("\n🔍 OID Operations Performance Results:")
    IO.puts("┌─────────────────────────────────────┬──────────────┬──────────────┐")
    IO.puts("│ OID                                 │ Str→List μs  │ List→Str μs  │")
    IO.puts("├─────────────────────────────────────┼──────────────┼──────────────┤")
    
    Enum.each(result.oid_benchmarks, fn benchmark ->
      oid_display = if String.length(benchmark.oid) > 35 do
        String.slice(benchmark.oid, 0, 32) <> "..."
      else
        benchmark.oid
      end
      
      IO.puts("│ #{pad_string(oid_display, 35)} │ #{pad_number(Float.round(benchmark.str_to_list_us_per_op, 2), 12)} │ #{pad_number(Float.round(benchmark.list_to_str_us_per_op, 2), 12)} │")
    end)
    
    IO.puts("└─────────────────────────────────────┴──────────────┴──────────────┘")
    IO.puts("Average: Str→List #{Float.round(result.average_str_to_list_us, 2)}μs, List→Str #{Float.round(result.average_list_to_str_us, 2)}μs")
  end

  defp print_memory_results(results) do
    IO.puts("\n💾 Memory Usage Analysis:")
    IO.puts("┌─────────────────────┬──────────────┬─────────────────────────────────┐")
    IO.puts("│ Scenario            │ Memory Used  │ Notes                           │")
    IO.puts("├─────────────────────┼──────────────┼─────────────────────────────────┤")
    
    Enum.each(results, fn result ->
      memory_display = if result.memory_used_kb < 1 do
        "#{result.memory_used_bytes} B"
      else
        "#{Float.round(result.memory_used_kb, 1)} KB"
      end
      
      notes = case result.scenario do
        :small_message -> "Single GET request"
        :large_bulk_response -> "100 interface entries"
        :many_small_messages -> "Batch processing efficiency"
        _ -> "Custom scenario"
      end
      
      IO.puts("│ #{pad_string(to_string(result.scenario), 19)} │ #{pad_string(memory_display, 12)} │ #{pad_string(notes, 31)} │")
    end)
    
    IO.puts("└─────────────────────┴──────────────┴─────────────────────────────────┘")
  end

  defp pad_string(str, width), do: String.pad_trailing(str, width)
  defp pad_number(num, width), do: num |> to_string() |> String.pad_leading(width)
end

# Helper functions for testing the Manager API return formats
defmodule SnmpTesting do
  @moduledoc """
  Helper functions for testing SNMP Manager API return formats.
  
  Usage in IEx:
    iex> SnmpTesting.demo_return_formats()
    iex> SnmpTesting.test_type_preservation()
  """

  def demo_return_formats do
    IO.puts("🎯 SNMP Manager API Return Format Demonstration")
    IO.puts("=" |> String.duplicate(50))
    
    IO.puts("\n📋 Current Return Formats:")
    IO.puts("• GET operations: {:ok, {type, value}} | {:error, reason}")
    IO.puts("• BULK operations: {:ok, [{oid, type, value}, ...]} | {:error, reason}")
    IO.puts("• GET NEXT: {:ok, {next_oid, {type, value}}} | {:error, reason}")
    IO.puts("• SET operations: {:ok, :success} | {:error, reason}")
    IO.puts("• GET MULTI: {:ok, [{oid, type, value}, ...]} | {:error, reason}")
    
    IO.puts("\n🔧 Example Usage (will show errors without real devices):")
    
    # Demonstrate GET format
    IO.puts("\n1. GET operation return format:")
    case SnmpLib.Manager.get("192.168.1.1", [1, 3, 6, 1, 2, 1, 1, 1, 0], timeout: 1000) do
      {:ok, {type, value}} ->
        IO.puts("   Success: type=#{inspect(type)}, value=#{inspect(value)}")
      {:error, reason} ->
        IO.puts("   Expected error: #{inspect(reason)}")
    end
    
    # Demonstrate BULK format
    IO.puts("\n2. BULK operation return format:")
    case SnmpLib.Manager.get_bulk("192.168.1.1", [1, 3, 6, 1, 2, 1, 2, 2], max_repetitions: 3, timeout: 1000) do
      {:ok, results} ->
        IO.puts("   Success: #{length(results)} results")
        Enum.take(results, 2) |> Enum.each(fn {oid, type, value} ->
          IO.puts("     • #{Enum.join(oid, ".")}: #{inspect(value)} (#{type})")
        end)
      {:error, reason} ->
        IO.puts("   Expected error: #{inspect(reason)}")
    end
    
    # Demonstrate GET NEXT format
    IO.puts("\n3. GET NEXT operation return format:")
    case SnmpLib.Manager.get_next("192.168.1.1", [1, 3, 6, 1, 2, 1, 1], timeout: 1000) do
      {:ok, {next_oid, {type, value}}} ->
        IO.puts("   Success: next_oid=#{Enum.join(next_oid, ".")}, type=#{type}, value=#{inspect(value)}")
      {:error, reason} ->
        IO.puts("   Expected error: #{inspect(reason)}")
    end
    
    IO.puts("\n✅ All examples show the new type-preserving return formats!")
  end

  def test_type_preservation do
    IO.puts("🔬 Testing Type Preservation Through Encode/Decode")
    IO.puts("=" |> String.duplicate(50))
    
    # Test different SNMP types
    test_varbinds = [
      {[1, 3, 6, 1, 2, 1, 1, 1, 0], :octet_string, "Test System"},
      {[1, 3, 6, 1, 2, 1, 1, 3, 0], :timeticks, 12345600},
      {[1, 3, 6, 1, 2, 1, 2, 2, 1, 10, 1], :counter32, 987654321},
      {[1, 3, 6, 1, 2, 1, 2, 2, 1, 5, 1], :gauge32, 100000000},
      {[1, 3, 6, 1, 2, 1, 1, 2, 0], :object_identifier, [1, 3, 6, 1, 4, 1, 9]},
      {[1, 3, 6, 1, 2, 1, 4, 20, 1, 1, 1], :ip_address, <<192, 168, 1, 1>>}
    ]
    
    # Create a response PDU
    pdu = %{
      type: :get_response,
      request_id: 12345,
      error_status: 0,
      error_index: 0,
      varbinds: test_varbinds
    }
    
    message = %{
      version: 1,  # SNMPv2c
      community: "public",
      pdu: pdu
    }
    
    IO.puts("\nOriginal varbinds:")
    Enum.with_index(test_varbinds, 1) |> Enum.each(fn {{oid, type, value}, index} ->
      IO.puts("  #{index}. #{Enum.join(oid, ".")}: #{inspect(value)} (#{type})")
    end)
    
    # Encode and decode
    case SnmpLib.PDU.encode_message(message) do
      {:ok, encoded} ->
        IO.puts("\n✅ Encoding successful: #{byte_size(encoded)} bytes")
        
        case SnmpLib.PDU.decode_message(encoded) do
          {:ok, decoded} ->
            IO.puts("✅ Decoding successful")
            
            decoded_varbinds = decoded.pdu.varbinds
            IO.puts("\nDecoded varbinds:")
            Enum.with_index(decoded_varbinds, 1) |> Enum.each(fn {{oid, type, value}, index} ->
              IO.puts("  #{index}. #{Enum.join(oid, ".")}: #{inspect(value)} (#{type})")
            end)
            
            # Check type preservation
            types_match = Enum.zip(test_varbinds, decoded_varbinds)
            |> Enum.all?(fn {{_oid1, type1, _val1}, {_oid2, type2, _val2}} ->
              type1 == type2
            end)
            
            if types_match do
              IO.puts("\n🎉 Type preservation: PERFECT!")
            else
              IO.puts("\n⚠️  Type preservation: Some types changed")
            end
            
          {:error, reason} ->
            IO.puts("❌ Decoding failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("❌ Encoding failed: #{inspect(reason)}")
    end
  end
end

# Print welcome message
IO.puts """

🎯 SNMP Library Interactive Environment Loaded!

Available benchmark functions:
  • SnmpBenchmark.benchmark_encoding(iterations)
  • SnmpBenchmark.benchmark_bulk_operations(device_count)  
  • SnmpBenchmark.benchmark_oid_operations(iterations)
  • SnmpBenchmark.benchmark_memory_usage()

Available testing functions:
  • SnmpTesting.demo_return_formats()
  • SnmpTesting.test_type_preservation()

Quick start:
  iex> SnmpBenchmark.benchmark_encoding(10_000)
  iex> SnmpTesting.demo_return_formats()

"""
