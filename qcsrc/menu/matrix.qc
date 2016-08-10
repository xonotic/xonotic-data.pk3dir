#include "matrix.qh"

var void MX_Handle(int buf, string ancestor)
{
    string type = json_get(buf, strcat(ancestor, ".type"));
    switch (type) {
        case "m.typing": {
            string arr = strcat(ancestor, ".content.user_ids");
            for (int i = 0, n = stof(json_get(buf, sprintf("%s.length", arr))); i < n; ++i) {
                string s = json_get(buf, sprintf("%s.%d", arr, i));
                print("\{1}", s, " is typing...\n");
            }
            break;
        }
        case "m.room.message": {
            string msgtype = json_get(buf, strcat(ancestor, ".content.msgtype"));
            switch (msgtype) {
                case "m.text": {
                    string sender = json_get(buf, strcat(ancestor, ".sender"));
                    string body = json_get(buf, strcat(ancestor, ".content.body"));
                    if (body) print("\{1}", sender, ": ", body, "\n");
                    break;
                }
            }
            break;
        }
    }
}
