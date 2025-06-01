defmodule SnmpLib.PerformanceTest do
  @moduledoc """
  Basic performance test to verify optimizations work.
  Run with: mix test test/performance_test.exs
  """
  
  use ExUnit.Case, async: false
  
  alias SnmpLib.PDU

  @tag :performance
  test "encoding performance is reasonable" do
    # Simple performance check - encoding should complete quickly
    oid = [1, 3, 6, 1, 2, 1, 1, 1, 0]
    pdu = PDU.build_get_request(oid, 12345)
    message = PDU.build_message(pdu, "public", :v2c)
    
    {time_microseconds, {:ok, _encoded}} = :timer.tc(fn ->
      PDU.encode_message(message)
    end)
    
    # Should encode in less than 1ms (1000 microseconds) on any reasonable machine
    assert time_microseconds < 1000, "Encoding took #{time_microseconds} microseconds, expected < 1000"
  end

  @tag :performance
  test "batch encoding performance" do
    # Test encoding multiple messages quickly
    messages = for i <- 1..100 do
      oid = [1, 3, 6, 1, 2, 1, 1, 1, i]
      pdu = PDU.build_get_request(oid, i)
      PDU.build_message(pdu, "public-#{i}", :v2c)
    end
    
    {time_microseconds, results} = :timer.tc(fn ->
      Enum.map(messages, &PDU.encode_message/1)
    end)
    
    # All should succeed
    assert Enum.all?(results, fn
      {:ok, binary} when is_binary(binary) -> true
      _ -> false
    end)
    
    # Should encode 100 messages in less than 100ms
    assert time_microseconds < 100_000, "Batch encoding took #{time_microseconds} microseconds, expected < 100,000"
    
    avg_time = time_microseconds / 100
    IO.puts("Average encoding time per message: #{Float.round(avg_time, 2)} microseconds")
  end

  @tag :performance
  test "round-trip performance" do
    # Test encode -> decode performance
    oid = [1, 3, 6, 1, 2, 1, 1, 1, 0]
    pdu = PDU.build_get_request(oid, 54321)
    message = PDU.build_message(pdu, "test-community", :v2c)
    
    {:ok, encoded} = PDU.encode_message(message)
    
    {time_microseconds, {:ok, _decoded}} = :timer.tc(fn ->
      PDU.decode_message(encoded)
    end)
    
    # Should decode in less than 1ms
    assert time_microseconds < 1000, "Decoding took #{time_microseconds} microseconds, expected < 1000"
  end
end