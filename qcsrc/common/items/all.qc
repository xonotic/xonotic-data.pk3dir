#ifndef ALL_C
#define ALL_C
#include "all.qh"

#include "all.inc"

void Dump_Items()
{
    ITEMS_FOREACH(true, LAMBDA({
        ITEM_HANDLE(Show, it);
    }));
}

#endif
