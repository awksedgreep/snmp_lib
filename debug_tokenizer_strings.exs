#!/usr/bin/env elixir

# Debug where string reversal happens in tokenization vs parsing

Logger.configure(level: :error)

IO.puts("🔍 Debugging Tokenizer vs Parser String Handling")
IO.puts("==============================================")

# Simple test with just a string
test_input = ~s{DESCRIPTION "This should not be reversed"}

IO.puts("Testing input: #{test_input}")

# Test our custom lexer directly
IO.puts("\n1. Testing custom lexer:")
case SnmpLib.MIB.Lexer.tokenize(test_input) do
  {:ok, tokens} ->
    string_tokens = Enum.filter(tokens, fn 
      {:string, _, _} -> true
      _ -> false
    end)
    IO.puts("  String tokens from lexer: #{inspect(string_tokens)}")
    
    if length(string_tokens) > 0 do
      {_, content, _} = List.first(string_tokens)
      IO.puts("  String content: \"#{content}\"")
      if String.contains?(content, "desrever") do
        IO.puts("  ❌ LEXER: String is reversed!")
      else
        IO.puts("  ✅ LEXER: String is correct")
      end
    end
    
  {:error, reason} ->
    IO.puts("  ❌ Lexer failed: #{inspect(reason)}")
end

# Test conversion to grammar format
IO.puts("\n2. Testing token conversion:")
case SnmpLib.MIB.Lexer.tokenize(test_input) do
  {:ok, tokens} ->
    # This calls convert_tokens_for_grammar internally in the parser
    char_content = to_charlist(test_input)
    case SnmpLib.MIB.SnmpTokenizer.tokenize(char_content, &SnmpLib.MIB.SnmpTokenizer.null_get_line/0) do
      {:ok, erlang_tokens} ->
        IO.puts("  Erlang tokenizer tokens: #{inspect(erlang_tokens)}")
        
        string_tokens = Enum.filter(erlang_tokens, fn 
          {:string, _, _} -> true
          _ -> false
        end)
        
        if length(string_tokens) > 0 do
          {_, _, content} = List.first(string_tokens)
          content_str = to_string(content)
          IO.puts("  Erlang string content: \"#{content_str}\"")
          if String.contains?(content_str, "desrever") do
            IO.puts("  ❌ ERLANG TOKENIZER: String is reversed!")
          else
            IO.puts("  ✅ ERLANG TOKENIZER: String is correct")
          end
        end
        
      {:error, reason} ->
        IO.puts("  ❌ Erlang tokenizer failed: #{inspect(reason)}")
    end
    
  {:error, reason} ->
    IO.puts("  ❌ Token conversion failed: #{inspect(reason)}")
end

# Test with minimal MIB that parses
test_mib = """
TEST-MIB DEFINITIONS ::= BEGIN
testObject OBJECT-TYPE
    DESCRIPTION "This should not be reversed"
    ::= { 1 }
END
"""

IO.puts("\n3. Testing full MIB parsing:")
case SnmpLib.MIB.Parser.parse(test_mib) do
  {:ok, mib_data} ->
    test_obj = Enum.find(mib_data.definitions, fn def ->
      Map.has_key?(def, :description) and def.description != nil
    end)
    
    if test_obj do
      desc_str = to_string(test_obj.description)
      IO.puts("  Final parsed description: \"#{desc_str}\"")
      if String.contains?(desc_str, "desrever") do
        IO.puts("  ❌ FINAL RESULT: String is reversed!")
      else
        IO.puts("  ✅ FINAL RESULT: String is correct")
      end
    else
      IO.puts("  ⚠️  No object with description found")
    end
    
  {:error, reason} ->
    IO.puts("  ❌ Full parsing failed: #{inspect(reason)}")
end