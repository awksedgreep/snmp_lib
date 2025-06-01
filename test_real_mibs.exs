#!/usr/bin/env elixir

# Test script to parse real MIB files

alias SnmpLib.MIB.{Lexer, Parser}

defmodule MibTester do
  def test_mib(file_path) do
    IO.puts("\n=== Testing: #{Path.basename(file_path)} ===")
    
    case File.read(file_path) do
      {:ok, content} ->
        # Show first few lines for context
        lines = String.split(content, "\n")
        IO.puts("First 5 lines:")
        lines
        |> Enum.take(5)
        |> Enum.with_index(1)
        |> Enum.each(fn {line, idx} ->
          IO.puts("  #{idx}. #{line}")
        end)
        
        IO.puts("\nTokenizing...")
        case Lexer.tokenize(content) do
          {:ok, tokens} ->
            IO.puts("✅ Tokenization successful! (#{length(tokens)} tokens)")
            
            IO.puts("Parsing...")
            case Parser.parse_tokens(tokens) do
              {:ok, mib} ->
                IO.puts("✅ Parsing successful!")
                IO.puts("   MIB name: #{mib.name}")
                IO.puts("   Imports: #{length(mib.imports)}")
                IO.puts("   Definitions: #{length(mib.definitions)}")
                if length(mib.definitions) > 0 do
                  definition_types = mib.definitions
                  |> Enum.map(& &1.__type__)
                  |> Enum.frequencies()
                  |> Enum.map(fn {type, count} -> "#{type}(#{count})" end)
                  |> Enum.join(", ")
                  IO.puts("   Definition types: #{definition_types}")
                end
                {:ok, mib}
                
              {:warning, mib, warnings} ->
                IO.puts("⚠️  Parsing completed with #{length(warnings)} warnings")
                IO.puts("   MIB name: #{mib.name}")
                IO.puts("   Imports: #{length(mib.imports)}")
                IO.puts("   Definitions: #{length(mib.definitions)}")
                Enum.each(warnings, fn warning ->
                  IO.puts("   Warning: #{warning.message}")
                end)
                {:warning, mib, warnings}
                
              {:error, errors} ->
                IO.puts("❌ Parsing failed with #{length(errors)} errors")
                Enum.take(errors, 3) |> Enum.each(fn error ->
                  IO.puts("   Error: #{error.message}")
                  if error.line, do: IO.puts("     Line: #{error.line}")
                  if error.column, do: IO.puts("     Column: #{error.column}")
                end)
                {:error, errors}
            end
            
          {:error, error} ->
            IO.puts("❌ Tokenization failed!")
            IO.puts("   Error: #{error.message}")
            if error.line, do: IO.puts("   Line: #{error.line}")
            if error.column, do: IO.puts("   Column: #{error.column}")
            {:error, [error]}
        end
        
      {:error, reason} ->
        IO.puts("❌ Failed to read file: #{reason}")
        {:error, reason}
    end
  end
  
  def test_directory(dir_path, pattern \\ "*.mib") do
    IO.puts("=== Testing MIBs in #{dir_path} ===")
    
    files = Path.wildcard(Path.join(dir_path, pattern))
    |> Enum.sort()
    
    IO.puts("Found #{length(files)} MIB files")
    
    results = Enum.map(files, fn file ->
      result = test_mib(file)
      {Path.basename(file), result}
    end)
    
    # Summary
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("SUMMARY")
    IO.puts(String.duplicate("=", 60))
    
    {successes, warnings, failures} = Enum.reduce(results, {0, 0, 0}, fn {name, result}, {s, w, f} ->
      case result do
        {:ok, _} -> 
          IO.puts("✅ #{name}")
          {s + 1, w, f}
        {:warning, _, _} ->
          IO.puts("⚠️  #{name}")
          {s, w + 1, f}
        {:error, _} ->
          IO.puts("❌ #{name}")
          {s, w, f + 1}
        _ ->
          IO.puts("❌ #{name} (read error)")
          {s, w, f + 1}
      end
    end)
    
    total = length(results)
    IO.puts("\nResults: #{successes} success, #{warnings} warnings, #{failures} failures out of #{total} total")
    IO.puts("Success rate: #{Float.round(successes / max(total, 1) * 100, 1)}%")
    
    results
  end
end

# Test a few individual files first
working_dir = "test/fixtures/mibs/working"

# Start with fundamental MIBs
test_files = [
  "SNMPv2-SMI.mib",
  "SNMPv2-TC.mib",
  "SNMPv2-MIB.mib",
  "RFC1155-SMI.mib",
  "INET-ADDRESS-MIB.mib"
]

IO.puts("Testing individual fundamental MIBs...")
Enum.each(test_files, fn file ->
  file_path = Path.join(working_dir, file)
  if File.exists?(file_path) do
    MibTester.test_mib(file_path)
  else
    IO.puts("File not found: #{file}")
  end
end)

# Test all working MIBs
IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("Now testing ALL working MIBs...")
MibTester.test_directory(working_dir)