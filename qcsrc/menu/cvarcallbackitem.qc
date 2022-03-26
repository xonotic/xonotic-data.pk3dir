#include "cvarcallbackitem.qh"

entity createCvarCallbackItem(string theCvarName, cvar_callback theCallback, entity theContext)
{
	entity item;
	item = NEW(CvarCallbackItem);
	item.cvarName = theCvarName;
	item.callback = theCallback;
	item.context = theContext;
	return item;
}