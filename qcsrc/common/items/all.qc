#ifndef ALL_C
#define ALL_C
#include "all.qh"

#include "all.inc"

void ItemTest()
{
    ITEMS_FOREACH(it != NULL, LAMBDA({
        print(strcat(etos(it), "\n"));
        ITEM_HANDLE(Show, it);
    }));
}

#endif
