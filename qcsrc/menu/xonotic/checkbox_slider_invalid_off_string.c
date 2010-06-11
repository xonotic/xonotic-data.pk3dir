#ifdef INTERFACE
CLASS(XonoticSliderCheckBoxNull) EXTENDS(CheckBox)
	METHOD(XonoticSliderCheckBoxNull, configureXonoticSliderCheckBoxNull, void(entity, float, entity, string, float))
	METHOD(XonoticSliderCheckBoxNull, setChecked, void(entity, float))
	METHOD(XonoticSliderCheckBoxNull, draw, void(entity))
	ATTRIB(XonoticSliderCheckBoxNull, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticSliderCheckBoxNull, image, string, SKINGFX_CHECKBOX)

	ATTRIB(XonoticSliderCheckBoxNull, color, vector, SKINCOLOR_CHECKBOX_N)
	ATTRIB(XonoticSliderCheckBoxNull, colorC, vector, SKINCOLOR_CHECKBOX_C)
	ATTRIB(XonoticSliderCheckBoxNull, colorF, vector, SKINCOLOR_CHECKBOX_F)
	ATTRIB(XonoticSliderCheckBoxNull, colorD, vector, SKINCOLOR_CHECKBOX_D)

	ATTRIB(XonoticSliderCheckBoxNull, alpha, float, SKINALPHA_TEXT)
	ATTRIB(XonoticSliderCheckBoxNull, disabledAlpha, float, SKINALPHA_DISABLED)

	ATTRIB(XonoticSliderCheckBoxNull, setting, float, 0)
	METHOD(XonoticSliderCheckBoxNull, loadCvars, void(entity))
	METHOD(XonoticSliderCheckBoxNull, saveCvars, void(entity))
	ATTRIB(XonoticSliderCheckBoxNull, value_s, string, string_null)

	ATTRIB(XonoticSliderCheckBoxNull, controlledSlider, entity, NULL)
	ATTRIB(XonoticSliderCheckBoxNull, inverted, float, 0)
	ATTRIB(XonoticSliderCheckBoxNull, savedValue, float, -1)
ENDCLASS(XonoticSliderCheckBoxNull)
entity makeXonoticSliderCheckBoxNull(float, entity, string, float);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticSliderCheckBoxNull(float isInverted, entity theControlledSlider, string theText, float theSetting)
{
	entity me;
	me = spawnXonoticSliderCheckBoxNull();
	me.configureXonoticSliderCheckBoxNull(me, isInverted, theControlledSlider, theText, theSetting);
	return me;
}
void configureXonoticSliderCheckBoxNullXonoticSliderCheckBoxNull(entity me, float isInverted, entity theControlledSlider, string theText, float theSetting)
{
	me.setting = theSetting;
	me.loadCvars(me);
	me.inverted = isInverted;
	me.checked = (me.value_s == "");
	if(theControlledSlider.value == median(theControlledSlider.valueMin, theControlledSlider.value, theControlledSlider.valueMax))
		me.savedValue = theControlledSlider.value;
	else
		me.savedValue = theControlledSlider.valueMin; 
	me.controlledSlider = theControlledSlider;
	me.configureCheckBox(me, theText, me.fontSize, me.image);
	me.tooltip = theControlledSlider.tooltip;
}
void drawXonoticSliderCheckBoxNull(entity me)
{
	me.checked = ((me.value_s == "") != me.inverted);
	if(me.controlledSlider.value == median(me.controlledSlider.valueMin, me.controlledSlider.value, me.controlledSlider.valueMax))
		me.savedValue = me.controlledSlider.value;
	drawCheckBox(me);
}
void setCheckedXonoticSliderCheckBoxNull(entity me, float val)
{
	if(me.checked == val)
		return;
	me.checked = val;
	if(val == me.inverted)
		me.controlledSlider.setValue(me.controlledSlider, median(me.controlledSlider.valueMin, me.savedValue, me.controlledSlider.valueMax));
	else
		me.controlledSlider.setValue(me.controlledSlider, 9000);
}
void loadCvarsXonoticSliderCheckBoxNull(entity me)
{
	me.value_s = strzone(cvar_string(strcat("hud_", HUD_Panel_GetName(highlightedPanel), HUD_Panel_GetSettingName(me.setting))));
}
void saveCvarsXonoticSliderCheckBoxNull(entity me)
{
	cvar_set(strcat("hud_", HUD_Panel_GetName(highlightedPanel), HUD_Panel_GetSettingName(me.setting)), me.value_s);
}
#endif
