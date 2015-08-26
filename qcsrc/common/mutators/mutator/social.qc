#ifdef MENUQC
REGISTER_MUTATOR(social, true);

void Social_send(int to, string msg);

string Social_invite_accept;

void Social_parse(entity fh, entity pass, int status)
{
	switch (status) {
		case URL_READY_CANWRITE: {
		    string msg = pass.message;
			url_fputs(fh, msg);
			url_fputs(fh, "\n");
			url_fclose(fh);
			break;
		}
		case URL_READY_CANREAD: {
		    string first = url_fgets(fh);
		    if (first == "") return;
		    int id = stoi(first);
		    printf("from player %d:\n", id);
		    string cmd = url_fgets(fh);
		    switch (cmd) {
		        case "ping":
		            Social_send(id, "pong");
		        case "pong":
		            printf("Player %d is online\n", id);
		            break;
		        case "msg":
		            for (string input; (input = url_fgets(fh)); ) {
                        print(input, "\n");
                    }
                    break;
                case "invite": {
                    string s = url_fgets(fh);
                    printf("Player %d has invited you to %s; `menu_cmd saccept` to join\n", id, s);
                    Social_invite_accept = sprintf("\nconnect %s\n", s);
                    break;
                }
		        default:
                    printf("Social_parse(): '%s'\n", cmd);
                    break;
		    }
			url_fclose(fh);
			break;
		}
		case URL_READY_CLOSED: break;
		case URL_READY_ERROR:
		default:
			printf("Social_parse(): %s\n", ftos(status));
			break;
	}
}

string autocvar_g_social_uri = "http://localhost:5000";

void Social_send(int to, string msg)
{
    entity e = spawn(); e.message = msg;
    if (crypto_getmyidstatus(0) > 0) {
        url_single_fopen(
            sprintf("%s/send?to=%d", autocvar_g_social_uri, to),
            FILE_APPEND,
            Social_parse,
            e
        );
    }
}

void Social_recv()
{
    if (crypto_getmyidstatus(0) > 0) {
        url_single_fopen(
            sprintf("%s/recv", autocvar_g_social_uri),
            FILE_APPEND,
            Social_parse,
            NULL
        );
    }
}

MUTATOR_HOOKFUNCTION(social, GameCommand) {
    if (MUTATOR_RETURNVALUE) return false; // command was already handled
    if (cmd_name == "ssend" && cmd_argc >= 3) {
        int to = stoi(argv(1));
        string msg = substring(cmd_string, argv_start_index(2), argv_end_index(-1) - argv_start_index(2));
        Social_send(to, msg);
        return true;
    }
    if (cmd_name == "sinvite" && cmd_argc == 2) {
        int to = stoi(argv(1));
        Social_send(to, sprintf("%s\n%s", "invite", g_server));
        return true;
    }
    if (cmd_name == "saccept") {
        ServerList_Connect(Social_invite_accept);
        return true;
    }
    if (cmd_name == "srecv") {
        Social_recv();
        return true;
    }
    return false;
}
#endif
