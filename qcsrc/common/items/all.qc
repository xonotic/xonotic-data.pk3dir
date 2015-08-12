#ifndef ITEMS_ALL_C
#define ITEMS_ALL_C
#include "all.qh"

#include "all.inc"

void Dump_Items()
{
    ITEMS_FOREACH(true, LAMBDA({
        ITEM_HANDLE(Show, it);
    }));
}

#endif
