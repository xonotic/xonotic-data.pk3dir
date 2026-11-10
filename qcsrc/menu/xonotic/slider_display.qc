#include "slider_display.qh"

entity makeXonoticDisplaySlider()
{
	entity me = NEW(XonoticDisplaySlider);
	me.configureXonoticDisplaySlider(me);
	return me;
}

void XonoticDisplaySlider_configureXonoticDisplaySlider(entity me)
{
	me.configureXonoticMixedSlider(me, "_menu_vid_display", _("Display number"));
	me.vid_info_displaycount = cvar("vid_info_displaycount");
	me.rebuildValues(me);
}

void XonoticDisplaySlider_rebuildValues(entity me)
{
	me.clearValues(me);
	for (int i = 0; i < me.vid_info_displaycount; ++i)
		me.addText(me, strzone(count_ordinal(i + 1)), i); // TODO: display names
	me.configureXonoticMixedSliderValues(me); // calls .loadCvars

	bool disable = (me.vid_info_displaycount <= 1); // only 1 display (... or 0)
	me.disabled = disable;
	if (me.controlledTextLabel)
		me.controlledTextLabel.disabled = disable;
}

void XonoticDisplaySlider_loadCvars(entity me)
{
	int count = cvar("vid_info_displaycount");
	if (count != me.vid_info_displaycount)
	{
		me.vid_info_displaycount = count;
		me.rebuildValues(me);
	}
	SUPER(XonoticDisplaySlider).loadCvars(me);
}
