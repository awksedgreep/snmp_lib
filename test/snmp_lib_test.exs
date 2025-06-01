defmodule SnmpLibTest do
  use ExUnit.Case
  doctest SnmpLib

  test "returns version information" do
    version = SnmpLib.version()
    assert is_binary(version)
    assert version != ""
  end
end
