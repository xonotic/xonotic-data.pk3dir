#include "nexposee.qh"

entity makeXonoticNexposee()
{
	entity me;
	me = NEW(XonoticNexposee);
	return me;
}

void XonoticNexposee_close(entity me)
{
	m_goto(string_null, true); // hide
}
