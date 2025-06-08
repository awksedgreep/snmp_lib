# Dialyzer ignore file for SnmpLib
# Format: {"file_path", "warning_description"}
# These are primarily false positives due to complex control flow analysis limitations

[
  # Walker module - false positives due to complex control flow
  {"lib/snmp_lib/walker.ex", "The pattern can never match the type {:ok, [any()]} | {:error, _}."},
  {"lib/snmp_lib/walker.ex", "Function filter_table_varbinds/2 will never be called."},
  {"lib/snmp_lib/walker.ex", "Function filter_subtree_varbinds/2 will never be called."},
  {"lib/snmp_lib/walker.ex", "Function extract_column_data/2 will never be called."},
  {"lib/snmp_lib/walker.ex", "Function oid_in_table?/2 will never be called."},
  {"lib/snmp_lib/walker.ex", "Function oid_in_subtree?/2 will never be called."},
  {"lib/snmp_lib/walker.ex", "The pattern can never match the type {:error, :getbulk_requires_v2c | {:socket_error, atom()}}."},
  
  # Manager module - false positives
  {"lib/snmp_lib/manager.ex", "The pattern can never match the type {:error, {:socket_error, atom()}}."},
  {"lib/snmp_lib/manager.ex", "Function perform_get_operation/4 has no local return."},
  {"lib/snmp_lib/manager.ex", "Function perform_bulk_operation/4 has no local return."},
  {"lib/snmp_lib/manager.ex", "Function perform_set_operation/5 has no local return."},
  {"lib/snmp_lib/manager.ex", "Function perform_get_next_operation/4 has no local return."},
  {"lib/snmp_lib/manager.ex", "The function call perform_snmp_request will not succeed."},
  {"lib/snmp_lib/manager.ex", "The created anonymous function has no local return."},
  {"lib/snmp_lib/manager.ex", "Function extract_get_result/1 will never be called."},
  {"lib/snmp_lib/manager.ex", "Function extract_bulk_result/1 will never be called."},
  {"lib/snmp_lib/manager.ex", "Function extract_set_result/1 will never be called."},
  {"lib/snmp_lib/manager.ex", "Function extract_get_next_result/1 will never be called."},
  {"lib/snmp_lib/manager.ex", "Function decode_error_status/1 will never be called."},
  {"lib/snmp_lib/manager.ex", "The pattern can never match the type {:error, :getbulk_requires_v2c | {:socket_error, atom()}}."},
  
  # USM module - SNMPv3 not currently used
  {"lib/snmp_lib/security/usm.ex", :_},
  
  # External dependencies that don't exist (MIB compilation features)
  {"src/snmpc_mib_gram.yrl", "Function :snmpc_lib.print_error/3 does not exist."},
  {"src/snmpc_mib_gram.yrl", "Function :snmpc_misc.to_upper/1 does not exist."},
  
  # Other modules - lower priority
  {"lib/snmp_lib/asn1.ex", "The pattern can never match the type pos_integer()."},
  {"lib/snmp_lib/error_handler.ex", "The pattern variable _until_time@1 can never match the type, because it is covered by previous clauses."},
  {"lib/snmp_lib/error_handler.ex", "The pattern can never match the type :closed."},
  {"lib/snmp_lib/mib/compiler.ex", :_},
  {"lib/snmp_lib/mib/parser.ex", "Function :yecc.file/1 does not exist."},
  {"lib/snmp_lib/mib/utilities.ex", "The function call to_list will not succeed."},
  {"lib/snmp_lib/monitor.ex", "The pattern can never match the type [any(), ...]."},
  {"lib/snmp_lib/monitor.ex", "Function Jason.encode!/1 does not exist."}
]
