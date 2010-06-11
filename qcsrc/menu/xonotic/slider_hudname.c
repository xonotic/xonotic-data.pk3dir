#ifdef INTERFACE
CLASS(XonoticSliderHUDName) EXTENDS(Slider)
	METHOD(XonoticSliderHUDName, configureXonoticSliderHUDName, void(entity, float, float, float, float))
	METHOD(XonoticSliderHUDName, setValue, void(entity, float))
	ATTRIB(XonoticSliderHUDName, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticSliderHUDName, valueSpace, float, SKINWIDTH_SLIDERTEXT)
	ATTRIB(XonoticSliderHUDName, image, string, SKINGFX_SLIDER)
	ATTRIB(XonoticSliderHUDName, tolerance, vector, SKINTOLERANCE_SLIDER)
	ATTRIB(XonoticSliderHUDName, align, float, 0.5)
	ATTRIB(XonoticSliderHUDName, color, vector, SKINCOLOR_SLIDER_N)
	ATTRIB(XonoticSliderHUDName, colorC, vector, SKINCOLOR_SLIDER_C)
	ATTRIB(XonoticSliderHUDName, colorF, vector, SKINCOLOR_SLIDER_F)
	ATTRIB(XonoticSliderHUDName, colorD, vector, SKINCOLOR_SLIDER_D)
	ATTRIB(XonoticSliderHUDName, color2, vector, SKINCOLOR_SLIDER_S)

	ATTRIB(XonoticSliderHUDName, setting, float, 0)
	METHOD(XonoticSliderHUDName, loadCvars, void(entity))
	METHOD(XonoticSliderHUDName, saveCvars, void(entity))

	ATTRIB(XonoticSliderHUDName, alpha, float, SKINALPHA_TEXT)
	ATTRIB(XonoticSliderHUDName, disabledAlpha, float, SKINALPHA_DISABLED)
ENDCLASS(XonoticSliderHUDName)
entity makeXonoticSliderHUDName(float, float, float, float);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticSliderHUDName(float theValueMin, float theValueMax, float theValueStep, float theSetting)
{
	entity me;
	me = spawnXonoticSliderHUDName();
	me.configureXonoticSliderHUDName(me, theValueMin, theValueMax, theValueStep, theSetting);
	return me;
}
void configureXonoticSliderHUDNameXonoticSliderHUDName(entity me, float theValueMin, float theValueMax, float theValueStep, float theSetting)
{
	float v, vk, vp;
	v = theValueMin;
	vk = theValueStep;
	vp = theValueStep * 10;
	while(fabs(vp) < fabs(theValueMax - theValueMin) / 40)
		vp *= 10;
	me.configureSliderVisuals(me, me.fontSize, me.align, me.valueSpace, me.image);
	me.configureSliderValues(me, theValueMin, v, theValueMax, theValueStep, vk, vp);

	me.setting = theSetting;
	me.loadCvars(me);
	// TODO: Tooltips.
	//if(tooltipdb >= 0)
	//	me.tooltip = getZonedTooltipForIdentifier(theCvar);
}
void setValueXonoticSliderHUDName(entity me, float val)
{
	if(val != me.value)
	{
		setValueSlider( me, val );
		me.saveCvars(me);
	}
}
void loadCvarsXonoticSliderHUDName(entity me)
{
	me.setValue(me, cvar(strcat("hud_", HUD_Panel_GetName(highlightedPanel), HUD_Panel_GetSettingName(me.setting))));
}
void saveCvarsXonoticSliderHUDName(entity me)
{
	cvar_set(strcat("hud_", HUD_Panel_GetName(highlightedPanel), HUD_Panel_GetSettingName(me.setting)), ftos(me.value));
}
#endif
