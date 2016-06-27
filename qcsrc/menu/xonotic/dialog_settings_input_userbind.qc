#include "dialog_settings_input_userbind.qh"

#include "keybinder.qh"
#include "textlabel.qh"
#include "inputbox.qh"
#include "button.qh"

void XonoticUserbindEditDialog_Save(entity btn, entity me)
{
	me.keybindBox.editUserbind(me.keybindBox, me.nameBox.text, me.commandPressBox.text, me.commandReleaseBox.text);
	Dialog_Close(btn, me);
}

void XonoticUserbindEditDialog_loadUserBind(entity me, string theName, string theCommandPress, string theCommandRelease)
{
	me.nameBox.setText(me.nameBox, theName);
		me.nameBox.keyDown(me.nameBox, K_END, 0, 0);
	me.commandPressBox.setText(me.commandPressBox, theCommandPress);
		me.nameBox.keyDown(me.commandPressBox, K_END, 0, 0);
	me.commandReleaseBox.setText(me.commandReleaseBox, theCommandRelease);
		me.nameBox.keyDown(me.commandReleaseBox, K_END, 0, 0);
}

void XonoticUserbindEditDialog_fill(entity me)
{
	entity e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Name:")));
		me.TD(me, 1, me.columns - 1, me.nameBox = makeXonoticInputBox(0, string_null));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Command when pressed:")));
		me.TD(me, 1, me.columns - 1, me.commandPressBox = makeXonoticInputBox(0, string_null));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Command when released:")));
		me.TD(me, 1, me.columns - 1, me.commandReleaseBox = makeXonoticInputBox(0, string_null));
	me.TR(me);
		me.TD(me, 1, me.columns / 2, e = makeXonoticButton(_("Save"), '0 0 0'));
			e.onClick = XonoticUserbindEditDialog_Save;
			e.onClickEntity = me;
		me.TD(me, 1, me.columns / 2, e = makeXonoticButton(_("Cancel"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
