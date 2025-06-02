# Test TEXTUAL-CONVENTION parsing
defmodule TestTextualConvention do
  alias SnmpLib.MIB.{Parser, Lexer}

  def test_textual_convention_parsing do
    test_cases = [
      # Test case 1: Basic TEXTUAL-CONVENTION
      {"Test 1: Basic TEXTUAL-CONVENTION", """
        TEST-MIB DEFINITIONS ::= BEGIN
        DisplayString TEXTUAL-CONVENTION
            DISPLAY-HINT "255a"
            STATUS current
            DESCRIPTION "Represents textual information taken from the NVT ASCII
                         character set, as defined in pages 4, 10-11 of RFC 854."
            SYNTAX OCTET STRING (SIZE (0..255))
        END
      """},
      
      # Test case 2: TEXTUAL-CONVENTION without DISPLAY-HINT
      {"Test 2: TEXTUAL-CONVENTION without DISPLAY-HINT", """
        TEST-MIB DEFINITIONS ::= BEGIN
        RowStatus TEXTUAL-CONVENTION
            STATUS current
            DESCRIPTION "The RowStatus textual convention is used to manage the
                         creation and deletion of conceptual rows."
            SYNTAX INTEGER {
                active(1),
                notInService(2),
                notReady(3),
                createAndGo(4),
                createAndWait(5),
                destroy(6)
            }
        END
      """},
      
      # Test case 3: TEXTUAL-CONVENTION with REFERENCE
      {"Test 3: TEXTUAL-CONVENTION with REFERENCE", """
        TEST-MIB DEFINITIONS ::= BEGIN
        MacAddress TEXTUAL-CONVENTION
            DISPLAY-HINT "1x:"
            STATUS current
            DESCRIPTION "Represents an 802 MAC address represented in the
                         'canonical' order defined by IEEE 802.1a."
            REFERENCE "IEEE Standard 802-1990: IEEE Standards for Local and
                       Metropolitan Area Networks: Overview and Architecture"
            SYNTAX OCTET STRING (SIZE (6))
        END
      """},
      
      # Test case 4: Real-world TEXTUAL-CONVENTION (TimeStamp)
      {"Test 4: Real-world TimeStamp TEXTUAL-CONVENTION", """
        SNMPv2-TC DEFINITIONS ::= BEGIN
        TimeStamp TEXTUAL-CONVENTION
            STATUS current
            DESCRIPTION "The value of the sysUpTime object at which a specific
                         occurrence happened.  The specific occurrence must be
                         defined in the description of any object defined using
                         this type."
            SYNTAX TimeTicks
        END
      """},
      
      # Test case 5: Complex DISPLAY-HINT format
      {"Test 5: Complex DISPLAY-HINT TEXTUAL-CONVENTION", """
        TEST-MIB DEFINITIONS ::= BEGIN
        DateAndTime TEXTUAL-CONVENTION
            DISPLAY-HINT "2d-1d-1d,1d:1d:1d.1d,1a1d:1d"
            STATUS current
            DESCRIPTION "A date-time specification."
            REFERENCE "RFC 2579, section 2"
            SYNTAX OCTET STRING (SIZE (8 | 11))
        END
      """}
    ]

    IO.puts "\n=== TEXTUAL-CONVENTION Parsing Tests ==="
    
    total = length(test_cases)
    
    results = Enum.map(test_cases, fn {name, mib_content} ->
      IO.puts "\n#{name}:"
      
      case Lexer.tokenize(mib_content) do
        {:ok, tokens} ->
          IO.puts "  ✅ TOKENIZATION SUCCESS: #{length(tokens)} tokens"
          
          case Parser.parse_tokens(tokens) do
            {:ok, mib} ->
              IO.puts "  ✅ PARSING SUCCESS: Parsed #{length(mib.definitions)} definition(s)"
              
              # Print the TEXTUAL-CONVENTION definition details
              case mib.definitions do
                [definition | _] when definition.__type__ == :textual_convention ->
                  IO.puts "  📝 TEXTUAL-CONVENTION Definition:"
                  IO.puts "     Name: #{definition.name}"
                  IO.puts "     Display Hint: #{definition.display_hint || "None"}"
                  IO.puts "     Status: #{definition.status}"
                  IO.puts "     Description: #{String.slice(definition.description, 0, 50)}..."
                  IO.puts "     Reference: #{definition.reference || "None"}"
                  IO.puts "     Syntax: #{inspect(definition.syntax, limit: :infinity)}"
                  {:success, definition}
                _ ->
                  IO.puts "  ⚠️  No TEXTUAL-CONVENTION definition found"
                  IO.puts "  📝 Found definitions: #{inspect(Enum.map(mib.definitions, & &1.__type__))}"
                  {:no_textual_convention, mib.definitions}
              end
              
            {:error, errors} ->
              IO.puts "  ❌ PARSING FAILED:"
              Enum.each(errors, fn error ->
                IO.puts "     #{SnmpLib.MIB.Error.format(error)}"
              end)
              {:parsing_failed, errors}
              
            {:warning, mib, warnings} ->
              IO.puts "  ⚠️  PARSED WITH WARNINGS:"
              Enum.each(warnings, fn warning ->
                IO.puts "     #{SnmpLib.MIB.Error.format(warning)}"
              end)
              case mib.definitions do
                [definition | _] when definition.__type__ == :textual_convention ->
                  IO.puts "  📝 TEXTUAL-CONVENTION Definition: #{definition.name}"
                  {:success_with_warnings, definition}
                _ ->
                  {:no_textual_convention, mib.definitions}
              end
          end
          
        {:error, error} ->
          IO.puts "  ❌ TOKENIZATION FAILED: #{SnmpLib.MIB.Error.format(error)}"
          {:tokenization_failed, error}
      end
    end)
    
    successful = Enum.count(results, fn 
      {:success, _} -> true
      {:success_with_warnings, _} -> true
      _ -> false
    end)
    
    IO.puts "\n=== Test Summary ==="
    IO.puts "Tests passed: #{successful}/#{total}"
    
    if successful == total do
      IO.puts "🎉 All TEXTUAL-CONVENTION parsing tests PASSED!"
    else
      IO.puts "⚠️  Some tests failed. Check results above."
    end
    
    {successful, total, results}
  end
end

TestTextualConvention.test_textual_convention_parsing()