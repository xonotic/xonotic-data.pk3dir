#include "mixedslider.qh"

entity makeXonoticMixedSlider_T(string theCvar, string theTooltip)
{
	entity me;
	me = NEW(XonoticMixedSlider);
	me.configureXonoticMixedSlider(me, theCvar, theTooltip);
	return me;
}
entity makeXonoticMixedSlider(string theCvar)
{
	return makeXonoticMixedSlider_T(theCvar, string_null);
}
void XonoticMixedSlider_configureXonoticMixedSlider(entity me, string theCvar, string theTooltip)
{
	me.configureSliderVisuals(me, me.fontSize, me.align, me.valueSpace, me.image);
	me.controlledCvar = (theCvar) ? theCvar : string_null;
	// me.loadCvars(me); // don't load it yet
	setZonedTooltip(me, theTooltip, theCvar);
}
void XonoticMixedSlider_setValue(entity me, float val)
{
	if (val != me.value)
	{
		SUPER(XonoticMixedSlider).setValue(me, val);
		me.saveCvars(me);
	}
}
void XonoticMixedSlider_setValue_noAnim(entity me, float val)
{
	if (val != me.value)
	{
		SUPER(XonoticMixedSlider).setValue_noAnim(me, val);
		me.saveCvars(me);
	}
}
void XonoticMixedSlider_loadCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	// don't call setValue_noAnim or else it will call saveCvars
	me.setValueFromNumberIdentifier_noAnim(me, cvar(me.controlledCvar));
}
void XonoticMixedSlider_saveCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	cvar_set(me.controlledCvar, ftos_mindecimals(me.getNumberIdentifier(me)));

	CheckSendCvars(me, me.controlledCvar);
}
void XonoticMixedSlider_configureXonoticMixedSliderValues(entity me)
{
	me.configureMixedSliderValues(me, 0);
	me.loadCvars(me);
}
