#include "nexposee.qh"

entity makeXonoticNexposee()
{
	entity me;
	me = NEW(XonoticNexposee);
	me.configureXonoticNexposee(me);
	return me;
}

void XonoticNexposee_configureXonoticNexposee(entity me)
{
}

void XonoticNexposee_close(entity me)
{
	m_goto(string_null); // hide
}
