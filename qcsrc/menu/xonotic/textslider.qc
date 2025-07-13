#include "textslider.qh"

entity makeXonoticTextSlider_T(string theCvar, string theTooltip)
{
	entity me;
	me = NEW(XonoticTextSlider);
	me.configureXonoticTextSlider(me, theCvar, theTooltip);
	return me;
}
entity makeXonoticTextSlider(string theCvar)
{
	return makeXonoticTextSlider_T(theCvar, string_null);
}
void XonoticTextSlider_configureXonoticTextSlider(entity me, string theCvar, string theTooltip)
{
	me.configureSliderVisuals(me, me.fontSize, me.align, me.valueSpace, me.image);
	me.controlledCvar = (theCvar) ? theCvar : string_null;
	// me.loadCvars(me); // don't load it yet
	setZonedTooltip(me, theTooltip, theCvar);
}
void XonoticTextSlider_setValue(entity me, float val, bool allowAnim)
{
	if(val != me.value)
	{
		SUPER(XonoticTextSlider).setValue(me, val, allowAnim);
		me.saveCvars(me);
	}
}
void XonoticTextSlider_setValueSpace(entity me, float val)
{
	me.valueSpace = val;
	me.configureSliderVisuals(me, me.fontSize, me.align, me.valueSpace, me.image);
}
void XonoticTextSlider_loadCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	float n = tokenize_console(me.controlledCvar);
	string s = cvar_string(argv(0));
	float i;
	for(i = 1; i < n; ++i)
		s = strcat(s, " ", cvar_string(argv(i)));
	me.setValueFromIdentifier(me, s, false);
	if(me.value < 0 && n > 1)
	{
		// if it failed: check if all cvars have the same value
		// if yes, try its value as 1-word identifier
		for(i = 1; i < n; ++i)
			if(cvar_string(argv(i)) != cvar_string(argv(i-1)))
				break;
		if(i >= n)
			me.setValueFromIdentifier(me, cvar_string(argv(0)), false);
	}
}
void XonoticTextSlider_saveCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	if(me.value >= 0 && me.value < me.nValues)
	{
		float n = tokenize_console(me.controlledCvar);
		if(n == 1)
		{
			// this is a special case to allow spaces in the identifiers
			cvar_set(argv(0), me.getIdentifier(me));
			CheckSendCvars(me, argv(0));
		}
		else
		{
			float i;
			float m = tokenize_console(strcat(me.controlledCvar, " ", me.getIdentifier(me)));
			if(m == n + 1)
			{
				for(i = 0; i < n; ++i)
				{
					cvar_set(argv(i), argv(n));
					CheckSendCvars(me, argv(i));
				}
			}
			else if(m == n * 2)
			{
				for(i = 0; i < n; ++i)
				{
					cvar_set(argv(i), argv(i + n));
					CheckSendCvars(me, argv(i));
				}
			}
			else
				error("XonoticTextSlider: invalid identifier ", me.getIdentifier(me), " does not match cvar list ", me.controlledCvar);
		}
	}
}
void XonoticTextSlider_configureXonoticTextSliderValues(entity me)
{
	me.configureTextSliderValues(me, string_null);
	me.loadCvars(me);
}
