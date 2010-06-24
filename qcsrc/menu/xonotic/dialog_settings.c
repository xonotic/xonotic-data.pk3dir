#ifdef INTERFACE
CLASS(XonoticSettingsDialog) EXTENDS(XonoticDialog)
	METHOD(XonoticSettingsDialog, fill, void(entity))
	ATTRIB(XonoticSettingsDialog, title, string, "Settings")
	ATTRIB(XonoticSettingsDialog, color, vector, SKINCOLOR_DIALOG_SETTINGS)
	ATTRIB(XonoticSettingsDialog, intendedWidth, float, 0.96)
	ATTRIB(XonoticSettingsDialog, rows, float, 19)
	ATTRIB(XonoticSettingsDialog, columns, float, 6)
ENDCLASS(XonoticSettingsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticSettingsDialog_fill(entity me)
{
	entity mc;
	mc = makeXonoticTabController(me.rows - 2);
	me.TR(me);
		me.TD(me, 1, 1, mc.makeTabButton(mc, "Input",   makeXonoticInputSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, "Video",   makeXonoticVideoSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, "Effects", makeXonoticEffectsSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, "Audio",   makeXonoticAudioSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, "Network", makeXonoticNetworkSettingsTab()));
		me.TD(me, 1, 1, mc.makeTabButton(mc, "Misc",    makeXonoticMiscSettingsTab()));
	me.TR(me);
	me.TR(me);
		me.TD(me, me.rows - 2, me.columns, mc);
}
#endif
