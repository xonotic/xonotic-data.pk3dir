#include "dialog_settings_graphics.qh"

#include "commandbutton.qh"
#include "textlabel.qh"

void GraphicsSettings_addPresetButtons(entity me, entity apply_button)
{
	entity e;

	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Quality preset:")));
			e.align = 1;
			e.marginRight = 0.2;
		float width = (me.columns - 1) / 5;
	#define ADD_PRESET_BUTTON(translated_name, file_name) \
		me.TD(me, 1, width, e = makeXonoticCommandButton(ZCTX(translated_name), '0 0 0', "exec effects-" file_name ".cfg", 0)); \
			e.applyButton = apply_button;
			ADD_PRESET_BUTTON(_("PRE^Low"),    "low")
			ADD_PRESET_BUTTON(_("PRE^Medium"), "med")
			ADD_PRESET_BUTTON(_("PRE^Normal"), "normal")
			ADD_PRESET_BUTTON(_("PRE^High"),   "high")
			ADD_PRESET_BUTTON(_("PRE^Ultra"),  "ultra")
	#undef ADD_PRESET_BUTTON
}

// NOTE: file format similar to dialog_settings_game.qc, please keep in sync

METHOD(GraphicsSettingsSource, getEntry, entity(entity me, int i, void(string name, string icon) returns))
{
	Lazy l = REGISTRY_GET(GraphicsSettings, i);
	entity it = l.m_get();
	if (returns)
		returns(it.title, string_null);
	return it;
}
METHOD(GraphicsSettingsSource, getEntryTooltip, entity(entity me, int i, void(string theTooltip) returns))
{
	Lazy l = REGISTRY_GET(GraphicsSettings, i);
	entity it = l.m_get();
	if (returns)
		returns(it.titleTooltip);
	return it;
}
METHOD(GraphicsSettingsSource, reload, int(entity me, string filter))
{
	return REGISTRY_COUNT(GraphicsSettings);
}

entity makeXonoticGraphicsSettingsTab()
{
	entity me = NEW(XonoticGraphicsSettingsTab);
	me.configureDialog(me);
	return me;
}
