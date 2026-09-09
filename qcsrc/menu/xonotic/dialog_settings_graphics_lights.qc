#include "dialog_settings_graphics_lights.qh"

#include "dialog_settings_graphics.qh"

#include "checkbox.qh"
#include "commandbutton.qh"
#include "slider.qh"
#include "textlabel.qh"

void XonoticGraphicsLightsSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGraphicsLightsSettingsTab()
{
	entity me = NEW(XonoticGraphicsLightsSettingsTab);
	me.configureDialog(me);
	return me;
}

bool someShadowCvarIsEnabled(entity box)
{
	if (cvar("r_shadow_realtime_dlight")
	&&  cvar("r_shadow_realtime_dlight_shadows"))
		return true;
	if (cvar("r_shadow_realtime_world")
	&&  cvar("r_shadow_realtime_world_shadows"))
		return true;
	return false;
}

void XonoticGraphicsLightsSettingsTab_fill(entity me)
{
	entity e;
	entity effectsApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "vid_restart", COMMANDBUTTON_APPLY);
		effectsApplyButton.disableOnClick = true;

	GraphicsSettings_addPresetButtons(me, effectsApplyButton);

	me.gotoRC(me, 2, 1); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Realtime")));
	me.TR(me);
		me.TD(me, 1, 1.1, e = makeXonoticTextLabel(0, _("Corona brightness:")));
		me.TD(me, 1, 1.9, e = makeXonoticSlider_T(0, 1.5, 0.1, "r_coronas", _("Flare effects around certain lights")));
			e.setValueSpace(e, e.valueSpace * (20/19));
			e.formatString = _("%sx");
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox_T(0, "r_coronas_occlusionquery", _("Fade coronas according to visibility"),
			_("Corona fading using occlusion queries")));
			setDependentNOT(e, "r_coronas", 0);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticCheckBox_T(0, "r_shadow_realtime_dlight", _("Realtime dynamic lights"),
			_("Temporary realtime light sources such as explosions, rockets and powerups")));
			makeMulti(e, "!gl_flashblend");
		me.TD(me, 1, 1, e = makeXonoticCheckBox_T(0, "r_shadow_realtime_dlight_shadows", _("Shadows"),
			_("Shadows cast by realtime dynamic lights")));
			setDependent(e, "r_shadow_realtime_dlight", 1, 1);
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticCheckBox_T(0, "r_shadow_realtime_world", _("Realtime world lights"),
			_("Realtime light sources included in certain maps. May have a big impact on performance.")));
		me.TD(me, 1, 1, e = makeXonoticCheckBox_T(0, "r_shadow_realtime_world_shadows", _("Shadows"),
			_("Shadows cast by realtime world lights")));
			setDependent(e, "r_shadow_realtime_world", 1, 1);
	me.TR(me);
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox_T(0, "r_shadow_usenormalmap", _("Use normal maps"),
			_("Directional shading of certain textures to simulate interaction of realtime light with a bumpy surface")));
			setDependent(e, "r_shadow_realtime_dlight", 1, 1);
			setDependentOR(e, "r_shadow_realtime_world", 1, 1);
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox(0, "r_shadow_shadowmapping", _("Soft shadows")));
			setDependentWeird(e, someShadowCvarIsEnabled);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Static")));
	me.TR(me);
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox_T(1, "mod_q3bsp_nolightmaps", _("Use lightmaps"),
			_("Use high resolution lightmaps, which will look pretty but use up some extra video memory")));
			e.applyButton = effectsApplyButton;
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox_T(0, "r_glsl_deluxemapping", _("Deluxe mapping"),
			_("Use per-pixel lighting effects")));
			setDependent(e, "mod_q3bsp_nolightmaps", 0, 0);
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependentAND(e, "vid_gl20", 1, 1);
	me.TR(me);
		me.TDempty(me, 3/2);
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox_T(0, "r_shadow_gloss", _("Gloss"),
			_("Enable the use of glossmaps on textures supporting them")));
			setDependent(e, "mod_q3bsp_nolightmaps", 0, 0);
			setDependentAND(e, "r_glsl_deluxemapping", 1, 1);
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependentAND(e, "vid_gl20", 1, 1);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, effectsApplyButton);
}
