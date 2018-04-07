#include "state.qh"

int chat_buffer;
int chat_buffer_idx;

STATIC_INIT(chat_buffer) {
    chat_buffer = buf_create();
}

int chat_lines_count() {
    return chat_buffer_idx + 1;
}

string chat_lines_get(int i) {
    return bufstr_get(chat_buffer, i);
}

void chat_lines_push(string s) {
    bufstr_set(chat_buffer, chat_buffer_idx++, s);
}
