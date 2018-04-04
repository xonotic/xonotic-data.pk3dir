#include "notice.qh"

#include <common/sounds/all.qh>

noref string autocvar__cl_hook_print = "menu_cmd notice";

GENERIC_COMMAND(notice, "Append a notice to chat")
{
    switch(request)
    {
        case CMD_REQUEST_COMMAND:
        {
            string s = console_decode(substring(command, argv_start_index(1), argv_end_index(-1)));
            for (int i = 0, n = tokenizebyseparator(s, "\n"); i < n; ++i)
            {
                string s = ColorTranslateRGB(argv(i));
                int c = str2chr(s, 0);
                if (c == 1 || c == 3) {
                    // visible in chat
                    s = substring(s, 1, -1);
                    if (c == 1) {
                        entity snd;
                        if (str2chr(s, 0) == '\r') {
                            s = substring(s, 1, -1);
                            snd = SND_TALK2;
                        } else {
                            snd = SND_TALK;
                        }
                        localsound(Sound_fixpath(snd));
                    }
                    s = strcat("^3", s);
                } else {
                    // not visible in chat
                    s = strcat("^7", s);
                }
                print(s, "\n");
            }
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
