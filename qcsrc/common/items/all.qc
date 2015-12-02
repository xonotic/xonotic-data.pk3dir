#ifndef ITEMS_ALL_C
#define ITEMS_ALL_C
#include "all.qh"

#include "all.inc"

void Dump_Items()
{
    FOREACH(Items, true, LAMBDA(
        ITEM_HANDLE(Show, it);
    ));
}

string Item_Model(string item_mdl)
{
    string output = strcat("models/items/", item_mdl);
#ifdef SVQC
    MUTATOR_CALLHOOK(ItemModel, item_mdl, output);
    output = item_model_output;
#endif
    return output;
}

#endif
