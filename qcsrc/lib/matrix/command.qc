#include "command.qh"

#include <common/command/_mod.qh>

GENERIC_COMMAND(mx, "Send a matrix command", false) {
    switch (argv(1)) {
        case "user":
            strcpy(matrix_user, substring(command, argv_start_index(2), -1));
            break;
        case "token":
            strcpy(matrix_access_token, substring(command, argv_start_index(2), -1));
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
