#include "image.qh"

entity makeXonoticImage(string theImage, float theAspect)
{
	entity me;
	me = NEW(XonoticImage);
	me.configureXonoticImage(me, theImage, theAspect);
	return me;
}
void XonoticImage_configureXonoticImage(entity me, string theImage, float theAspect)
{
	me.configureImage(me, theImage);
	me.forcedAspect = theAspect;
}
