#!/usr/bin/env elixir

# Test the new Erlang-faithful tokenizer
alias SnmpLib.MIB.LexerErlangPort

# Simple test MIB
simple_mib = """
TestMib DEFINITIONS ::= BEGIN
END
"""

IO.puts("Testing simple MIB...")
case LexerErlangPort.tokenize(simple_mib) do
  {:ok, tokens} ->
    IO.puts("Success with #{length(tokens)} tokens:")
    Enum.each(tokens, &IO.inspect/1)
  {:error, reason} ->
    IO.puts("Error: #{reason}")
end

# Test with SNMPv2-TC
IO.puts("\n\nTesting SNMPv2-TC MIB...")
snmpv2_tc_content = File.read!("test/fixtures/mibs/docsis/SNMPv2-TC")

case LexerErlangPort.tokenize(snmpv2_tc_content) do
  {:ok, tokens} ->
    IO.puts("Success with #{length(tokens)} tokens from SNMPv2-TC")
    # Show first few tokens
    tokens |> Enum.take(10) |> Enum.each(&IO.inspect/1)
    IO.puts("...")
    IO.puts("Last few tokens:")
    tokens |> Enum.take(-5) |> Enum.each(&IO.inspect/1)
  {:error, reason} ->
    IO.puts("Error: #{reason}")
end