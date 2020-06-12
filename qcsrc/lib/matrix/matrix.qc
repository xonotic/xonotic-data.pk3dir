#include "matrix.qh"

.string message;

void MX_Nick_(entity fh, entity pass, int status);
void MX_Nick(string name)
{
    if (!matrix_access_token) return;
    entity pass = new_pure(mx);
    pass.message = name;
    url_single_fopen(
        sprintf("%s/_matrix/client/r0/profile/%s/displayname?access_token=%s", autocvar_matrix_server, matrix_user, matrix_access_token),
        FILE_WRITE,
        MX_Nick_,
        pass
    );
}
void MX_Nick_(entity fh, entity pass, int status)
{
    switch (status) {
        case URL_READY_CANWRITE: {
            fh.url_verb = "PUT";
            fh.url_content_type = "application/json";
            url_fputs(fh, sprintf("{\"displayname\": \"%s\"}", pass.message));
            delete(pass);
            url_fclose(fh);
            break;
        }
    }
}


void MX_Messages_(entity fh, entity pass, int status);
void MX_Messages(string from)
{
    if (!matrix_access_token) return;
    string s = sprintf("%s/_matrix/client/r0/events?room_id=%s&limit=50&timeout=30000&from=%s&access_token=%s", autocvar_matrix_server, matrix_room, from, matrix_access_token);
    url_single_fopen(
        s,
        FILE_READ,
        MX_Messages_,
        NULL
    );
}
void MX_Messages_(entity fh, entity pass, int status)
{
    switch (status) {
        default: {
            LOG_WARNF("status: %d", status);
            break;
        }
        case URL_READY_CLOSED: break;
        case URL_READY_CANREAD: {
            string json = "";
            for (string s; (s = url_fgets(fh)); ) { json = strcat(json, s, "\n"); }
            url_fclose(fh);
            int buf = json_parse(json, _json_parse_object);
            EXPECT_NE(-1, buf);
            for (int i = 0, n = stof(json_get(buf, "chunk.length")); i < n; ++i) {
                MX_Handle(buf, sprintf("chunk.%d", i));
            }
            MX_Messages(json_get(buf, "end"));
            break;
        }
    }
}


void MX_Sync_(entity fh, entity pass, int status);
void MX_Sync(string since)
{
    if (!matrix_access_token) return;
    string s = strcat(autocvar_matrix_server, "/_matrix/client/r0/sync?");
    if (since) {
        s = strcat(s,
            "since=", since, "&",
            "timeout=30000&",
            sprintf("filter={\"account_data\":{\"types\":[]},\"presence\":{\"types\":[]},\"room\":{\"rooms\":[\"%s\"]}}&", matrix_room)
        );
    } else {
        s = strcat(s,
            "timeout=0&",
            "filter={\"account_data\":{\"types\":[]},\"presence\":{\"types\":[]},\"room\":{\"rooms\":[]}}&"
        );
    }
    s = strcat(s, "access_token=", matrix_access_token);
    url_single_fopen(s, FILE_READ, MX_Sync_, NULL);
}
void MX_Sync_(entity fh, entity pass, int status)
{
    switch (status) {
        default: {
            LOG_WARNF("status: %d", status);
            break;
        }
        case URL_READY_CLOSED: break;
        case URL_READY_CANREAD: {
            string json = "";
            for (string s; (s = url_fgets(fh)); ) { json = strcat(json, s, "\n"); }
            url_fclose(fh);
            int buf = json_parse(json, _json_parse_object);
            EXPECT_NE(-1, buf);
            string arr = sprintf("rooms.join.%s.timeline.events", matrix_room);
            for (int i = 0, n = stof(json_get(buf, sprintf("%s.length", arr))); i < n; ++i) {
                MX_Handle(buf, sprintf("%s.%d", arr, i));
            }
            MX_Sync(json_get(buf, "next_batch"));
            break;
        }
    }
}


void MX_JLF_(entity fh, entity pass, int status);
void MX_Join(string room)
{
    if (!matrix_access_token) return;
    url_single_fopen(
        sprintf("%s/_matrix/client/r0/rooms/%s/join?access_token=%s", autocvar_matrix_server, matrix_room, matrix_access_token),
        FILE_WRITE,
        MX_JLF_,
        NULL
    );
}
void MX_Leave(string room)
{
    if (!matrix_access_token) return;
    url_single_fopen(
        sprintf("%s/_matrix/client/r0/rooms/%s/leave?access_token=%s", autocvar_matrix_server, matrix_room, matrix_access_token),
        FILE_WRITE,
        MX_JLF_,
        NULL
    );
}
void MX_Forget(string room)
{
    if (!matrix_access_token) return;
    url_single_fopen(
        sprintf("%s/_matrix/client/r0/rooms/%s/forget?access_token=%s", autocvar_matrix_server, matrix_room, matrix_access_token),
        FILE_WRITE,
        MX_JLF_,
        NULL
    );
}
void MX_JLF_(entity fh, entity pass, int status)
{
    switch (status) {
        case URL_READY_CANWRITE: {
            fh.url_content_type = "application/json";
            url_fputs(fh, sprintf("{%s}", pass.message));
            url_fclose(fh);
            break;
        }
    }
}


void MX_Typing_(entity fh, entity pass, int status);
void MX_Typing(bool state)
{
    if (!matrix_access_token) return;
    entity pass = new_pure(mx);
    pass.message = state ? "true" : "false";
    url_single_fopen(
        sprintf("%s/_matrix/client/r0/rooms/%s/typing/%s?access_token=%s", autocvar_matrix_server, matrix_room, matrix_user, matrix_access_token),
        FILE_WRITE,
        MX_Typing_,
        pass
    );
}
void MX_Typing_(entity fh, entity pass, int status)
{
    switch (status) {
        case URL_READY_CANWRITE: {
            fh.url_verb = "PUT";
            fh.url_content_type = "application/json";
            url_fputs(fh, sprintf("{\"typing\": %s, \"timeout\": 30000}", pass.message));
            delete(pass);
            url_fclose(fh);
            break;
        }
    }
}


void MX_Say_(entity fh, entity pass, int status);
void MX_Say(string body)
{
    if (!matrix_access_token) return;
    static int txnid;
    entity pass = new_pure(mx);
    pass.message = strzone(body);
    url_single_fopen(
        sprintf("%s/_matrix/client/r0/rooms/%s/send/m.room.message/%d?access_token=%s", autocvar_matrix_server, matrix_room, ++txnid, matrix_access_token),
        FILE_WRITE,
        MX_Say_,
        pass
    );
}
void MX_Say_(entity fh, entity pass, int status)
{
    switch (status) {
        case URL_READY_CANWRITE: {
            fh.url_verb = "PUT";
            fh.url_content_type = "application/json";
            url_fputs(fh, sprintf("{\"msgtype\": \"m.text\", \"body\": \"%s\"}", pass.message));
            strfree(pass.message);
            delete(pass);
            url_fclose(fh);
            break;
        }
    }
}
