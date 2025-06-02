%%
%% SNMP types header file - Elixir compatibility
%%

%% Basic SNMP data structure for parsed MIB data
-record(pdata, {
    mib_version,    % v1_mib | v2_mib
    mib_name,       % MIB module name
    imports,        % Import definitions
    defs            % List of definitions
}).

%% Module Identity record
-record(mc_module_identity, {
    name,
    last_updated,
    organization,
    contact_info,
    description,
    revisions,
    name_assign
}).

%% Revision record
-record(mc_revision, {
    revision,
    description
}).

%% Object Type record
-record(mc_object_type, {
    name,
    syntax,
    units,
    max_access,
    status,
    description,
    reference,
    kind,
    name_assign
}).

%% New Type record
-record(mc_new_type, {
    name,
    macro,
    status,
    description,
    reference,
    display_hint,
    syntax
}).

%% Trap record
-record(mc_trap, {
    name,
    enterprise,
    vars,
    description,
    reference,
    num
}).

%% Notification record
-record(mc_notification, {
    name,
    vars,
    status,
    description,
    reference,
    name_assign
}).

%% Agent Capabilities record
-record(mc_agent_capabilities, {
    name,
    product_release,
    status,
    description,
    reference,
    modules,
    name_assign
}).

%% Agent Capabilities Variation records
-record(mc_ac_notification_variation, {
    name,
    access,
    description
}).

-record(mc_ac_object_variation, {
    name,
    syntax,
    write_syntax,
    access,
    creation,
    default_value,
    description
}).

%% Agent Capabilities Module record
-record(mc_ac_module, {
    name,
    groups,
    variation
}).

%% Module Compliance record
-record(mc_module_compliance, {
    name,
    status,
    description,
    reference,
    modules,
    name_assign
}).

%% Module Compliance Module record
-record(mc_mc_module, {
    name,
    mandatory,
    compliance
}).

%% Module Compliance Group record
-record(mc_mc_compliance_group, {
    name,
    description
}).

%% Module Compliance Object record
-record(mc_mc_object, {
    name,
    syntax,
    write_syntax,
    access,
    description
}).

%% Object Group record
-record(mc_object_group, {
    name,
    objects,
    status,
    description,
    reference,
    name_assign
}).

%% Notification Group record
-record(mc_notification_group, {
    name,
    objects,
    status,
    description,
    reference,
    name_assign
}).

%% Sequence record
-record(mc_sequence, {
    name,
    fields
}).

%% Internal record
-record(mc_internal, {
    name,
    macro,
    parent,
    sub_index
}).