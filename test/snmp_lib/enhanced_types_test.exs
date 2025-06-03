defmodule SnmpLib.EnhancedTypesTest do
  use ExUnit.Case, async: true
  doctest SnmpLib.Types
  
  alias SnmpLib.Types
  
  @moduletag :enhanced_types
  
  describe "encode_value/2 with automatic type inference" do
    test "infers string type for text" do
      assert {:ok, {:string, "hello"}} = Types.encode_value("hello")
      assert {:ok, {:string, "test message"}} = Types.encode_value("test message")
      assert {:ok, {:string, ""}} = Types.encode_value("")
    end
    
    test "infers integer types for numbers" do
      assert {:ok, {:unsigned32, 42}} = Types.encode_value(42)
      assert {:ok, {:unsigned32, 0}} = Types.encode_value(0)
      assert {:ok, {:integer, -42}} = Types.encode_value(-42)
      assert {:ok, {:counter64, 5_000_000_000}} = Types.encode_value(5_000_000_000)
    end
    
    test "infers IP address type for IP strings" do
      assert {:ok, {:ip_address, {192, 168, 1, 1}}} = Types.encode_value("192.168.1.1")
      assert {:ok, {:ip_address, {127, 0, 0, 1}}} = Types.encode_value("127.0.0.1")
      assert {:ok, {:ip_address, {0, 0, 0, 0}}} = Types.encode_value("0.0.0.0")
    end
    
    test "infers IP address type for IP tuples" do
      assert {:ok, {:ip_address, {192, 168, 1, 1}}} = Types.encode_value({192, 168, 1, 1})
      assert {:ok, {:ip_address, {10, 0, 0, 1}}} = Types.encode_value({10, 0, 0, 1})
    end
    
    test "infers object identifier type for OID lists" do
      assert {:ok, {:object_identifier, [1, 3, 6, 1, 2, 1]}} = Types.encode_value([1, 3, 6, 1, 2, 1])
      assert {:ok, {:object_identifier, [1, 3, 6, 1, 4, 1, 9]}} = Types.encode_value([1, 3, 6, 1, 4, 1, 9])
    end
    
    test "infers boolean type" do
      assert {:ok, {:boolean, true}} = Types.encode_value(true)
      assert {:ok, {:boolean, false}} = Types.encode_value(false)
    end
    
    test "infers null type" do
      assert {:ok, {:null, nil}} = Types.encode_value(:null)
      assert {:ok, {:null, nil}} = Types.encode_value(nil)
    end
    
    test "handles octet strings (binary data)" do
      binary_data = <<0xDE, 0xAD, 0xBE, 0xEF>>
      assert {:ok, {:octet_string, ^binary_data}} = Types.encode_value(binary_data)
    end
  end
  
  describe "encode_value/2 with explicit type specification" do
    test "encodes with explicit string type" do
      assert {:ok, {:string, "hello"}} = Types.encode_value("hello", type: :string)
      assert {:ok, {:string, "42"}} = Types.encode_value("42", type: :string)
    end
    
    test "encodes with explicit integer types" do
      assert {:ok, {:counter32, 100}} = Types.encode_value(100, type: :counter32)
      assert {:ok, {:gauge32, 200}} = Types.encode_value(200, type: :gauge32)
      assert {:ok, {:timeticks, 300}} = Types.encode_value(300, type: :timeticks)
      assert {:ok, {:counter64, 400}} = Types.encode_value(400, type: :counter64)
      assert {:ok, {:unsigned32, 500}} = Types.encode_value(500, type: :unsigned32)
    end
    
    test "encodes IP address from string with explicit type" do
      assert {:ok, {:ip_address, {192, 168, 1, 1}}} = Types.encode_value("192.168.1.1", type: :ip_address)
      assert {:ok, {:ip_address, {10, 0, 0, 1}}} = Types.encode_value("10.0.0.1", type: :ip_address)
    end
    
    test "encodes OID from string with explicit type" do
      assert {:ok, {:object_identifier, [1, 3, 6, 1, 2, 1]}} = Types.encode_value("1.3.6.1.2.1", type: :object_identifier)
      assert {:ok, {:oid, [1, 3, 6, 1, 4, 1, 9]}} = Types.encode_value("1.3.6.1.4.1.9", type: :oid)
    end
    
    test "validates values with explicit types" do
      assert {:error, :out_of_range} = Types.encode_value(-1, type: :counter32)
      assert {:error, :out_of_range} = Types.encode_value(4_294_967_296, type: :counter32)
      assert {:error, :invalid_format} = Types.encode_value("not.an.ip", type: :ip_address)
    end
    
    test "handles type normalization" do
      assert {:ok, {:string, "test"}} = Types.encode_value("test", type: "string")
      assert {:ok, {:counter32, 42}} = Types.encode_value(42, type: "counter32")
      assert {:ok, {:object_identifier, [1, 3, 6]}} = Types.encode_value([1, 3, 6], type: "object_identifier")
    end
  end
  
  describe "infer_type/1" do
    test "infers types for integers" do
      assert :unsigned32 = Types.infer_type(42)
      assert :unsigned32 = Types.infer_type(0)
      assert :integer = Types.infer_type(-42)
      assert :counter64 = Types.infer_type(5_000_000_000)
    end
    
    test "infers types for strings" do
      assert :string = Types.infer_type("hello world")
      assert :string = Types.infer_type("test")
      assert :ip_address = Types.infer_type("192.168.1.1")
      assert :ip_address = Types.infer_type("127.0.0.1")
    end
    
    test "infers types for lists" do
      assert :object_identifier = Types.infer_type([1, 3, 6, 1, 2, 1])
      assert :object_identifier = Types.infer_type([1, 3, 6])
      assert :unknown = Types.infer_type(["not", "an", "oid"])
      assert :unknown = Types.infer_type([1])  # Too short for OID
    end
    
    test "infers types for other values" do
      assert :boolean = Types.infer_type(true)
      assert :boolean = Types.infer_type(false)
      assert :null = Types.infer_type(:null)
      assert :null = Types.infer_type(nil)
      assert :ip_address = Types.infer_type({192, 168, 1, 1})
      assert :unknown = Types.infer_type({300, 300, 300, 300})  # Invalid IP tuple
    end
  end
  
  describe "decode_value/1" do
    test "decodes strings consistently" do
      assert "hello" = Types.decode_value({:string, "hello"})
      assert "test" = Types.decode_value({:string, ~c"test"})  # Handle charlists
      assert "world" = Types.decode_value({:octet_string, "world"})
      assert "elixir" = Types.decode_value({:octet_string, ~c"elixir"})
    end
    
    test "decodes integers" do
      assert 42 = Types.decode_value({:integer, 42})
      assert 100 = Types.decode_value({:unsigned32, 100})
      assert 200 = Types.decode_value({:counter32, 200})
      assert 300 = Types.decode_value({:gauge32, 300})
      assert 400 = Types.decode_value({:timeticks, 400})
      assert 500 = Types.decode_value({:counter64, 500})
    end
    
    test "decodes IP addresses to strings" do
      assert "192.168.1.1" = Types.decode_value({:ip_address, {192, 168, 1, 1}})
      assert "127.0.0.1" = Types.decode_value({:ip_address, <<127, 0, 0, 1>>})
      assert "10.0.0.1" = Types.decode_value({:ip_address, {10, 0, 0, 1}})
    end
    
    test "decodes OIDs" do
      assert [1, 3, 6, 1, 2, 1] = Types.decode_value({:object_identifier, [1, 3, 6, 1, 2, 1]})
      assert [1, 3, 6, 1, 4, 1, 9] = Types.decode_value({:oid, [1, 3, 6, 1, 4, 1, 9]})
    end
    
    test "decodes other types" do
      assert true = Types.decode_value({:boolean, true})
      assert false == Types.decode_value({:boolean, false})
      assert nil == Types.decode_value({:null, nil})
      assert <<1, 2, 3>> = Types.decode_value({:opaque, <<1, 2, 3>>})
    end
    
    test "decodes exception values" do
      assert :no_such_object = Types.decode_value({:no_such_object, nil})
      assert :no_such_instance = Types.decode_value({:no_such_instance, nil})
      assert :end_of_mib_view = Types.decode_value({:end_of_mib_view, nil})
    end
    
    test "passes through untyped values" do
      assert 42 = Types.decode_value(42)
      assert "test" = Types.decode_value("test")
      assert :atom = Types.decode_value(:atom)
    end
  end
  
  describe "parse_ip_address/1" do
    test "parses valid IP addresses" do
      assert {:ok, {192, 168, 1, 1}} = Types.parse_ip_address("192.168.1.1")
      assert {:ok, {127, 0, 0, 1}} = Types.parse_ip_address("127.0.0.1")
      assert {:ok, {10, 0, 0, 1}} = Types.parse_ip_address("10.0.0.1")
      assert {:ok, {0, 0, 0, 0}} = Types.parse_ip_address("0.0.0.0")
      assert {:ok, {255, 255, 255, 255}} = Types.parse_ip_address("255.255.255.255")
    end
    
    test "rejects invalid IP addresses" do
      assert {:error, :invalid_format} = Types.parse_ip_address("invalid")
      assert {:error, :invalid_format} = Types.parse_ip_address("192.168.1.1.1")
      assert {:error, :invalid_format} = Types.parse_ip_address("256.1.1.1")
      assert {:error, :invalid_format} = Types.parse_ip_address("192.168.-1.1")
      # Note: inet.parse_address is lenient with incomplete addresses
      # so "192.168.1" might be valid - let's test actual invalid formats
      assert {:error, :invalid_format} = Types.parse_ip_address("not.an.ip.address")
    end
    
    test "rejects IPv6 addresses" do
      assert {:error, :not_ipv4} = Types.parse_ip_address("::1")
      assert {:error, :not_ipv4} = Types.parse_ip_address("2001:db8::1")
    end
    
    test "rejects non-string input" do
      assert {:error, :invalid_input} = Types.parse_ip_address(123)
      assert {:error, :invalid_input} = Types.parse_ip_address({192, 168, 1, 1})
    end
  end
  
  describe "type validation for new types" do
    test "validates unsigned32" do
      assert :ok = Types.validate_unsigned32(0)
      assert :ok = Types.validate_unsigned32(4_294_967_295)
      assert {:error, :out_of_range} = Types.validate_unsigned32(-1)
      assert {:error, :out_of_range} = Types.validate_unsigned32(4_294_967_296)
      assert {:error, :not_integer} = Types.validate_unsigned32("42")
    end
  end
  
  describe "error handling" do
    test "handles encoding errors gracefully" do
      assert {:error, :cannot_infer_type} = Types.encode_value(%{complex: :structure})
      assert {:error, :out_of_range} = Types.encode_value(-1, type: :counter32)
      assert {:error, :encoding_failed} = Types.encode_value("string", type: :integer)
    end
    
    test "handles unknown types" do
      assert {:error, :unsupported_type} = Types.coerce_value(:unknown_type, "value")
    end
  end
  
  describe "integration with existing coerce_value/2" do
    test "maintains backward compatibility" do
      assert {:ok, {:counter32, 42}} = Types.coerce_value(:counter32, 42)
      assert {:ok, {:string, "test"}} = Types.coerce_value(:string, "test")
      assert {:ok, :null} = Types.coerce_value(:null, nil)
    end
    
    test "supports new types in coerce_value" do
      assert {:ok, {:unsigned32, 42}} = Types.coerce_value(:unsigned32, 42)
      assert {:ok, {:octet_string, "test"}} = Types.coerce_value(:octet_string, "test")
      assert {:ok, {:object_identifier, [1, 3, 6]}} = Types.coerce_value(:object_identifier, [1, 3, 6])
      assert {:ok, {:boolean, true}} = Types.coerce_value(:boolean, true)
      assert {:ok, {:ip_address, {192, 168, 1, 1}}} = Types.coerce_value(:ip_address, "192.168.1.1")
    end
  end
  
  describe "type normalization" do
    test "normalizes string type names" do
      assert :unsigned32 = Types.normalize_type("unsigned32")
      assert :boolean = Types.normalize_type("boolean")
      assert :string = Types.normalize_type("octet_string")
      assert :object_identifier = Types.normalize_type("object_identifier")
    end
  end
  
  describe "type classification" do
    test "identifies numeric types" do
      assert Types.is_numeric_type?(:unsigned32)
      assert Types.is_numeric_type?(:counter32)
      assert Types.is_numeric_type?(:integer)
      refute Types.is_numeric_type?(:string)
      refute Types.is_numeric_type?(:boolean)
    end
    
    test "identifies binary types" do
      assert Types.is_binary_type?(:string)
      assert Types.is_binary_type?(:octet_string)
      assert Types.is_binary_type?(:opaque)
      refute Types.is_binary_type?(:integer)
      refute Types.is_binary_type?(:boolean)
    end
    
    test "provides max/min values for new types" do
      assert 4_294_967_295 = Types.max_value(:unsigned32)
      assert 0 = Types.min_value(:unsigned32)
    end
  end
  
  describe "round-trip encoding/decoding" do
    test "round-trip for strings" do
      original = "hello world"
      {:ok, {type, encoded}} = Types.encode_value(original)
      decoded = Types.decode_value({type, encoded})
      assert original == decoded
    end
    
    test "round-trip for integers" do
      original = 42
      {:ok, {type, encoded}} = Types.encode_value(original)
      decoded = Types.decode_value({type, encoded})
      assert original == decoded
    end
    
    test "round-trip for IP addresses" do
      original = "192.168.1.1"
      {:ok, {type, encoded}} = Types.encode_value(original)
      decoded = Types.decode_value({type, encoded})
      assert original == decoded
    end
    
    test "round-trip for OIDs" do
      original = [1, 3, 6, 1, 2, 1]
      {:ok, {type, encoded}} = Types.encode_value(original)
      decoded = Types.decode_value({type, encoded})
      assert original == decoded
    end
    
    test "round-trip for booleans" do
      for original <- [true, false] do
        {:ok, {type, encoded}} = Types.encode_value(original)
        decoded = Types.decode_value({type, encoded})
        assert original == decoded
      end
    end
  end
  
  describe "edge cases and complex scenarios" do
    test "handles empty values" do
      assert {:ok, {:string, ""}} = Types.encode_value("")
      assert "" = Types.decode_value({:string, ""})
    end
    
    test "handles large numbers" do
      large_number = 18_446_744_073_709_551_615  # Max uint64
      {:ok, {type, encoded}} = Types.encode_value(large_number)
      assert type == :counter64
      assert encoded == large_number
    end
    
    test "handles boundary values" do
      # Test boundary conditions for each type
      assert {:ok, {:unsigned32, 0}} = Types.encode_value(0, type: :unsigned32)
      assert {:ok, {:unsigned32, 4_294_967_295}} = Types.encode_value(4_294_967_295, type: :unsigned32)
      assert {:error, :out_of_range} = Types.encode_value(-1, type: :unsigned32)
      assert {:error, :out_of_range} = Types.encode_value(4_294_967_296, type: :unsigned32)
    end
    
    test "handles type inference ambiguity" do
      # Test cases where type inference might be ambiguous
      assert :string = Types.infer_type("hello123")  # String that contains numbers
      assert :unsigned32 = Types.infer_type(123)  # Number that could be string
      assert :string = Types.infer_type("not.an.ip.address")  # String that looks a bit like IP but isn't
    end
  end
end