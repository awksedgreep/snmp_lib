defmodule SnmpLib.TargetParsingTest do
  use ExUnit.Case, async: true
  alias SnmpLib.Utils

  doctest SnmpLib.Utils

  describe "parse_target/1" do
    test "parses IP address with port" do
      assert {:ok, %{host: {192, 168, 1, 1}, port: 161}} = Utils.parse_target("192.168.1.1:161")
      assert {:ok, %{host: {10, 0, 0, 1}, port: 162}} = Utils.parse_target("10.0.0.1:162")
      assert {:ok, %{host: {127, 0, 0, 1}, port: 8080}} = Utils.parse_target("127.0.0.1:8080")
    end

    test "parses IP address without port (uses default 161)" do
      assert {:ok, %{host: {192, 168, 1, 1}, port: 161}} = Utils.parse_target("192.168.1.1")
      assert {:ok, %{host: {10, 0, 0, 1}, port: 161}} = Utils.parse_target("10.0.0.1")
      assert {:ok, %{host: {172, 16, 0, 1}, port: 161}} = Utils.parse_target("172.16.0.1")
    end

    test "parses hostname with port" do
      assert {:ok, %{host: "device.local", port: 162}} = Utils.parse_target("device.local:162")
      assert {:ok, %{host: "router.example.com", port: 8161}} = Utils.parse_target("router.example.com:8161")
      assert {:ok, %{host: "localhost", port: 1161}} = Utils.parse_target("localhost:1161")
    end

    test "parses hostname without port (uses default 161)" do
      assert {:ok, %{host: "device.local", port: 161}} = Utils.parse_target("device.local")
      assert {:ok, %{host: "router.example.com", port: 161}} = Utils.parse_target("router.example.com")
      assert {:ok, %{host: "localhost", port: 161}} = Utils.parse_target("localhost")
    end

    test "parses IP tuple (uses default port 161)" do
      assert {:ok, %{host: {192, 168, 1, 1}, port: 161}} = Utils.parse_target({192, 168, 1, 1})
      assert {:ok, %{host: {10, 0, 0, 1}, port: 161}} = Utils.parse_target({10, 0, 0, 1})
      assert {:ok, %{host: {0, 0, 0, 0}, port: 161}} = Utils.parse_target({0, 0, 0, 0})
      assert {:ok, %{host: {255, 255, 255, 255}, port: 161}} = Utils.parse_target({255, 255, 255, 255})
    end

    test "parses already parsed map with host and port" do
      assert {:ok, %{host: {192, 168, 1, 1}, port: 161}} = 
        Utils.parse_target(%{host: "192.168.1.1", port: 161})
      
      assert {:ok, %{host: "device.local", port: 162}} = 
        Utils.parse_target(%{host: "device.local", port: 162})
      
      assert {:ok, %{host: {10, 0, 0, 1}, port: 8080}} = 
        Utils.parse_target(%{host: {10, 0, 0, 1}, port: 8080})
    end

    test "parses already parsed map with host only (uses default port 161)" do
      assert {:ok, %{host: {192, 168, 1, 1}, port: 161}} = 
        Utils.parse_target(%{host: "192.168.1.1"})
      
      assert {:ok, %{host: "device.local", port: 161}} = 
        Utils.parse_target(%{host: "device.local"})
      
      assert {:ok, %{host: {10, 0, 0, 1}, port: 161}} = 
        Utils.parse_target(%{host: {10, 0, 0, 1}})
    end

    test "handles edge case ports correctly" do
      assert {:ok, %{host: {192, 168, 1, 1}, port: 1}} = Utils.parse_target("192.168.1.1:1")
      assert {:ok, %{host: {192, 168, 1, 1}, port: 65535}} = Utils.parse_target("192.168.1.1:65535")
    end

    test "returns error for invalid port numbers" do
      assert {:error, {:invalid_port, "0"}} = Utils.parse_target("192.168.1.1:0")
      assert {:error, {:invalid_port, "99999"}} = Utils.parse_target("192.168.1.1:99999")
      assert {:error, {:invalid_port, "65536"}} = Utils.parse_target("192.168.1.1:65536")
      assert {:error, {:invalid_port, "-1"}} = Utils.parse_target("192.168.1.1:-1")
    end

    test "returns error for invalid port format" do
      assert {:error, {:invalid_port_format, "abc"}} = Utils.parse_target("192.168.1.1:abc")
      assert {:error, {:invalid_port_format, "161.5"}} = Utils.parse_target("192.168.1.1:161.5")
      assert {:error, {:invalid_port_format, "161x"}} = Utils.parse_target("192.168.1.1:161x")
      assert {:error, {:invalid_port_format, ""}} = Utils.parse_target("192.168.1.1:")
    end

    test "returns error for invalid IP tuple" do
      assert {:error, {:invalid_ip_tuple, {256, 1, 1, 1}}} = Utils.parse_target({256, 1, 1, 1})
      assert {:error, {:invalid_ip_tuple, {192, 256, 1, 1}}} = Utils.parse_target({192, 256, 1, 1})
      assert {:error, {:invalid_ip_tuple, {192, 168, 256, 1}}} = Utils.parse_target({192, 168, 256, 1})
      assert {:error, {:invalid_ip_tuple, {192, 168, 1, 256}}} = Utils.parse_target({192, 168, 1, 256})
      assert {:error, {:invalid_ip_tuple, {-1, 168, 1, 1}}} = Utils.parse_target({-1, 168, 1, 1})
    end

    test "returns error for invalid target format" do
      assert {:error, {:invalid_target_format, nil}} = Utils.parse_target(nil)
      assert {:error, {:invalid_target_format, 123}} = Utils.parse_target(123)
      assert {:error, {:invalid_target_format, []}} = Utils.parse_target([])
      assert {:error, {:invalid_target_format, %{}}} = Utils.parse_target(%{})
      assert {:error, {:invalid_target_format, %{invalid: "key"}}} = Utils.parse_target(%{invalid: "key"})
    end

    test "returns error for invalid map with invalid port" do
      assert {:error, {:invalid_port, "99999"}} = 
        Utils.parse_target(%{host: "192.168.1.1", port: 99999})
      
      assert {:error, {:invalid_port, "0"}} = 
        Utils.parse_target(%{host: "192.168.1.1", port: 0})
      
      assert {:error, {:invalid_port, "-5"}} = 
        Utils.parse_target(%{host: "192.168.1.1", port: -5})
    end

    test "handles IPv6-like strings as hostnames" do
      # IPv6 addresses are not parsed as IP tuples, they remain as hostnames
      assert {:ok, %{host: "::1", port: 161}} = Utils.parse_target("::1")
      assert {:ok, %{host: "2001:db8::1", port: 161}} = Utils.parse_target("2001:db8::1")
    end

    test "handles complex hostnames" do
      assert {:ok, %{host: "complex-hostname.sub.domain.com", port: 161}} = 
        Utils.parse_target("complex-hostname.sub.domain.com")
      
      assert {:ok, %{host: "host_with_underscores", port: 8161}} = 
        Utils.parse_target("host_with_underscores:8161")
    end

    test "maintains consistency with examples in module documentation" do
      # These should match the examples in the @doc string
      assert {:ok, %{host: {192, 168, 1, 1}, port: 161}} = Utils.parse_target("192.168.1.1:161")
      assert {:ok, %{host: {192, 168, 1, 1}, port: 161}} = Utils.parse_target("192.168.1.1")
      assert {:ok, %{host: "device.local", port: 162}} = Utils.parse_target("device.local:162")
      assert {:ok, %{host: "device.local", port: 161}} = Utils.parse_target("device.local")
      assert {:ok, %{host: {192, 168, 1, 1}, port: 161}} = Utils.parse_target({192, 168, 1, 1})
      assert {:ok, %{host: {192, 168, 1, 1}, port: 161}} = Utils.parse_target(%{host: "192.168.1.1", port: 161})
      assert {:error, {:invalid_port, "99999"}} = Utils.parse_target("invalid:99999")
    end
  end
end