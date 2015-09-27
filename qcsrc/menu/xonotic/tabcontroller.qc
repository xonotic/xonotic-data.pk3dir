#ifndef TABCONTROLLER_H
#define TABCONTROLLER_H
#include "../item/modalcontroller.qc"
CLASS(XonoticTabController, ModalController)
	METHOD(XonoticTabController, configureXonoticTabController, void(entity, float));
	METHOD(XonoticTabController, makeTabButton_T, entity(entity, string, entity, string));
	METHOD(XonoticTabController, makeTabButton, entity(entity, string, entity));
	ATTRIB(XonoticTabController, rows, float, 0)
	ATTRIB(XonoticTabController, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticTabController, image, string, SKINGFX_BUTTON)
ENDCLASS(XonoticTabController)
entity makeXonoticTabController(float theRows);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticTabController(float theRows)
{
	entity me;
	me = NEW(XonoticTabController);
	me.configureXonoticTabController(me, theRows);
	return me;
}
void XonoticTabController_configureXonoticTabController(entity me, float theRows)
{
	me.rows = theRows;
}
entity XonoticTabController_makeTabButton_T(entity me, string theTitle, entity tab, string theTooltip)
{
	entity b;
	if(me.rows != tab.rows)
		error("Tab dialog height mismatch!");
	b = makeXonoticButton_T(theTitle, '0 0 0', theTooltip);
		me.addTab(me, tab, b);
	// TODO make this real tab buttons (with color parameters, and different gfx)
	return b;
}
entity XonoticTabController_makeTabButton(entity me, string theTitle, entity tab)
{
	return XonoticTabController_makeTabButton_T(me, theTitle, tab, string_null);
}
#endif
