#include "state.qh"

int extensions_buffer;
int extensions_buffer_idx;

STATIC_INIT_EARLY(extensions_buffer)
{
    extensions_buffer = buf_create();
}

int extensions_count()
{
    return extensions_buffer_idx;
}

string extensions_get(int i, int fld)
{
    return bufstr_get(extensions_buffer, i * _EXTENSIONS_FIELDS + fld);
}

void extensions_register(string id, void(bool) set)
{
    int i = extensions_buffer_idx++ * _EXTENSIONS_FIELDS;
    bufstr_set(extensions_buffer, i + EXTENSIONS_NAME, id);
    bufstr_set(extensions_buffer, i + EXTENSIONS_SETTER, ftos(ITOF(reinterpret_cast(int, set))));
}
