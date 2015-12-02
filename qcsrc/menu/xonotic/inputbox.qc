#ifndef INPUTBOX_H
#define INPUTBOX_H
#include "../item/inputbox.qc"
CLASS(XonoticInputBox, InputBox)
	METHOD(XonoticInputBox, configureXonoticInputBox, void(entity, float, string, string));
	METHOD(XonoticInputBox, focusLeave, void(entity));
	METHOD(XonoticInputBox, setText, void(entity, string));
	METHOD(XonoticInputBox, keyDown, float(entity, float, float, float));
	ATTRIB(XonoticInputBox, fontSize, float, SKINFONTSIZE_NORMAL)
	ATTRIB(XonoticInputBox, image, string, SKINGFX_INPUTBOX)
	ATTRIB(XonoticInputBox, onChange, void(entity, entity), func_null)
	ATTRIB(XonoticInputBox, onChangeEntity, entity, NULL)
	ATTRIB(XonoticInputBox, onEnter, void(entity, entity), func_null)
	ATTRIB(XonoticInputBox, onEnterEntity, entity, NULL)
	ATTRIB(XonoticInputBox, marginLeft, float, SKINMARGIN_INPUTBOX_CHARS)
	ATTRIB(XonoticInputBox, marginRight, float, SKINMARGIN_INPUTBOX_CHARS)
	ATTRIB(XonoticInputBox, color, vector, SKINCOLOR_INPUTBOX_N)
	ATTRIB(XonoticInputBox, colorF, vector, SKINCOLOR_INPUTBOX_F)

	ATTRIB(XonoticInputBox, alpha, float, SKINALPHA_TEXT)

	// Clear button attributes
	ATTRIB(XonoticInputBox, cb_offset, float, SKINOFFSET_CLEARBUTTON) // bound to range -1, 0
	ATTRIB(XonoticInputBox, cb_src, string, SKINGFX_CLEARBUTTON)
	ATTRIB(XonoticInputBox, cb_color, vector, SKINCOLOR_CLEARBUTTON_N)
	ATTRIB(XonoticInputBox, cb_colorF, vector, SKINCOLOR_CLEARBUTTON_F)
	ATTRIB(XonoticInputBox, cb_colorC, vector, SKINCOLOR_CLEARBUTTON_C)

	ATTRIB(XonoticInputBox, cvarName, string, string_null)
	METHOD(XonoticInputBox, loadCvars, void(entity));
	METHOD(XonoticInputBox, saveCvars, void(entity));
	ATTRIB(XonoticInputBox, sendCvars, float, 0)

	ATTRIB(XonoticInputBox, saveImmediately, float, 0)
ENDCLASS(XonoticInputBox)
entity makeXonoticInputBox_T(float, string, string theTooltip);
entity makeXonoticInputBox(float, string);
#endif

#ifdef IMPLEMENTATION
entity makeXonoticInputBox_T(float doEditColorCodes, string theCvar, string theTooltip)
{
	entity me;
	me = NEW(XonoticInputBox);
	me.configureXonoticInputBox(me, doEditColorCodes, theCvar, theTooltip);
	return me;
}
entity makeXonoticInputBox(float doEditColorCodes, string theCvar)
{
	return makeXonoticInputBox_T(doEditColorCodes, theCvar, string_null);
}
void XonoticInputBox_configureXonoticInputBox(entity me, float doEditColorCodes, string theCvar, string theTooltip)
{
	me.configureInputBox(me, "", 0, me.fontSize, me.image);
	me.editColorCodes = doEditColorCodes;
	me.cvarName = (theCvar) ? theCvar : string_null;
	me.loadCvars(me);
	setZonedTooltip(me, theTooltip, theCvar);
	me.cursorPos = strlen(me.text);
}
void XonoticInputBox_focusLeave(entity me)
{
	me.saveCvars(me);
}
void XonoticInputBox_setText(entity me, string val)
{
	if(me.text != val)
	{
		SUPER(XonoticInputBox).setText(me, val);
		if(me.onChange)
			me.onChange(me, me.onChangeEntity);
		if(me.saveImmediately)
			me.saveCvars(me);
	}
	else
		SUPER(XonoticInputBox).setText(me, val);
}
void XonoticInputBox_loadCvars(entity me)
{
	if (!me.cvarName)
		return;
	SUPER(XonoticInputBox).setText(me, cvar_string(me.cvarName));
}
void XonoticInputBox_saveCvars(entity me)
{
	if (!me.cvarName)
		return;
	cvar_set(me.cvarName, me.text);
	CheckSendCvars(me, me.cvarName);
}
float XonoticInputBox_keyDown(entity me, float key, float ascii, float shift)
{
	float r;
	r = 0;
	if(key == K_ENTER || key == K_KP_ENTER)
	{
		if(me.cvarName)
		{
			me.saveCvars(me);
			r = 1;
		}
		if(me.onEnter)
			me.onEnter(me, me.onEnterEntity);
	}
	if(SUPER(XonoticInputBox).keyDown(me, key, ascii, shift))
		r = 1;
	return r;
}
#endif
