#ifdef INTERFACE
CLASS(XonoticColorButton) EXTENDS(RadioButton)
	METHOD(XonoticColorButton, configureXonoticColorButton, void(entity, float, float, float))
	METHOD(XonoticColorButton, setChecked, void(entity, float))
	METHOD(XonoticColorButton, draw, void(entity))
	ATTRIB(XonoticColorButton, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticColorButton, image, string, SKINGFX_COLORBUTTON)
	ATTRIB(XonoticColorButton, image2, string, SKINGFX_COLORBUTTON_COLOR)

	ATTRIB(XonoticColorButton, useDownAsChecked, float, 1)

	ATTRIB(XonoticColorButton, cvarPart, float, 0)
	ATTRIB(XonoticColorButton, cvarName, string, string_null)
	ATTRIB(XonoticColorButton, cvarValueFloat, float, 0)
	METHOD(XonoticColorButton, loadCvars, void(entity))
	METHOD(XonoticColorButton, saveCvars, void(entity))
ENDCLASS(XonoticColorButton)
entity makeXonoticColorButton(float, float, float);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticColorButton(float theGroup, float theColor, float theValue)
{
	entity me;
	me = spawnXonoticColorButton();
	me.configureXonoticColorButton(me, theGroup, theColor, theValue);
	return me;
}
void configureXonoticColorButtonXonoticColorButton(entity me, float theGroup, float theColor, float theValue)
{
	me.cvarName = "_cl_color";
	me.cvarValueFloat = theValue;
	me.cvarPart = theColor;
	me.loadCvars(me);
	me.configureRadioButton(me, string_null, me.fontSize, me.image, theGroup, 0);
	me.srcMulti = 1;
	me.src2 = me.image2;
}
void setCheckedXonoticColorButton(entity me, float val)
{
	if(val != me.checked)
	{
		me.checked = val;
		me.saveCvars(me);
	}
}
void loadCvarsXonoticColorButton(entity me)
{
	if not(me.cvarName)
		return;

	if(me.cvarPart == 1)
		me.checked = (cvar(me.cvarName) & 240) == me.cvarValueFloat * 16;
	else
		me.checked = (cvar(me.cvarName) & 15) == me.cvarValueFloat;
}
void saveCvarsXonoticColorButton(entity me)
{
	if not(me.cvarName)
		return;

	if(me.checked)
	{
		if(me.cvarPart == 1)
			cvar_set(me.cvarName, ftos(cvar(me.cvarName) & 15 + me.cvarValueFloat * 16));
		else
			cvar_set(me.cvarName, ftos(cvar(me.cvarName) & 240 + me.cvarValueFloat));
	}
	// TODO on an apply button, read _cl_color and execute the color command for it
}
void drawXonoticColorButton(entity me)
{
	me.color2 = colormapPaletteColor(me.cvarValueFloat, me.cvarPart);
	drawCheckBox(me);
}
#endif
