defmodule SnmpLib.MIB.LexerTest do
  use ExUnit.Case, async: true
  doctest SnmpLib.MIB.Lexer
  
  alias SnmpLib.MIB.{Lexer, Error}
  
  describe "basic tokenization" do
    test "tokenizes simple identifier" do
      assert {:ok, tokens} = Lexer.tokenize("sysDescr")
      assert [{:identifier, "sysDescr", %{line: 1, column: 1}}] = tokens
    end
    
    test "tokenizes keywords" do
      assert {:ok, tokens} = Lexer.tokenize("OBJECT-TYPE")
      assert [{:keyword, :object_type, %{line: 1, column: 1}}] = tokens
    end
    
    test "tokenizes numbers" do
      assert {:ok, tokens} = Lexer.tokenize("42")
      assert [{:number, 42, %{line: 1, column: 1}}] = tokens
    end
    
    test "tokenizes negative numbers" do
      assert {:ok, tokens} = Lexer.tokenize("-42")
      assert [{:number, -42, %{line: 1, column: 1}}] = tokens
    end
    
    test "tokenizes strings" do
      assert {:ok, tokens} = Lexer.tokenize("\"Hello World\"")
      assert [{:string, "Hello World", %{line: 1, column: 1}}] = tokens
    end
    
    test "tokenizes symbols" do
      assert {:ok, tokens} = Lexer.tokenize("::=")
      assert [{:symbol, :assign, %{line: 1, column: 1}}] = tokens
      
      assert {:ok, tokens} = Lexer.tokenize("{}")
      assert [
        {:symbol, :open_brace, %{line: 1, column: 1}},
        {:symbol, :close_brace, %{line: 1, column: 2}}
      ] = tokens
    end
  end
  
  describe "whitespace handling" do
    test "skips spaces and tabs" do
      assert {:ok, tokens} = Lexer.tokenize("  \t  sysDescr  \t  ")
      assert [{:identifier, "sysDescr", %{line: 1, column: 13}}] = tokens
    end
    
    test "handles newlines" do
      assert {:ok, tokens} = Lexer.tokenize("line1\nline2")
      assert [
        {:identifier, "line1", %{line: 1, column: 1}},
        {:identifier, "line2", %{line: 2, column: 1}}
      ] = tokens
    end
    
    test "handles different newline styles" do
      assert {:ok, tokens} = Lexer.tokenize("line1\r\nline2\rline3")
      assert [
        {:identifier, "line1", %{line: 1, column: 1}},
        {:identifier, "line2", %{line: 2, column: 1}},
        {:identifier, "line3", %{line: 3, column: 1}}
      ] = tokens
    end
  end
  
  describe "comment handling" do
    test "skips line comments" do
      assert {:ok, tokens} = Lexer.tokenize("before -- this is a comment\nafter")
      assert [
        {:identifier, "before", %{line: 1, column: 1}},
        {:identifier, "after", %{line: 2, column: 1}}
      ] = tokens
    end
    
    test "handles comment at end of file" do
      assert {:ok, tokens} = Lexer.tokenize("token -- comment")
      assert [{:identifier, "token", %{line: 1, column: 1}}] = tokens
    end
  end
  
  describe "string handling" do
    test "handles escaped quotes" do
      assert {:ok, tokens} = Lexer.tokenize("\"He said \\\"Hello\\\"\"")
      assert [{:string, "He said \"Hello\"", %{line: 1, column: 1}}] = tokens
    end
    
    test "handles escaped characters" do
      assert {:ok, tokens} = Lexer.tokenize("\"line1\\nline2\\tindented\"")
      assert [{:string, "line1\nline2\tindented", %{line: 1, column: 1}}] = tokens
    end
    
    test "reports unterminated strings" do
      assert {:error, %Error{type: :unterminated_string}} = 
        Lexer.tokenize("\"unterminated")
    end
  end
  
  describe "complex tokenization" do
    test "tokenizes MIB object definition" do
      mib_text = """
      sysDescr OBJECT-TYPE
          SYNTAX  DisplayString (SIZE (0..255))
          ACCESS  read-only
          STATUS  mandatory
          DESCRIPTION
              "A textual description of the entity."
          ::= { system 1 }
      """
      
      assert {:ok, tokens} = Lexer.tokenize(mib_text)
      
      # Verify we get the expected token types
      token_types = Enum.map(tokens, fn {type, _, _} -> type end)
      
      assert :identifier in token_types  # sysDescr
      assert :keyword in token_types     # OBJECT-TYPE, SYNTAX, etc.
      assert :symbol in token_types      # ::=, {, }
      assert :string in token_types      # description
      assert :number in token_types      # 1
    end
    
    test "handles vendor-specific identifiers with hyphens" do
      assert {:ok, tokens} = Lexer.tokenize("cisco-specific-object")
      assert [{:identifier, "cisco-specific-object", %{line: 1, column: 1}}] = tokens
    end
    
    test "handles mixed case keywords" do
      # Some vendors use different cases
      assert {:ok, tokens} = Lexer.tokenize("read-only")
      assert [{:keyword, :read_only, %{line: 1, column: 1}}] = tokens
    end
  end
  
  describe "error handling" do
    test "reports invalid characters" do
      assert {:error, %Error{type: :invalid_character}} = 
        Lexer.tokenize("valid @invalid")
    end
    
    test "provides accurate line/column information" do
      assert {:error, %Error{line: 2, column: 5}} = 
        Lexer.tokenize("line1\ntest@")
    end
    
    test "handles empty input" do
      assert {:ok, []} = Lexer.tokenize("")
    end
    
    test "handles whitespace-only input" do
      assert {:ok, []} = Lexer.tokenize("   \t\n  \r\n  ")
    end
  end
  
  describe "performance characteristics" do
    test "handles large input efficiently" do
      # Generate a reasonably large MIB-like input
      large_input = Enum.map(1..1000, fn i ->
        "object#{i} OBJECT-TYPE SYNTAX INTEGER ACCESS read-only STATUS current"
      end) |> Enum.join("\n")
      
      {time_us, result} = :timer.tc(fn -> Lexer.tokenize(large_input) end)
      
      assert {:ok, tokens} = result
      assert length(tokens) > 5000  # Should have many tokens
      assert time_us < 500_000  # Should complete in under 500ms
    end
  end
end