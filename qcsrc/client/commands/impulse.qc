#include "impulse.qh"

STATIC_INIT(impulse) {
    registercommand("impulse");
}

string impulse_sentinel = "!";

bool impulse_handle(string arg)
{
    // taking advantage of atoi's behaviour in the engine to ignore non-digits to prevent re-entry
    if (endsWith(arg, impulse_sentinel)) {
        // pass to engine
        return false;
    }
    int req = stoi(arg);
    switch (req) {
        default: {
            impulse_var = req;
            break;
        }
    }
    return true;
}

void impulse_set(int value)
{
    localcmd(sprintf("impulse %d%s\n", value, impulse_sentinel));
}

void impulse_frame_end()
{
    impulse_set(impulse_var);
}
