#include "commands.qh"

#include <common/sounds/all.qh>

#include "state.qh"

noref string autocvar__cl_hook_print = "menu_cmd notice";

GENERIC_COMMAND(notice, "Append a notice to chat", true)
{
    switch(request)
    {
        case CMD_REQUEST_COMMAND:
        {
            string s = console_decode(substring(command, argv_start_index(1), argv_end_index(1) - argv_start_index(1)));
            int flags = stoi(argv(2));
            s = ColorTranslateRGB(s);
            string prefix = (flags & NOTICE_CHAT) ? "\{3}" : "";
            if (!(flags & NOTICE_SILENT)) {
                entity snd = (flags & NOTICE_PRIVATE) ? SND_TALK2 : SND_TALK;
                localsound(Sound_fixpath(snd));
            }
            chat_lines_push(s);
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

void m_goto(string name);

GENERIC_COMMAND(commandmode, "input a console command", true)
{
    switch(request)
    {
        case CMD_REQUEST_COMMAND:
        {
            if (!autoextension_chat) {
                return;
            }
            string prefix = arguments > 1 ? strcat(substring(command, argv_start_index(1), argv_end_index(-1)), " ") : "";
            chat_command = "";
            strcpy(chat_text, prefix);
            if (!isdemo()) {
                m_goto("Chat");
            }
            return;
        }

        default:
        case CMD_REQUEST_USAGE:
        {
            LOG_INFO("Usage:^3 ", GetProgramCommandPrefix(), " commandmode [prefix]");
            return;
        }
    }
}

GENERIC_COMMAND(messagemode, "input a chat message to say to everyone", true)
{
    switch(request)
    {
        case CMD_REQUEST_COMMAND:
        {
            if (!autoextension_chat) {
                return;
            }
            string prefix = arguments > 1 ? strcat(substring(command, argv_start_index(1), argv_end_index(-1)), " ") : "";
            chat_command = "say ";
            strcpy(chat_text, prefix);
            if (!isdemo()) {
                m_goto("Chat");
            }
            return;
        }

        default:
        case CMD_REQUEST_USAGE:
        {
            LOG_INFO("Usage:^3 ", GetProgramCommandPrefix(), " messagemode [prefix]");
            return;
        }
    }
}

GENERIC_COMMAND(messagemode2, "input a chat message to say to only your team", true)
{
    switch(request)
    {
        case CMD_REQUEST_COMMAND:
        {
            if (!autoextension_chat) {
                return;
            }
            string prefix = arguments > 1 ? strcat(substring(command, argv_start_index(1), argv_end_index(-1)), " ") : "";
            chat_command = "say_team ";
            strcpy(chat_text, prefix);
            if (!isdemo()) {
                m_goto("Chat");
            }
            return;
        }

        default:
        case CMD_REQUEST_USAGE:
        {
            LOG_INFO("Usage:^3 ", GetProgramCommandPrefix(), " messagemode2 [prefix]");
            return;
        }
    }
}
