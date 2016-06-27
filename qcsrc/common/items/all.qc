#ifndef ITEMS_ALL_C
#define ITEMS_ALL_C
#include "all.qh"

#include "item/_mod.inc"

void Dump_Items()
{
    FOREACH(Items, true, ITEM_HANDLE(Show, it));
}

string Item_Model(string item_mdl)
{
    string output = strcat("models/items/", item_mdl);
#ifdef SVQC
    MUTATOR_CALLHOOK(ItemModel, item_mdl, output);
    output = M_ARGV(1, string);
#endif
    return output;
}

#endif
