#include "dialog_settings_videoeffects.qh"

// NOTE: file format similar to dialog_settings_game.qc, please keep in sync

METHOD(VideoEffectsSettingsSource, getEntry, entity(entity me, int i, void(string name, string icon) returns))
{
	Lazy l = REGISTRY_GET(VideoEffectsSettings, i);
	entity it = l.m_get();
	if (returns)
		returns(it.title, string_null);
	return it;
}
METHOD(VideoEffectsSettingsSource, getEntryTooltip, entity(entity me, int i, void(string theTooltip) returns))
{
	Lazy l = REGISTRY_GET(VideoEffectsSettings, i);
	entity it = l.m_get();
	if (returns)
		returns(it.titleTooltip);
	return it;
}
METHOD(VideoEffectsSettingsSource, reload, int(entity me, string filter))
{
	return REGISTRY_COUNT(VideoEffectsSettings);
}

entity makeXonoticVideoEffectsSettingsTab()
{
	entity me = NEW(XonoticVideoEffectsSettingsTab);
	me.configureDialog(me);
	return me;
}
