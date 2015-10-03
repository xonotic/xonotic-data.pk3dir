#ifndef SLIDER_H
#define SLIDER_H
#include "../item/slider.qc"
CLASS(XonoticSlider, Slider)
	METHOD(XonoticSlider, configureXonoticSlider, void(entity, float, float, float, string, string));
	METHOD(XonoticSlider, setValue, void(entity, float));
	ATTRIB(XonoticSlider, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticSlider, valueSpace, float, SKINWIDTH_SLIDERTEXT)
	ATTRIB(XonoticSlider, image, string, SKINGFX_SLIDER)
	ATTRIB(XonoticSlider, tolerance, vector, SKINTOLERANCE_SLIDER)
	ATTRIB(XonoticSlider, align, float, 0.5)
	ATTRIB(XonoticSlider, color, vector, SKINCOLOR_SLIDER_N)
	ATTRIB(XonoticSlider, colorC, vector, SKINCOLOR_SLIDER_C)
	ATTRIB(XonoticSlider, colorF, vector, SKINCOLOR_SLIDER_F)
	ATTRIB(XonoticSlider, colorD, vector, SKINCOLOR_SLIDER_D)
	ATTRIB(XonoticSlider, color2, vector, SKINCOLOR_SLIDER_S)

	ATTRIB(XonoticSlider, cvarName, string, string_null)
	METHOD(XonoticSlider, loadCvars, void(entity));
	METHOD(XonoticSlider, saveCvars, void(entity));
	ATTRIB(XonoticSlider, sendCvars, float, 0)

	ATTRIB(XonoticSlider, alpha, float, SKINALPHA_TEXT)
	ATTRIB(XonoticSlider, disabledAlpha, float, SKINALPHA_DISABLED)
ENDCLASS(XonoticSlider)
entity makeXonoticSlider_T(float, float, float, string, string theTooltip);
entity makeXonoticSlider(float, float, float, string);
#endif

#ifdef IMPLEMENTATION
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

	me.cvarName = (theCvar) ? theCvar : string_null;
	if(theCvar)
		// Prevent flickering of the slider button by initialising the
		// slider out of bounds to hide the button before loading the cvar
		me.configureSliderValues(me, theValueMin, theValueMin-theValueStep, theValueMax, theValueStep, theValueStep, vp);
	else
		me.configureSliderValues(me, theValueMin, theValueMin, theValueMax, theValueStep, theValueStep, vp);
	me.loadCvars(me);
	setZonedTooltip(me, theTooltip, theCvar);
}
void XonoticSlider_setValue(entity me, float val)
{
	if(val != me.value)
	{
		SUPER(XonoticSlider).setValue( me, val );
		me.saveCvars(me);
	}
}
void XonoticSlider_loadCvars(entity me)
{
	if (!me.cvarName)
		return;

	me.setValue_noAnim(me, cvar(me.cvarName));
}
void XonoticSlider_saveCvars(entity me)
{
	if (!me.cvarName)
		return;

	cvar_set(me.cvarName, ftos(me.value));

	CheckSendCvars(me, me.cvarName);
}
#endif
