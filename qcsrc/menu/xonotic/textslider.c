#ifdef INTERFACE
CLASS(XonoticTextSlider) EXTENDS(TextSlider)
	METHOD(XonoticTextSlider, configureXonoticTextSlider, void(entity, string))
	METHOD(XonoticTextSlider, setValue, void(entity, float))
	METHOD(XonoticTextSlider, configureXonoticTextSliderValues, void(entity))
	ATTRIB(XonoticTextSlider, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticTextSlider, valueSpace, float, SKINWIDTH_SLIDERTEXT)
	ATTRIB(XonoticTextSlider, image, string, SKINGFX_SLIDER)
	ATTRIB(XonoticSlider, tolerance, vector, SKINTOLERANCE_SLIDER)
	ATTRIB(XonoticTextSlider, align, float, 0.5)
	ATTRIB(XonoticSlider, color, vector, SKINCOLOR_SLIDER_N)
	ATTRIB(XonoticSlider, colorC, vector, SKINCOLOR_SLIDER_C)
	ATTRIB(XonoticSlider, colorF, vector, SKINCOLOR_SLIDER_F)
	ATTRIB(XonoticSlider, colorD, vector, SKINCOLOR_SLIDER_D)
	ATTRIB(XonoticSlider, color2, vector, SKINCOLOR_SLIDER_S)

	ATTRIB(XonoticTextSlider, cvarName, string, string_null)
	METHOD(XonoticTextSlider, loadCvars, void(entity))
	METHOD(XonoticTextSlider, saveCvars, void(entity))

	ATTRIB(XonoticTextSlider, alpha, float, SKINALPHA_TEXT)
	ATTRIB(XonoticTextSlider, disabledAlpha, float, SKINALPHA_DISABLED)
ENDCLASS(XonoticTextSlider)
entity makeXonoticTextSlider(string); // note: you still need to call addValue and configureXonoticTextSliderValues!
#endif

#ifdef IMPLEMENTATION
entity makeXonoticTextSlider(string theCvar)
{
	entity me;
	me = spawnXonoticTextSlider();
	me.configureXonoticTextSlider(me, theCvar);
	return me;
}
void configureXonoticTextSliderXonoticTextSlider(entity me, string theCvar)
{
	me.configureSliderVisuals(me, me.fontSize, me.align, me.valueSpace, me.image);
	if(theCvar)
	{
		me.cvarName = theCvar;
		me.tooltip = getZonedTooltipForIdentifier(theCvar);
		// don't load it yet
	}
}
void setValueXonoticTextSlider(entity me, float val)
{
	if(val != me.value)
	{
		me.value = val;
		me.saveCvars(me);
	}
}
void loadCvarsXonoticTextSlider(entity me)
{
	if not(me.cvarName)
		return;

	var float n = tokenize_console(me.cvarName);
	var string s = cvar_string(argv(0));
	float i;
	for(i = 1; i < n; ++i)
		s = strcat(s, " ", cvar_string(argv(i)));
	me.setValueFromIdentifier(me, s);
}
void saveCvarsXonoticTextSlider(entity me)
{
	if not(me.cvarName)
		return;

	if(me.value >= 0 && me.value < me.nValues)
	{
		var float n = tokenize_console(me.cvarName);
		if(n == 1)
		{
			// this is a special case to allow spaces in the identifiers
			cvar_set(argv(0), me.getIdentifier(me));
		}
		else
		{
			float i;
			var float m = tokenize_console(strcat(me.cvarName, " ", me.getIdentifier(me)));
			if(m == n + 1)
			{
				for(i = 0; i < n; ++i)
					cvar_set(argv(i), argv(n));
			}
			else if(m == n * 2)
			{
				for(i = 0; i < n; ++i)
					cvar_set(argv(i), argv(i + n));
			}
			else
				error("XonoticTextSlider: invalid identifier ", me.getIdentifier(me), " does not match cvar list ", me.cvarName);
		}
	}
}
void configureXonoticTextSliderValuesXonoticTextSlider(entity me)
{
	me.configureTextSliderValues(me, string_null);
	me.loadCvars(me);
}
#endif
