#include "all.qh"

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

string Item_Sound(string it_snd)
{
	string output = strcat("misc/", it_snd);
#ifdef SVQC
		MUTATOR_CALLHOOK(ItemSound, it_snd, output);
		return M_ARGV(1, string);
#else
		return output;
#endif
}
