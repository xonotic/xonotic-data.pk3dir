#ifndef ITEMS_ALL_C
#define ITEMS_ALL_C
#include "all.qh"

#include "all.inc"

void Dump_Items()
{
    FOREACH(ITEMS, 0, ITEM_COUNT, true, LAMBDA({
        ITEM_HANDLE(Show, it);
    }));
}

#endif
