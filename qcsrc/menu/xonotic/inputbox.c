#ifdef INTERFACE
CLASS(XonoticInputBox) EXTENDS(InputBox)
	METHOD(XonoticInputBox, configureXonoticInputBox, void(entity, float, string))
	METHOD(XonoticInputBox, focusLeave, void(entity))
	METHOD(XonoticInputBox, setText, void(entity, string))
	ATTRIB(XonoticInputBox, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticInputBox, image, string, SKINGFX_INPUTBOX)
	ATTRIB(XonoticInputBox, onChange, void(entity, entity), SUB_Null)
	ATTRIB(XonoticInputBox, onChangeEntity, entity, NULL)
	ATTRIB(XonoticInputBox, onEnter, void(entity, entity), SUB_Null)
	ATTRIB(XonoticInputBox, onEnterEntity, entity, NULL)
	ATTRIB(XonoticInputBox, marginLeft, float, SKINMARGIN_INPUTBOX_CHARS)
	ATTRIB(XonoticInputBox, marginRight, float, SKINMARGIN_INPUTBOX_CHARS)
	ATTRIB(XonoticInputBox, color, vector, SKINCOLOR_INPUTBOX_N)
	ATTRIB(XonoticInputBox, colorF, vector, SKINCOLOR_INPUTBOX_F)

	ATTRIB(XonoticInputBox, alpha, float, SKINALPHA_TEXT)

	ATTRIB(XonoticInputBox, cvarName, string, string_null)
	METHOD(XonoticInputBox, loadCvars, void(entity))
	METHOD(XonoticInputBox, saveCvars, void(entity))
	METHOD(XonoticInputBox, keyDown, float(entity, float, float, float))
ENDCLASS(XonoticInputBox)
entity makeXonoticInputBox(float, string);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticInputBox(float doEditColorCodes, string theCvar)
{
	entity me;
	me = spawnXonoticInputBox();
	me.configureXonoticInputBox(me, doEditColorCodes, theCvar);
	return me;
}
void configureXonoticInputBoxXonoticInputBox(entity me, float doEditColorCodes, string theCvar)
{
	me.configureInputBox(me, "", 0, me.fontSize, me.image);
	me.editColorCodes = doEditColorCodes;
	if(theCvar)
	{
		me.cvarName = theCvar;
		me.tooltip = getZonedTooltipForIdentifier(theCvar);
		me.loadCvars(me);
	}
	me.cursorPos = strlen(me.text);
}
void focusLeaveXonoticInputBox(entity me)
{
	me.saveCvars(me);
}
void setTextXonoticInputBox(entity me, string new)
{
	if(me.text != new)
	{
		setTextInputBox(me, new);
		me.onChange(me, me.onChangeEntity);
	}
	else
		setTextInputBox(me, new);
}
void loadCvarsXonoticInputBox(entity me)
{
	if not(me.cvarName)
		return;
	setTextInputBox(me, cvar_string(me.cvarName));
}
void saveCvarsXonoticInputBox(entity me)
{
	if not(me.cvarName)
		return;
	cvar_set(me.cvarName, me.text);
}
float keyDownXonoticInputBox(entity me, float key, float ascii, float shift)
{
	float r;
	r = 0;
	if(key == K_ENTER)
	{
		if(me.cvarName)
		{
			me.saveCvars(me);
			r = 1;
		}
		me.onEnter(me, me.onEnterEntity);
	}
	if(keyDownInputBox(me, key, ascii, shift))
		r = 1;
	return r;
}
#endif
