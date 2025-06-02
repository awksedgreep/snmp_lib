#!/usr/bin/env elixir

# Test actual parser with DOCSIS MIB to reproduce the error

Code.require_file("lib/snmp_lib/mib/lexer.ex")
Code.require_file("lib/snmp_lib/mib/parser_port.ex")

alias SnmpLib.MIB.Lexer
alias SnmpLib.MIB.ParserPort

# Read just the first part of the DOCSIS MIB to find the problematic constructs
mib_content = File.read!("test/fixtures/mibs/docsis/DOCS-CABLE-DEVICE-MIB")
lines = String.split(mib_content, "\n")

# Get a snippet that contains MODULE-IDENTITY and OID assignment
snippet_start = Enum.find_index(lines, fn line -> String.contains?(line, "docsDev MODULE-IDENTITY") end)

if snippet_start do
  # Take lines from MODULE-IDENTITY to the end of its definition
  snippet_lines = Enum.slice(lines, snippet_start, 10)
  snippet = Enum.join(snippet_lines, "\n")
  
  IO.puts("=== Testing MODULE-IDENTITY snippet ===")
  IO.puts(snippet)
  IO.puts("=" <> String.duplicate("=", 80))
  
  case Lexer.tokenize(snippet) do
    {:ok, tokens} ->
      IO.puts("✓ Tokenization successful")
      IO.puts("Token count: #{length(tokens)}")
      
      # Show all tokens for debugging
      IO.puts("\nAll tokens:")
      Enum.with_index(tokens, 1)
      |> Enum.each(fn {token, index} ->
        IO.puts("#{index}. #{inspect(token)}")
      end)
      
      # Now try to parse this with various parser functions
      IO.puts("\n=== Attempting to parse ===")
      
      # Check what functions are available in ParserPort
      functions = ParserPort.__info__(:functions)
      parse_functions = Enum.filter(functions, fn {name, _arity} ->
        name |> Atom.to_string() |> String.starts_with?("parse")
      end)
      
      IO.puts("Available parse functions:")
      Enum.each(parse_functions, fn {name, arity} ->
        IO.puts("  #{name}/#{arity}")
      end)
      
      # Try some likely candidates
      test_functions = [
        {:parse_module_identity, 1},
        {:parse_object_identity, 1}, 
        {:parse_object_identifier, 1},
        {:parse_assignment, 1}
      ]
      
      Enum.each(test_functions, fn {func_name, arity} ->
        if {func_name, arity} in functions do
          IO.puts("\nTesting #{func_name}/#{arity}...")
          try do
            result = apply(ParserPort, func_name, [tokens])
            case result do
              {:ok, parsed} ->
                IO.puts("✓ Success: #{inspect(parsed, limit: 3)}")
              {:error, reason} ->
                IO.puts("✗ Error: #{reason}")
              other ->
                IO.puts("? Unexpected: #{inspect(other, limit: 3)}")
            end
          rescue
            e ->
              IO.puts("✗ Exception: #{Exception.message(e)}")
          catch
            type, value ->
              IO.puts("✗ Caught #{type}: #{inspect(value)}")
          end
        else
          IO.puts("Function #{func_name}/#{arity} not available")
        end
      end)
      
    {:error, reason} ->
      IO.puts("✗ Tokenization failed: #{reason}")
  end
else
  IO.puts("Could not find MODULE-IDENTITY in the MIB file")
end

# Test a simple OBJECT IDENTIFIER assignment that's more likely to fail
IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("=== Testing simple OBJECT IDENTIFIER assignment ===")

simple_assignment = "docsDevMIBObjects OBJECT IDENTIFIER ::= { docsDev 1 }"
IO.puts("Input: #{simple_assignment}")

case Lexer.tokenize(simple_assignment) do
  {:ok, tokens} ->
    IO.puts("✓ Tokenized: #{inspect(tokens, pretty: true)}")
    
    # Try to find a function that parses object identifier assignments
    functions = ParserPort.__info__(:functions)
    parse_functions = Enum.filter(functions, fn {name, _arity} ->
      name_str = Atom.to_string(name)
      String.contains?(name_str, "object") or String.contains?(name_str, "identifier") or String.contains?(name_str, "assignment")
    end)
    
    IO.puts("Functions containing 'object', 'identifier', or 'assignment':")
    Enum.each(parse_functions, fn {name, arity} ->
      IO.puts("  #{name}/#{arity}")
    end)
    
  {:error, reason} ->
    IO.puts("✗ Tokenization failed: #{reason}")
end