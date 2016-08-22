#include "command.qh"

#include <common/command/_mod.qh>

GENERIC_COMMAND(mx, "Send a matrix command") {
    switch (argv(1)) {
        case "user":
            if (matrix_user) strunzone(matrix_user);
            matrix_user = strzone(substring(command, argv_start_index(2), -1));
            break;
        case "token":
            if (matrix_access_token) strunzone(matrix_access_token);
            matrix_access_token = strzone(substring(command, argv_start_index(2), -1));
            break;
        case "messages":
            MX_Messages(string_null);
            break;
        case "nick":
            MX_Nick(substring(command, argv_start_index(2), -1));
            break;
        case "join":
            string s = substring(command, argv_start_index(2), -1);
            if (s != matrix_room && matrix_room != "") {
                MX_Leave(matrix_room);
                strunzone(matrix_room);
            }
            matrix_room = strzone(s);
            MX_Join(matrix_room);
            break;
        case "sync":
            MX_Sync(string_null);
            break;
        case "typing":
            MX_Typing(true);
            break;
        case "say":
            MX_Say(substring(command, argv_start_index(2), -1));
            break;
        case "leave":
            MX_Leave(matrix_room);
            matrix_room = string_null;
            break;
        case "forget":
            MX_Forget(matrix_room);
            matrix_room = "";
            break;
    }
}
