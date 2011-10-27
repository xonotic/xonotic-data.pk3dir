#ifdef INTERFACE
CLASS(XonoticSandboxToolsDialog) EXTENDS(XonoticRootDialog)
	METHOD(XonoticSandboxToolsDialog, fill, void(entity)) // to be overridden by user to fill the dialog with controls
	ATTRIB(XonoticSandboxToolsDialog, title, string, _("Sandbox Tools")) // ;)
	ATTRIB(XonoticSandboxToolsDialog, color, vector, SKINCOLOR_DIALOG_SANDBOXTOOLS)
	ATTRIB(XonoticSandboxToolsDialog, intendedWidth, float, 0.8)
	ATTRIB(XonoticSandboxToolsDialog, rows, float, 20)
	ATTRIB(XonoticSandboxToolsDialog, columns, float, 4)
	ATTRIB(XonoticSandboxToolsDialog, name, string, "SandboxTools")
ENDCLASS(XonoticSandboxToolsDialog)
#endif

#ifdef IMPLEMENTATION
void XonoticSandboxToolsDialog_fill(entity me)
{
	entity e, box;

	me.TR(me);
		me.TD(me, 1, 0.25, e = makeXonoticTextLabel(0, _("Model:")));
		me.TD(me, 1, 1.5, box = makeXonoticInputBox(1, "menu_sandbox_spawn_model"));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = 1;
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Spawn"), '0 0 0', "sandbox spawn_object $menu_sandbox_spawn_model", 0));
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Remove"), '0 0 0', "sandbox remove_object", 0));
	me.TDempty(me, 0.1);
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Copy"), '0 0 0', "sandbox duplicate_object_copy", 0));
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Paste"), '0 0 0', "sandbox duplicate_object_paste", 0));
	me.TR(me);
		me.TD(me, 1, 0.25, e = makeXonoticTextLabel(0, _("Bone:")));
		me.TD(me, 1, 1.5, box = makeXonoticInputBox(1, "menu_sandbox_attach_bone"));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = 1;
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Set child"), '0 0 0', "sandbox attach_object get", 0));
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Attach"), '0 0 0', "sandbox attach_object set $menu_sandbox_edit_skin", 0));
	me.TDempty(me, 0.1);
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Detach all"), '0 0 0', "sandbox attach_object remove", 0));
	me.TR(me);
	me.TR(me);
	me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Visual object properties:")));
	me.TR(me);
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Set skin:"), '0 0 0', "sandbox edit_object skin $menu_sandbox_edit_skin", 0));
		me.TD(me, 1, 1.5, e = makeXonoticSlider(0, 99, 1, "menu_sandbox_edit_skin"));
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Set alpha:"), '0 0 0', "sandbox edit_object alpha $menu_sandbox_edit_alpha", 0));
		me.TD(me, 1, 1.5, e = makeXonoticSlider(0.1, 1, 0.05, "menu_sandbox_edit_alpha"));
	me.TR(me);
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Set color main:"), '0 0 0', "sandbox edit_object color_main \"$menu_sandbox_edit_color_main\"", 0));
		me.TD(me, 2, 1.5, e = makeXonoticColorpickerString("menu_sandbox_edit_color_main", "menu_sandbox_edit_color_main"));
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Set color glow:"), '0 0 0', "sandbox edit_object color_glow \"$menu_sandbox_edit_color_glow\"", 0));
		me.TD(me, 2, 1.5, e = makeXonoticColorpickerString("menu_sandbox_edit_color_glow", "menu_sandbox_edit_color_glow"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Set frame:"), '0 0 0', "sandbox edit_object frame $menu_sandbox_edit_frame", 0));
		me.TD(me, 1, 1.5, e = makeXonoticSlider(0, 99, 1, "menu_sandbox_edit_frame"));
	me.TR(me);
	me.TR(me);
	me.TD(me, 1, 2, e = makeXonoticTextLabel(0, _("Physical object properties:")));
	me.TR(me);
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Set material:"), '0 0 0', "sandbox edit_object material $menu_sandbox_edit_material", 0));
		me.TD(me, 1, 1.5, e = makeXonoticTextSlider("menu_sandbox_edit_material"));
			e.addValue(e, _("none"), "0");
			e.addValue(e, _("metal"), "1");
			e.addValue(e, _("stone"), "2");
			e.addValue(e, _("wood"), "3");
			e.addValue(e, _("flesh"), "4");
			e.configureXonoticTextSliderValues(e);
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Set physics:"), '0 0 0', "sandbox edit_object physics $menu_sandbox_edit_physics", 0));
		me.TD(me, 1, 0.5, e = makeXonoticRadioButton(1, "menu_sandbox_edit_physics", "0", _("Static")));
		me.TD(me, 1, 0.5, e = makeXonoticRadioButton(1, "menu_sandbox_edit_physics", "1", _("Movable")));
		me.TD(me, 1, 0.5, e = makeXonoticRadioButton(1, "menu_sandbox_edit_physics", "2", _("Physical")));
	me.TR(me);
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Set scale:"), '0 0 0', "sandbox edit_object scale $menu_sandbox_edit_scale", 0));
		me.TD(me, 1, 1.5, e = makeXonoticSlider(0.5, 2, 0.05, "menu_sandbox_edit_scale"));
		me.TD(me, 1, 0.5, makeXonoticCommandButton(_("Set force:"), '0 0 0', "sandbox edit_object force $menu_sandbox_edit_force", 0));
		me.TD(me, 1, 1.5, e = makeXonoticSlider(0, 10, 0.5, "menu_sandbox_edit_force"));

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
#endif

/* Click. The c-word is here so you can grep for it :-) */
