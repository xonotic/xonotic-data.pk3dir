#include "dialog_settings_game.qh"

// NOTE: file format similar to dialog_settings_videoeffects.qc, please keep in sync

METHOD(GameSettingsSource, getEntry, entity(entity me, int i, void(string name, string icon) returns))
{
	Lazy l = REGISTRY_GET(GameSettings, i);
	entity it = l.m_get();
	if (returns)
		returns(it.title, string_null);
	return it;
}
METHOD(GameSettingsSource, getEntryTooltip, entity(entity me, int i, void(string theTooltip) returns))
{
	Lazy l = REGISTRY_GET(GameSettings, i);
	entity it = l.m_get();
	if (returns)
		returns(it.titleTooltip);
	return it;
}
METHOD(GameSettingsSource, reload, int(entity me, string filter))
{
	return REGISTRY_COUNT(GameSettings);
}

entity makeXonoticGameSettingsTab()
{
	entity me = NEW(XonoticGameSettingsTab);
	me.configureDialog(me);
	return me;
}
