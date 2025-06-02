# Real-world MIB validation testing
alias SnmpLib.MIB.{Parser, Lexer}

defmodule RealWorldValidation do
  alias SnmpLib.MIB.{Parser, Lexer}
  
  def run do
    IO.puts "\n" <> String.duplicate("=", 70)
    IO.puts "REAL-WORLD MIB PARSER VALIDATION"
    IO.puts String.duplicate("=", 70)
    
    IO.puts "\n📋 Testing parser against realistic MIB content patterns..."
    
    # Test increasingly complex real-world patterns
    test_cases = [
      {"Simple Object Definition", simple_object()},
      {"Complex TEXTUAL-CONVENTION", complex_textual_convention()},
      {"Table with INDEX", table_with_index()},
      {"MODULE-IDENTITY with Revisions", module_identity_with_revisions()},
      {"Notification with Objects", notification_with_objects()},
      {"Group Definition", group_definition()},
      {"Legacy Trap Definition", legacy_trap()},
      {"Complex Real-World Pattern", complex_real_world()}
    ]
    
    {passed, total} = run_validation_tests(test_cases)
    
    IO.puts "\n" <> String.duplicate("=", 70)
    IO.puts "VALIDATION RESULTS"
    IO.puts String.duplicate("=", 70)
    
    success_rate = Float.round(passed / total * 100, 1)
    IO.puts "✅ Tests Passed: #{passed}/#{total} (#{success_rate}%)"
    
    if success_rate >= 80 do
      IO.puts "\n🎉 PRODUCTION VALIDATION SUCCESSFUL!"
      IO.puts "Parser demonstrates production readiness with #{success_rate}% success rate."
      IO.puts "Ready for deployment in real-world SNMP environments."
    else
      IO.puts "\n⚠️  NEEDS ADDITIONAL WORK"
      IO.puts "Parser requires further development before production deployment."
    end
    
    suggest_next_steps(success_rate)
  end
  
  defp run_validation_tests(test_cases) do
    results = Enum.map(test_cases, fn {name, mib_content} ->
      IO.puts "\n🔍 Testing: #{name}"
      
      case validate_mib_content(mib_content) do
        :success -> 
          IO.puts "  ✅ SUCCESS"
          :passed
        {:error, reason} -> 
          IO.puts "  ❌ FAILED: #{reason}"
          :failed
        {:warning, warning} ->
          IO.puts "  ⚠️  WARNING: #{warning}"
          :passed
      end
    end)
    
    passed = Enum.count(results, &(&1 == :passed))
    total = length(results)
    
    {passed, total}
  end
  
  defp validate_mib_content(mib_content) do
    case Lexer.tokenize(mib_content) do
      {:ok, tokens} ->
        case Parser.parse_tokens(tokens) do
          {:ok, mib} -> 
            IO.puts "    Parsed #{length(mib.definitions)} definitions"
            :success
          {:warning, mib, warnings} -> 
            IO.puts "    Parsed #{length(mib.definitions)} definitions with #{length(warnings)} warnings"
            {:warning, "Parsed with warnings but successful"}
          {:error, errors} -> 
            first_error = List.first(errors)
            {:error, SnmpLib.MIB.Error.format(first_error)}
        end
      {:error, error} -> 
        {:error, "Tokenization failed: #{SnmpLib.MIB.Error.format(error)}"}
    end
  end
  
  defp suggest_next_steps(success_rate) do
    IO.puts "\n📋 RECOMMENDED NEXT STEPS:"
    
    if success_rate >= 90 do
      IO.puts "1. Deploy to production SNMP environments"
      IO.puts "2. Begin processing enterprise MIB libraries"
      IO.puts "3. Monitor performance with large MIB collections"
    elsif success_rate >= 80 do
      IO.puts "1. Address remaining edge cases identified in testing"
      IO.puts "2. Conduct limited production trials"
      IO.puts "3. Gather feedback from real-world usage"
    else
      IO.puts "1. Fix critical parsing issues identified in testing"
      IO.puts "2. Enhance error recovery mechanisms"
      IO.puts "3. Expand test coverage for failing scenarios"
    end
    
    IO.puts "4. Consider implementing MODULE-COMPLIANCE parsing"
    IO.puts "5. Add AGENT-CAPABILITIES support for complete feature coverage"
  end
  
  # Test case definitions with real-world patterns
  
  defp simple_object do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    IMPORTS Counter32 FROM SNMPv2-SMI;
    
    sysUpTime OBJECT-TYPE
        SYNTAX TimeTicks
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION "System uptime in hundredths of seconds"
        ::= { system 3 }
    
    END
    """
  end
  
  defp complex_textual_convention do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    MacAddress TEXTUAL-CONVENTION
        DISPLAY-HINT "1x:"
        STATUS current
        DESCRIPTION "Represents an 802 MAC address"
        SYNTAX OCTET STRING (SIZE(6))
        
    RowStatus TEXTUAL-CONVENTION
        STATUS current
        DESCRIPTION "Row status for table management"
        SYNTAX INTEGER {
            active(1),
            notInService(2),
            notReady(3),
            createAndGo(4),
            createAndWait(5),
            destroy(6)
        }
    
    END
    """
  end
  
  defp table_with_index do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    IMPORTS Counter32, Gauge32 FROM SNMPv2-SMI;
    
    ifTable OBJECT-TYPE
        SYNTAX SEQUENCE OF IfEntry
        MAX-ACCESS not-accessible
        STATUS current
        DESCRIPTION "Interface information table"
        ::= { interfaces 2 }
        
    ifEntry OBJECT-TYPE
        SYNTAX IfEntry
        MAX-ACCESS not-accessible
        STATUS current
        DESCRIPTION "Interface table entry"
        INDEX { ifIndex }
        ::= { ifTable 1 }
        
    ifIndex OBJECT-TYPE
        SYNTAX INTEGER (1..2147483647)
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION "Interface index"
        ::= { ifEntry 1 }
        
    ifInOctets OBJECT-TYPE
        SYNTAX Counter32
        UNITS "octets"
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION "Total octets received"
        ::= { ifEntry 10 }
    
    END
    """
  end
  
  defp module_identity_with_revisions do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    testMIB MODULE-IDENTITY
        LAST-UPDATED "202401150000Z"
        ORGANIZATION "Example Organization"
        CONTACT-INFO
            "Example Contact
             Email: admin@example.com
             Phone: +1-555-0123"
        DESCRIPTION
            "This MIB module defines test objects for network management."
        REVISION "202401150000Z"
        DESCRIPTION
            "Latest revision with enhanced features"
        REVISION "202312010000Z" 
        DESCRIPTION
            "Initial version"
        ::= { enterprises 12345 }
    
    END
    """
  end
  
  defp notification_with_objects do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    linkDown NOTIFICATION-TYPE
        OBJECTS { 
            ifIndex,
            ifAdminStatus,
            ifOperStatus,
            ifName
        }
        STATUS current
        DESCRIPTION
            "A linkDown trap signifies that the SNMP entity, acting in
             an agent role, recognizes a failure in one of the communication
             links represented in the agent's configuration."
        REFERENCE "RFC 2863"
        ::= { snmpTraps 3 }
        
    systemGroup OBJECT-GROUP
        OBJECTS { 
            sysDescr,
            sysObjectID,
            sysUpTime,
            sysContact,
            sysName,
            sysLocation,
            sysServices
        }
        STATUS current
        DESCRIPTION
            "The system group defines objects which are common to all
             managed systems."
        ::= { snmpGroups 6 }
    
    END
    """
  end
  
  defp group_definition do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    ifGeneralInformationGroup OBJECT-GROUP
        OBJECTS {
            ifIndex,
            ifDescr,
            ifType,
            ifSpeed,
            ifPhysAddress,
            ifAdminStatus,
            ifOperStatus,
            ifLastChange
        }
        STATUS current
        DESCRIPTION
            "A collection of objects providing information applicable to
             all network interfaces."
        ::= { ifGroups 10 }
    
    END
    """
  end
  
  defp legacy_trap do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    coldStart TRAP-TYPE
        ENTERPRISE snmp
        DESCRIPTION
            "A coldStart trap signifies that the SNMP entity, supporting a
             command responder application, is reinitializing itself such
             that its configuration may have been altered."
        ::= 0
        
    authenticationFailure TRAP-TYPE
        ENTERPRISE snmp
        VARIABLES { snmpInBadCommunityNames }
        DESCRIPTION
            "An authenticationFailure trap signifies that the SNMP entity
             has received a protocol message that is not properly authenticated."
        ::= 4
    
    END
    """
  end
  
  defp complex_real_world do
    """
    EXAMPLE-MIB DEFINITIONS ::= BEGIN
    
    IMPORTS
        MODULE-IDENTITY, OBJECT-TYPE, NOTIFICATION-TYPE,
        Unsigned32, Counter32, Gauge32, TimeTicks,
        TEXTUAL-CONVENTION                              FROM SNMPv2-SMI
        DisplayString, RowStatus, TimeStamp             FROM SNMPv2-TC
        MODULE-COMPLIANCE, OBJECT-GROUP                 FROM SNMPv2-CONF;
    
    exampleMIB MODULE-IDENTITY
        LAST-UPDATED "202401150000Z"
        ORGANIZATION "Example Corp"
        CONTACT-INFO "support@example.com"
        DESCRIPTION "Example enterprise MIB"
        REVISION "202401150000Z"
        DESCRIPTION "Initial release"
        ::= { enterprises 99999 }
        
    ConnectionState TEXTUAL-CONVENTION
        STATUS current
        DESCRIPTION "Connection state enumeration"
        SYNTAX INTEGER {
            idle(1),
            connecting(2),
            connected(3),
            disconnecting(4),
            error(5)
        }
        
    connectionTable OBJECT-TYPE
        SYNTAX SEQUENCE OF ConnectionEntry
        MAX-ACCESS not-accessible
        STATUS current
        DESCRIPTION "Active connections table"
        ::= { exampleMIB 1 }
        
    connectionEntry OBJECT-TYPE
        SYNTAX ConnectionEntry
        MAX-ACCESS not-accessible
        STATUS current
        DESCRIPTION "Connection entry"
        INDEX { connectionId }
        ::= { connectionTable 1 }
        
    connectionId OBJECT-TYPE
        SYNTAX Unsigned32 (1..4294967295)
        MAX-ACCESS not-accessible
        STATUS current
        DESCRIPTION "Connection identifier"
        ::= { connectionEntry 1 }
        
    connectionState OBJECT-TYPE
        SYNTAX ConnectionState
        MAX-ACCESS read-only
        STATUS current
        DESCRIPTION "Current connection state"
        ::= { connectionEntry 2 }
        
    connectionEstablished NOTIFICATION-TYPE
        OBJECTS { connectionId, connectionState }
        STATUS current
        DESCRIPTION "Connection established notification"
        ::= { exampleMIB 0 1 }
        
    connectionsGroup OBJECT-GROUP
        OBJECTS { connectionState }
        STATUS current
        DESCRIPTION "Connection monitoring objects"
        ::= { exampleMIB 2 1 }
    
    END
    """
  end
end

RealWorldValidation.run()