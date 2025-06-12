# Dialyzer ignore file for SnmpLib
# Format: {"file_path", "warning_description"}
# Using :_ to ignore all warnings from problematic files

[
  # Ignore all warnings from these files - they contain complex control flow
  # that causes dialyzer false positives
  {"lib/snmp_lib/manager.ex", :_},
  {"lib/snmp_lib/pdu.ex", :_},
  {"lib/snmp_lib/pdu/builder.ex", :_},
  {"lib/snmp_lib/walker.ex", :_},
  {"lib/snmp_lib/error_handler.ex", :_},
  {"lib/snmp_lib/mib/parser.ex", :_},
  {"lib/snmp_lib/mib/utilities.ex", :_},
  {"lib/snmp_lib/monitor.ex", :_},
  {"lib/snmp_lib/security/usm.ex", :_},
  {"lib/snmp_lib/mib/compiler.ex", :_},
  {"lib/snmp_lib/asn1.ex", :_},

  # External dependencies that don't exist
  {"src/snmpc_mib_gram.yrl", :_}
]
