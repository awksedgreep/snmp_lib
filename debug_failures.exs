# Debug the failing test cases
alias SnmpLib.MIB.{Parser, Lexer}

defmodule DebugTester do
  alias SnmpLib.MIB.{Parser, Lexer}
  
  def run do
    IO.puts "\n=== Debugging Failed Test Cases ==="
    
    # Test the failing basic OBJECT-TYPE case
    mib1 = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    sysDescr OBJECT-TYPE
        SYNTAX DisplayString (SIZE(0..255))
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION "A textual description of the entity"
        ::= { system 1 }
    
    END
    """
    
    IO.puts "=== Debugging Basic OBJECT-TYPE ==="
    debug_parse(mib1)
    
    # Test the failing TEXTUAL-CONVENTION case
    mib2 = """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    DisplayString TEXTUAL-CONVENTION
        DISPLAY-HINT "255a"
        STATUS current
        DESCRIPTION "Represents textual information taken from the NVT ASCII character set"
        SYNTAX OCTET STRING (SIZE (0..255))
    
    END
    """
    
    IO.puts "\n=== Debugging TEXTUAL-CONVENTION ==="
    debug_parse(mib2)
  end
  
  defp debug_parse(mib_content) do
    case Lexer.tokenize(mib_content) do
      {:ok, tokens} ->
        IO.puts "✅ Tokenization succeeded: #{length(tokens)} tokens"
        
        # Show first few tokens for context
        IO.puts "First 10 tokens:"
        tokens |> Enum.take(10) |> Enum.each(fn token ->
          IO.puts "  #{inspect(token)}"
        end)
        
        case Parser.parse_tokens(tokens) do
          {:ok, mib} ->
            IO.puts "✅ Parsing succeeded: #{length(mib.definitions)} definitions"
          {:error, errors} ->
            IO.puts "❌ Parsing failed with #{length(errors)} errors:"
            Enum.each(errors, fn error ->
              IO.puts "  #{SnmpLib.MIB.Error.format(error)}"
            end)
          {:warning, mib, warnings} ->
            IO.puts "⚠️  Parsing succeeded with warnings: #{length(warnings)}"
            IO.puts "Parsed #{length(mib.definitions)} definitions"
        end
        
      {:error, error} ->
        IO.puts "❌ Tokenization failed:"
        IO.puts "  #{SnmpLib.MIB.Error.format(error)}"
    end
  end
end

DebugTester.run()