# Test MODULE-COMPLIANCE parsing implementation
alias SnmpLib.MIB.{Parser, Lexer}

defmodule ModuleComplianceTest do
  alias SnmpLib.MIB.{Parser, Lexer}
  
  def run do
    IO.puts "\n=== MODULE-COMPLIANCE Parsing Tests ==="
    IO.puts "Testing comprehensive MODULE-COMPLIANCE parsing implementation\n"
    
    test_cases = [
      {"Basic MODULE-COMPLIANCE", basic_module_compliance()},
      {"MODULE-COMPLIANCE with MANDATORY-GROUPS", with_mandatory_groups()},
      {"MODULE-COMPLIANCE with OBJECT clauses", with_object_clauses()},
      {"Complex MODULE-COMPLIANCE", complex_module_compliance()},
      {"Real-world MODULE-COMPLIANCE", real_world_example()}
    ]
    
    {passed, total} = run_tests(test_cases)
    
    IO.puts "\n=== MODULE-COMPLIANCE Test Results ==="
    IO.puts "Passed: #{passed}/#{total} (#{Float.round(passed/total*100, 1)}%)"
    
    if passed == total do
      IO.puts "🎉 ALL MODULE-COMPLIANCE tests PASSED!"
      IO.puts "Parser now supports complete MODULE-COMPLIANCE definitions."
    else
      IO.puts "🔧 Some tests failed - review MODULE-COMPLIANCE implementation"
    end
  end
  
  defp run_tests(test_cases) do
    results = Enum.map(test_cases, fn {name, mib_content} ->
      IO.puts "Testing #{name}:"
      
      case test_parse(mib_content) do
        :success -> 
          IO.puts "  ✅ SUCCESS\n"
          :passed
        {:error, reason} -> 
          IO.puts "  ❌ FAILED: #{reason}\n"
          :failed
      end
    end)
    
    passed = Enum.count(results, &(&1 == :passed))
    total = length(results)
    
    {passed, total}
  end
  
  defp test_parse(mib_content) do
    case Lexer.tokenize(mib_content) do
      {:ok, tokens} ->
        case Parser.parse_tokens(tokens) do
          {:ok, mib} -> 
            # Find MODULE-COMPLIANCE definitions
            compliance_defs = Enum.filter(mib.definitions, &(&1.__type__ == :module_compliance))
            IO.puts "    Parsed #{length(compliance_defs)} MODULE-COMPLIANCE definitions"
            
            # Show details of first compliance definition
            if length(compliance_defs) > 0 do
              compliance = List.first(compliance_defs)
              IO.puts "    Name: #{compliance.name}"
              IO.puts "    Status: #{compliance.status}"
              IO.puts "    Mandatory Groups: #{length(compliance.mandatory_groups)}"
              IO.puts "    Object Clauses: #{length(compliance.object_clauses)}"
            end
            
            :success
          {:warning, mib, _warnings} -> 
            compliance_defs = Enum.filter(mib.definitions, &(&1.__type__ == :module_compliance))
            IO.puts "    Parsed #{length(compliance_defs)} MODULE-COMPLIANCE definitions (with warnings)"
            :success
          {:error, errors} -> 
            first_error = List.first(errors)
            {:error, SnmpLib.MIB.Error.format(first_error)}
        end
      {:error, error} -> 
        {:error, "Tokenization failed: #{SnmpLib.MIB.Error.format(error)}"}
    end
  end
  
  # Test case definitions
  
  defp basic_module_compliance do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    basicCompliance MODULE-COMPLIANCE
        STATUS current
        DESCRIPTION "Basic compliance statement for test MIB"
        ::= { compliances 1 }
    
    END
    """
  end
  
  defp with_mandatory_groups do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    systemCompliance MODULE-COMPLIANCE
        STATUS current
        DESCRIPTION "System compliance requirements"
        MANDATORY-GROUPS { 
            systemGroup,
            snmpGroup,
            snmpSetGroup
        }
        ::= { compliances 2 }
    
    END
    """
  end
  
  defp with_object_clauses do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    interfaceCompliance MODULE-COMPLIANCE
        STATUS current
        DESCRIPTION "Interface compliance with object refinements"
        OBJECT ifAdminStatus
            MIN-ACCESS read-only
            DESCRIPTION "Write access not required"
        OBJECT ifOperStatus  
            SYNTAX INTEGER { up(1), down(2) }
            DESCRIPTION "Simplified operational status"
        ::= { compliances 3 }
    
    END
    """
  end
  
  defp complex_module_compliance do
    """
    TEST-MIB DEFINITIONS ::= BEGIN
    
    fullCompliance MODULE-COMPLIANCE
        STATUS current
        DESCRIPTION "Complete compliance statement with all clauses"
        REFERENCE "RFC 2863 - Interface MIB"
        MANDATORY-GROUPS { 
            ifGeneralInformationGroup,
            ifStackGroup
        }
        OBJECT ifAdminStatus
            MIN-ACCESS read-only
            DESCRIPTION "Write access is not required"
        OBJECT ifLinkUpDownTrapEnable
            SYNTAX INTEGER { enabled(1), disabled(2) }
            MIN-ACCESS read-only
            DESCRIPTION "Simplified trap control"
        ::= { compliances 10 }
    
    END
    """
  end
  
  defp real_world_example do
    """
    SNMPv2-CONF DEFINITIONS ::= BEGIN
    
    IMPORTS MODULE-IDENTITY, OBJECT-TYPE FROM SNMPv2-SMI;
    
    snmpBasicCompliance MODULE-COMPLIANCE
        STATUS current
        DESCRIPTION
            "The compliance statement for SNMPv2 entities which
             implement the SNMPv2 MIB."
        REFERENCE "RFC 3418"
        MANDATORY-GROUPS { 
            snmpGroup, 
            snmpSetGroup, 
            systemGroup,
            snmpBasicNotificationsGroup 
        }
        OBJECT snmpSetSerialNo
            SYNTAX TestAndIncr
            MIN-ACCESS read-write
            DESCRIPTION
                "Write access is required for this object."
        ::= { snmpCompliances 2 }
    
    END
    """
  end
end

ModuleComplianceTest.run()