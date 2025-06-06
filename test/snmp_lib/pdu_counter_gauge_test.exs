defmodule SnmpLib.PDU.CounterGaugeTest do
  use ExUnit.Case, async: true
  
  alias SnmpLib.PDU
  
  describe "Counter32 and Gauge32 encoding" do
    test "Counter32 with atom type encodes correctly" do
      pdu = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :counter32, 1000000}])
      msg = PDU.build_message(pdu, "public", :v1)
      {:ok, encoded} = PDU.encode_message(msg)
      hex = Base.encode16(encoded)
      
      # Should contain Counter32 tag (0x41) and value (0x0F4240 = 1000000)
      assert String.contains?(hex, "41030F4240")
      # Should NOT contain NULL encoding
      refute String.contains?(hex, "050000")
    end
    
    test "Gauge32 with atom type encodes correctly" do
      pdu = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :gauge32, 1000000}])
      msg = PDU.build_message(pdu, "public", :v1)
      {:ok, encoded} = PDU.encode_message(msg)
      hex = Base.encode16(encoded)
      
      # Should contain Gauge32 tag (0x42) and value (0x0F4240 = 1000000)
      assert String.contains?(hex, "42030F4240")
      # Should NOT contain NULL encoding
      refute String.contains?(hex, "050000")
    end
    
    test "Counter32 with tuple format still works" do
      pdu = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :auto, {:counter32, 1000000}}])
      msg = PDU.build_message(pdu, "public", :v1)
      {:ok, encoded} = PDU.encode_message(msg)
      hex = Base.encode16(encoded)
      
      # Should contain Counter32 tag (0x41) and value
      assert String.contains?(hex, "41030F4240")
    end
    
    test "Gauge32 with tuple format still works" do
      pdu = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :auto, {:gauge32, 1000000}}])
      msg = PDU.build_message(pdu, "public", :v1)
      {:ok, encoded} = PDU.encode_message(msg)
      hex = Base.encode16(encoded)
      
      # Should contain Gauge32 tag (0x42) and value
      assert String.contains?(hex, "42030F4240")
    end
    
    test "TimeTicks with atom type encodes correctly" do
      pdu = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :timeticks, 1000000}])
      msg = PDU.build_message(pdu, "public", :v1)
      {:ok, encoded} = PDU.encode_message(msg)
      hex = Base.encode16(encoded)
      
      # Should contain TimeTicks tag (0x43) and value
      assert String.contains?(hex, "43030F4240")
      refute String.contains?(hex, "050000")
    end
    
    test "Counter64 with atom type encodes correctly" do
      pdu = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :counter64, 1000000}])
      msg = PDU.build_message(pdu, "public", :v1)
      {:ok, encoded} = PDU.encode_message(msg)
      hex = Base.encode16(encoded)
      
      # Should contain Counter64 tag (0x46) and 8-byte value
      assert String.contains?(hex, "460800000000000F4240")
      refute String.contains?(hex, "050000")
    end
    
    test "different Counter32 values encode correctly" do
      test_values = [0, 1, 127, 128, 255, 256, 65535, 65536, 4294967295]
      
      Enum.each(test_values, fn value ->
        pdu = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :counter32, value}])
        msg = PDU.build_message(pdu, "public", :v1)
        {:ok, encoded} = PDU.encode_message(msg)
        hex = Base.encode16(encoded)
        
        # Should contain Counter32 tag (0x41) and NOT be NULL encoding (tag 05 with length 00)
        assert String.contains?(hex, "41")
        refute String.contains?(hex, "050000")  
      end)
    end
    
    test "different Gauge32 values encode correctly" do
      test_values = [0, 1, 127, 128, 255, 256, 65535, 65536, 4294967295]
      
      Enum.each(test_values, fn value ->
        pdu = PDU.build_response(1, 0, 0, [{[1,3,6,1,2,1,2,2,1,10,1], :gauge32, value}])
        msg = PDU.build_message(pdu, "public", :v1)
        {:ok, encoded} = PDU.encode_message(msg)
        hex = Base.encode16(encoded)
        
        # Should contain Gauge32 tag (0x42) and NOT be NULL encoding (tag 05 with length 00)
        assert String.contains?(hex, "42")
        refute String.contains?(hex, "050000")  
      end)
    end
  end
end
