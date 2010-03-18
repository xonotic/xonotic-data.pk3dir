#ifdef INTERFACE
CLASS(XonoticImage) EXTENDS(Image)
	METHOD(XonoticImage, configureXonoticImage, void(entity, string, float))
ENDCLASS(XonoticImage)
entity makeXonoticImage(string theImage, float theAspect);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticImage(string theImage, float theAspect)
{
	entity me;
	me = spawnXonoticImage();
	me.configureXonoticImage(me, theImage, theAspect);
	return me;
}
void configureXonoticImageXonoticImage(entity me, string theImage, float theAspect)
{
	me.configureImage(me, theImage);
	if(theAspect < 0) // use image aspect
	{
		vector sz;
		sz = draw_PictureSize(theImage);
		me.forcedAspect = sz_x / sz_y;
	}
	else
		me.forcedAspect = theAspect;
}
#endif
