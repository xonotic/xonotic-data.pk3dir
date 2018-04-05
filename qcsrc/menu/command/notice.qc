#include "notice.qh"

#include <common/sounds/all.qh>

noref string autocvar__cl_hook_print = "menu_cmd notice";

GENERIC_COMMAND(notice, "Append a notice to chat")
{
    switch(request)
    {
        case CMD_REQUEST_COMMAND:
        {
            int flags = stoi(argv(1));
            string s = console_decode(substring(command, argv_start_index(2), argv_end_index(-1)));
            s = ColorTranslateRGB(s);
            string prefix = (flags & NOTICE_CHAT) ? "\{3}" : "";
            if (!(flags & NOTICE_SILENT)) {
                entity snd = (flags & NOTICE_PRIVATE) ? SND_TALK2 : SND_TALK;
                localsound(Sound_fixpath(snd));
            }
            print(prefix, "^7", s, "\n");
            return;
        }

        default:
        case CMD_REQUEST_USAGE:
        {
            LOG_INFO("Usage:^3 ", GetProgramCommandPrefix(), " notice message");
            LOG_INFO("  Where 'message' is the message to append.");
            return;
        }
    }
}
