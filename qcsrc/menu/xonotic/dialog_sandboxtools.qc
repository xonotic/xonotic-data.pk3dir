#include "dialog_sandboxtools.qh"

#include "textlabel.qh"
#include "inputbox.qh"
#include "commandbutton.qh"
#include "colorpicker_string.qh"
#include "slider.qh"
#include "radiobutton.qh"

void XonoticSandboxToolsDialog_fill(entity me)
{
	entity e, box;

	me.TR(me);
		me.TD(me, 1, 0.3, e = makeXonoticTextLabel(0, _("Model:")));
		me.TD(me, 1, 1.3, box = makeXonoticInputBox(1, "menu_sandbox_spawn_model"));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = true;
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2.2/4, e = makeXonoticCommandButton(_("Spawn"), '0 0 0', "sandbox object_spawn \"$menu_sandbox_spawn_model\"", 0));
		me.TD(me, 1, 2.2/4, e = makeXonoticCommandButton(_("Remove *"), '0 0 0', "sandbox object_remove", 0));
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2.2/4, e = makeXonoticCommandButton(_("Copy *"), '0 0 0', "sandbox object_duplicate copy cl_sandbox_clipboard", 0));
		me.TD(me, 1, 2.2/4, e = makeXonoticCommandButton(_("Paste"), '0 0 0', "sandbox object_duplicate paste \"$cl_sandbox_clipboard\"", 0));
	me.TR(me);
		me.TD(me, 1, 0.3, e = makeXonoticTextLabel(0, _("Bone:")));
		me.TD(me, 1, 1.3, box = makeXonoticInputBox(1, "menu_sandbox_attach_bone"));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = true;
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2.1/3, e = makeXonoticCommandButton(_("Set * as child"), '0 0 0', "sandbox object_attach get", 0));
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2.1/3, e = makeXonoticCommandButton(_("Attach to *"), '0 0 0', "sandbox object_attach set \"$menu_sandbox_attach_bone\"", 0));
		me.TDempty(me, 0.1);
		me.TD(me, 1, 2.1/3, e = makeXonoticCommandButton(_("Detach from *"), '0 0 0', "sandbox object_attach remove", 0));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Visual object properties for *:")));
	me.TR(me);
		me.TD(me, 1, 0.75, e = makeXonoticCommandButton(_("Set skin:"), '0 0 0', "sandbox object_edit skin $menu_sandbox_edit_skin", 0));
		me.TD(me, 1, 1.25, e = makeXonoticSlider(0, 99, 1, "menu_sandbox_edit_skin"));
		me.TD(me, 1, 0.75, e = makeXonoticCommandButton(_("Set opacity:"), '0 0 0', "sandbox object_edit alpha $menu_sandbox_edit_alpha", 0));
		me.TD(me, 1, 1.25, e = makeXonoticSlider(0.1, 1, 0.05, "menu_sandbox_edit_alpha"));
			e.formatString = "%";
	me.TR(me);
		me.TD(me, 1, 0.75, e = makeXonoticCommandButton(_("Set color main:"), '0 0 0', "sandbox object_edit color_main \"$menu_sandbox_edit_color_main\"", 0));
		me.TD(me, 2, 1.25, e = makeXonoticColorpickerString("menu_sandbox_edit_color_main", "menu_sandbox_edit_color_main"));
		me.TD(me, 1, 0.75, e = makeXonoticCommandButton(_("Set color glow:"), '0 0 0', "sandbox object_edit color_glow \"$menu_sandbox_edit_color_glow\"", 0));
		me.TD(me, 2, 1.25, e = makeXonoticColorpickerString("menu_sandbox_edit_color_glow", "menu_sandbox_edit_color_glow"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 0.75, e = makeXonoticCommandButton(_("Set frame:"), '0 0 0', "sandbox object_edit frame $menu_sandbox_edit_frame", 0));
		me.TD(me, 1, 1.25, e = makeXonoticSlider(0, 99, 1, "menu_sandbox_edit_frame"));
	me.TR(me);
		me.TD(me, 1, 4, e = makeXonoticTextLabel(0, _("Physical object properties for *:")));
	me.TR(me);
		me.TD(me, 1, 0.6, e = makeXonoticCommandButton(_("Set material:"), '0 0 0', "sandbox object_edit material \"$menu_sandbox_edit_material\"", 0));
		me.TD(me, 1, 1.4, box = makeXonoticInputBox(1, "menu_sandbox_edit_material"));
			box.forbiddenCharacters = "\r\n\\\"$"; // don't care, isn't getting saved
			box.maxLength = -127; // negative means encoded length in bytes
			box.saveImmediately = true;
	me.TR(me);
		me.TD(me, 1, 0.6, e = makeXonoticCommandButton(_("Set solidity:"), '0 0 0', "sandbox object_edit solidity $menu_sandbox_edit_solidity", 0));
		me.TD(me, 1, 1.4/2, e = makeXonoticRadioButton(1, "menu_sandbox_edit_solidity", "0", _("Non-solid")));
		me.TD(me, 1, 1.4/2, e = makeXonoticRadioButton(1, "menu_sandbox_edit_solidity", "1", _("Solid")));
		me.TD(me, 1, 0.6, e = makeXonoticCommandButton(_("Set physics:"), '0 0 0', "sandbox object_edit physics $menu_sandbox_edit_physics", 0));
		me.TD(me, 1, 1.4/3, e = makeXonoticRadioButton(2, "menu_sandbox_edit_physics", "0", _("Static")));
		me.TD(me, 1, 1.4/3, e = makeXonoticRadioButton(2, "menu_sandbox_edit_physics", "1", _("Movable")));
		me.TD(me, 1, 1.4/3, e = makeXonoticRadioButton(2, "menu_sandbox_edit_physics", "2", _("Physical")));
	me.TR(me);
		me.TD(me, 1, 0.6, e = makeXonoticCommandButton(_("Set scale:"), '0 0 0', "sandbox object_edit scale $menu_sandbox_edit_scale", 0));
		me.TD(me, 1, 1.4, e = makeXonoticSlider(0.25, 2, 0.05, "menu_sandbox_edit_scale"));
		me.TD(me, 1, 0.6, e = makeXonoticCommandButton(_("Set force:"), '0 0 0', "sandbox object_edit force $menu_sandbox_edit_force", 0));
		me.TD(me, 1, 1.4, e = makeXonoticSlider(0, 10, 0.5, "menu_sandbox_edit_force"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 0.5, e = makeXonoticCommandButton(_("Claim *"), '0 0 0', "sandbox object_claim", 0));
		me.TDempty(me, 0.25);
		me.TD(me, 1, 0.8, e = makeXonoticCommandButton(_("* object info"), '1 1 0.5', "sandbox object_info object; toggleconsole", 0));
		me.TD(me, 1, 0.75, e = makeXonoticCommandButton(_("* mesh info"), '1 1 0.5', "sandbox object_info mesh; toggleconsole", 0));
		me.TD(me, 1, 0.8, e = makeXonoticCommandButton(_("* attachment info"), '1 1 0.5', "sandbox object_info attachments; toggleconsole", 0));
		me.TDempty(me, 0.25);
		me.TD(me, 1, 0.65, e = makeXonoticCommandButton(_("Show help"), '1 0.5 0.5', "sandbox help; toggleconsole", 0));
	me.TR(me);
		me.TDempty(me, 0.1);
		me.TD(me, 1, 3.9, e = makeXonoticTextLabel(0, _("* is the object you are facing")));

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, e = makeXonoticButton(_("OK"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
}
