# Comprehensive test of all implemented MIB parsing features
alias SnmpLib.MIB.{Parser, Lexer}

defmodule ComprehensiveTester do
  alias SnmpLib.MIB.{Parser, Lexer}
  
  def run do
    IO.puts "\n=== Comprehensive MIB Parser Feature Tests ==="
    IO.puts "Testing all implemented parsing capabilities\n"
    
    tests = [
      {"Basic OBJECT-TYPE", test_basic_object_type()},
      {"TEXTUAL-CONVENTION", test_textual_convention()},
      {"NOTIFICATION-TYPE", test_notification_type()},
      {"OBJECT-GROUP", test_object_group()},
      {"TRAP-TYPE (SNMPv1)", test_trap_type()},
      {"AUGMENTS support", test_augments()},
      {"DEFVAL support", test_defval()},
      {"Complex SIZE constraints", test_complex_size()},
      {"MODULE-IDENTITY", test_module_identity()}
    ]
    
    total = length(tests)
    {passed, failed} = run_test_suite(tests)
    
    IO.puts "\n=== Test Results Summary ==="
    IO.puts "Total tests: #{total}"
    IO.puts "✅ Passed: #{passed}/#{total} (#{Float.round(passed/total*100, 1)}%)"
    IO.puts "❌ Failed: #{failed}/#{total}"
    
    if passed == total do
      IO.puts "\n🎉 ALL parsing feature tests PASSED!"
      IO.puts "Parser successfully handles all implemented MIB constructs!"
    else
      IO.puts "\n🟡 Some tests failed - review specific parsing features"
    end
  end
  
  defp run_test_suite(tests) do
    results = Enum.map(tests, fn {name, mib_content} ->
      IO.puts "Testing #{name}:"
      
      case test_mib_parsing(mib_content) do
        :success ->
          IO.puts "  ✅ SUCCESS\n"
          :passed
        {:error, reason} ->
          IO.puts "  ❌ FAILED: #{reason}\n"
          :failed
      end
    end)
    
    passed = Enum.count(results, &(&1 == :passed))
    failed = Enum.count(results, &(&1 == :failed))
    
    {passed, failed}
  end
  
  defp test_mib_parsing(mib_content) do
    case Lexer.tokenize(mib_content) do
      {:ok, tokens} ->
        case Parser.parse_tokens(tokens) do
          {:ok, mib} ->
            IO.puts "    Parsed #{length(mib.definitions)} definitions successfully"
            :success
          {:error, errors} ->
            first_error = List.first(errors)
            {:error, SnmpLib.MIB.Error.format(first_error)}
          {:warning, mib, warnings} ->
            IO.puts "    Parsed with warnings: #{length(warnings)}"
            :success
        end
      {:error, error} ->
        {:error, "Tokenization failed: #{SnmpLib.MIB.Error.format(error)}"}
    end
  end
  
  # Test cases for different MIB constructs
  
  defp test_basic_object_type do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    sysDescr OBJECT-TYPE
        SYNTAX DisplayString (SIZE(0..255))
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION "A textual description of the entity"
        ::= { system 1 }
    
    END
    """
  end
  
  defp test_textual_convention do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    DisplayString TEXTUAL-CONVENTION
        DISPLAY-HINT "255a"
        STATUS current
        DESCRIPTION "Represents textual information taken from the NVT ASCII character set"
        SYNTAX OCTET STRING (SIZE (0..255))
    
    END
    """
  end
  
  defp test_notification_type do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    linkDown NOTIFICATION-TYPE
        OBJECTS { ifIndex, ifAdminStatus, ifOperStatus }
        STATUS current
        DESCRIPTION "A linkDown trap signifies that the SNMP entity recognizes a failure"
        ::= { snmpTraps 3 }
    
    END
    """
  end
  
  defp test_object_group do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    systemGroup OBJECT-GROUP
        OBJECTS { sysDescr, sysObjectID, sysUpTime, sysContact, sysName }
        STATUS current
        DESCRIPTION "The system group defines objects which are common to all managed systems"
        ::= { snmpGroups 6 }
    
    END
    """
  end
  
  defp test_trap_type do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    coldStart TRAP-TYPE
        ENTERPRISE snmp
        DESCRIPTION "A coldStart trap signifies that the SNMP entity is reinitializing itself"
        ::= 0
    
    END
    """
  end
  
  defp test_augments do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    extendedIfEntry OBJECT-TYPE
        SYNTAX ExtendedIfEntry
        MAX-ACCESS not-accessible
        STATUS current
        DESCRIPTION "Additional interface information"
        AUGMENTS { ifEntry }
        ::= { extendedIfTable 1 }
    
    END
    """
  end
  
  defp test_defval do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    testInteger OBJECT-TYPE
        SYNTAX INTEGER (1..100)
        MAX-ACCESS read-write
        STATUS current
        DESCRIPTION "Test integer with default value"
        DEFVAL { 42 }
        ::= { test 1 }
    
    testString OBJECT-TYPE
        SYNTAX DisplayString
        MAX-ACCESS read-write
        STATUS current
        DESCRIPTION "Test string with default value"
        DEFVAL { "default" }
        ::= { test 2 }
    
    END
    """
  end
  
  defp test_complex_size do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    complexString OBJECT-TYPE
        SYNTAX OCTET STRING (SIZE (8 | 11 | 16))
        MAX-ACCESS read-write
        STATUS current
        DESCRIPTION "String with multiple allowed sizes"
        ::= { test 1 }
    
    END
    """
  end
  
  defp test_module_identity do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    testMibModule MODULE-IDENTITY
        LAST-UPDATED "202401010000Z"
        ORGANIZATION "Test Organization"
        CONTACT-INFO "test@example.com"
        DESCRIPTION "Test MIB module"
        REVISION "202401010000Z"
        DESCRIPTION "Initial version"
        ::= { enterprises 12345 }
    
    END
    """
  end
end

# Run the comprehensive test suite
ComprehensiveTester.run()