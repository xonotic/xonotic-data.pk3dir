#include "commands.qh"

#include "state.qh"

// space separated list of extensions
void extensions_set(string s)
{
    for (int i = 0, n = extensions_count(); i < n; ++i) {
        string id = extensions_get_name(i);
        void(bool) set = extensions_get_setter(i);
        bool enable = strhasword(s, id);
        set(enable);
    }
}

GENERIC_COMMAND(_cl_hook_gamestart, "_cl_hook_gamestart", true)
{
    switch(request)
    {
        case CMD_REQUEST_COMMAND:
        {
            string s = substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1));
            localcmd("\nset _cl_hook_gametype ", s, "; _cl_hook_gamestart_stage2\n");
            extensions_set(cvar_string("_cl_extensions"));
            cvar_set("_cl_extensions", "");
            return;
        }

        default:
        case CMD_REQUEST_USAGE:
        {
            return;
        }
    }
}

GENERIC_COMMAND(_cl_extensions, "_cl_extensions", true)
{
    switch(request)
    {
        case CMD_REQUEST_COMMAND:
        {
            string s = substring(command, argv_start_index(1), argv_end_index(-1) - argv_start_index(1));
            extensions_set(s);
            return;
        }

        default:
        case CMD_REQUEST_USAGE:
        {
            return;
        }
    }
}
