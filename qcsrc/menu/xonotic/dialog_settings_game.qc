#include "dialog_settings_game.qh"

METHOD(SettingSource, getEntry, entity(entity me, int i, void(string name, string icon) returns))
{
	Lazy l = REGISTRY_GET(Settings, i);
	entity it = l.m_get();
	if (returns)
		returns(it.title, string_null);
	return it;
}
METHOD(SettingSource, getEntryTooltip, entity(entity me, int i, void(string theTooltip) returns))
{
	Lazy l = REGISTRY_GET(Settings, i);
	entity it = l.m_get();
	if (returns)
		returns(it.titleTooltip);
	return it;
}
METHOD(SettingSource, reload, int(entity me, string filter))
{
	return REGISTRY_COUNT(Settings);
}

entity makeXonoticGameSettingsTab()
{
	entity me = NEW(XonoticGameSettingsTab);
	me.configureDialog(me);
	return me;
}
