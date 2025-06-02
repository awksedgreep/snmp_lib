%%
%% SNMP compiler header file - Elixir compatibility
%%

%% Version warning macro
-define(vwarning(Format, Args), 
    io:format("Warning: " ++ Format ++ "~n", Args)).