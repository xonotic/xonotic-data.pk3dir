#include "matrix.qh"

#include <server/chat.qh>

var void MX_Handle(int buf, string ancestor)
{
    string type = json_get(buf, strcat(ancestor, ".type"));
    switch (type) {
        case "m.room.message": {
            string msgtype = json_get(buf, strcat(ancestor, ".content.msgtype"));
            switch (msgtype) {
                case "m.text": {
                    string sender = json_get(buf, strcat(ancestor, ".sender"));
                    string body = json_get(buf, strcat(ancestor, ".content.body"));
                    if (sender != matrix_user && body) Say(NULL, false, NULL, body, false);
                    break;
                }
            }
            break;
        }
    }
}
