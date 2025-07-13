#include "slider.qh"

entity makeXonoticSlider_T(float theValueMin, float theValueMax, float theValueStep, string theCvar, string theTooltip)
{
	entity me;
	me = NEW(XonoticSlider);
	me.configureXonoticSlider(me, theValueMin, theValueMax, theValueStep, theCvar, theTooltip);
	return me;
}
entity makeXonoticSlider(float theValueMin, float theValueMax, float theValueStep, string theCvar)
{
	return makeXonoticSlider_T(theValueMin, theValueMax, theValueStep, theCvar, string_null);
}
void XonoticSlider_configureXonoticSlider(entity me, float theValueMin, float theValueMax, float theValueStep, string theCvar, string theTooltip)
{
	float vp;
	vp = theValueStep * 10;
	while(fabs(vp) < fabs(theValueMax - theValueMin) / 40)
		vp *= 10;

	me.configureSliderVisuals(me, me.fontSize, me.align, me.valueSpace, me.image);

	me.controlledCvar = (theCvar) ? theCvar : string_null;
	if(theCvar)
		// Prevent flickering of the slider button by initialising the
		// slider out of bounds to hide the button before loading the cvar
		me.configureSliderValues(me, theValueMin, theValueMin-theValueStep, theValueMax, theValueStep, theValueStep, vp);
	else
		me.configureSliderValues(me, theValueMin, theValueMin, theValueMax, theValueStep, theValueStep, vp);
	me.loadCvars(me);
	setZonedTooltip(me, theTooltip, theCvar);
}
void XonoticSlider_setValue(entity me, float val, bool allowAnim)
{
	if(val != me.value)
	{
		SUPER(XonoticSlider).setValue(me, val, allowAnim);
		me.saveCvars(me);

		if(me.onChange)
			me.onChange(me, me.onChangeEntity);
	}
}
void XonoticSlider_setValueSpace(entity me, float val)
{
	me.valueSpace = val;
	me.configureSliderVisuals(me, me.fontSize, me.align, me.valueSpace, me.image);
}
void XonoticSlider_loadCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	me.setValue(me, cvar(me.controlledCvar), false);
}
void XonoticSlider_saveCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	cvar_set(me.controlledCvar, ftos_mindecimals(me.value));

	CheckSendCvars(me, me.controlledCvar);
}
