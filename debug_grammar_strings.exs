#!/usr/bin/env elixir

# Debug exactly where strings get reversed during grammar parsing

Logger.configure(level: :error)

IO.puts("🔍 Debugging Grammar String Processing")
IO.puts("====================================")

# Test with minimal valid MIB that will actually parse through the grammar
test_mib = """
TEST-MIB DEFINITIONS ::= BEGIN

IMPORTS
    Integer32, OBJECT-TYPE
        FROM SNMPv2-SMI;

testObject OBJECT-TYPE
    SYNTAX Integer32
    MAX-ACCESS read-only
    STATUS current
    DESCRIPTION "This should not be reversed"
    ::= { 1 3 6 1 4 1 12345 1 }

END
"""

# Step 1: Test tokenization  
IO.puts("1. Testing tokenization...")
char_content = to_charlist(test_mib)

case SnmpLib.MIB.SnmpTokenizer.tokenize(char_content, &SnmpLib.MIB.SnmpTokenizer.null_get_line/0) do
  {:ok, tokens} ->
    description_tokens = Enum.filter(tokens, fn 
      {:string, _, _} -> true
      _ -> false
    end)
    
    if length(description_tokens) > 0 do
      {:string, _, content} = List.first(description_tokens)
      content_str = to_string(content)
      IO.puts("  Tokenized string: \"#{content_str}\"")
      
      if String.contains?(content_str, "desrever") do
        IO.puts("  ❌ TOKENIZATION: String is already reversed!")
      else
        IO.puts("  ✅ TOKENIZATION: String is correct")
      end
    end
    
    # Step 2: Test raw grammar parsing (before convert_to_elixir_format)
    IO.puts("\n2. Testing raw grammar parsing...")
    
    # Get parser module
    case SnmpLib.MIB.Parser.init_parser() do
      {:ok, parser_module} ->
        case apply(parser_module, :parse, [tokens]) do
          {:ok, parse_tree} ->
            IO.puts("  Raw parse tree type: #{inspect(elem(parse_tree, 0))}")
            IO.puts("  Raw parse tree (first 200 chars): #{inspect(parse_tree) |> String.slice(0, 200)}...")
            
            # Look for string content in the raw parse tree
            tree_str = inspect(parse_tree)
            if String.contains?(tree_str, "desrever") do
              IO.puts("  ❌ RAW GRAMMAR: String is reversed in parse tree!")
            else
              IO.puts("  ✅ RAW GRAMMAR: String appears correct in parse tree")
            end
            
            # Step 3: Test conversion to Elixir format
            IO.puts("\n3. Testing Elixir format conversion...")
            elixir_result = SnmpLib.MIB.Parser.convert_to_elixir_format(parse_tree)
            
            # Find description in converted result
            test_obj = Enum.find(elixir_result.definitions, fn def ->
              Map.has_key?(def, :description) and def.description != nil
            end)
            
            if test_obj do
              desc_str = to_string(test_obj.description)
              IO.puts("  Converted description: \"#{desc_str}\"")
              
              if String.contains?(desc_str, "desrever") do
                IO.puts("  ❌ CONVERSION: String was reversed during conversion!")
              else
                IO.puts("  ✅ CONVERSION: String is correct after conversion")
              end
            else
              IO.puts("  ⚠️  No description found in converted result")
            end
            
          {:error, reason} ->
            IO.puts("  ❌ Grammar parsing failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("  ❌ Parser init failed: #{inspect(reason)}")
    end
    
  {:error, reason} ->
    IO.puts("  ❌ Tokenization failed: #{inspect(reason)}")
end