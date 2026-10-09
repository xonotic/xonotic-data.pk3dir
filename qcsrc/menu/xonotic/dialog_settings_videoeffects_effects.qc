#include "dialog_settings_videoeffects_effects.qh"

#include "checkbox.qh"
#include "checkbox_slider_invalid.qh"
#include "commandbutton.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "textlabel.qh"

void XonoticVideoEffectsEffectsSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticVideoEffectsEffectsSettingsTab()
{
	entity me = NEW(XonoticVideoEffectsEffectsSettingsTab);
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

void XonoticVideoEffectsEffectsSettingsTab_fill(entity me)
{
	entity e, s;
	entity effectsApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "vid_restart", COMMANDBUTTON_APPLY);
		effectsApplyButton.disableOnClick = true;

	float col = (me.columns - 3) * 0.5;
	me.TR(me);
		me.TD(me, 1, col, e = makeXonoticTextLabel(0, _("Quality preset:")));
			e.align = 1;
			e.marginLeft = 0.2;
			e.marginRight = 0.2;
		float width = (me.columns - col) / 5;
	#define ADD_PRESET_BUTTON(translated_name, file_name) \
		me.TD(me, 1, width, e = makeXonoticCommandButton(ZCTX(translated_name), '0 0 0', "exec effects-" file_name ".cfg", 0)); \
			e.applyButton = effectsApplyButton;
			ADD_PRESET_BUTTON(_("PRE^Low"),    "low")
			ADD_PRESET_BUTTON(_("PRE^Medium"), "med")
			ADD_PRESET_BUTTON(_("PRE^Normal"), "normal")
			ADD_PRESET_BUTTON(_("PRE^High"),   "high")
			ADD_PRESET_BUTTON(_("PRE^Ultra"),  "ultra")
	#undef ADD_PRESET_BUTTON

	me.gotoRC(me, 2, col); me.setFirstColumn(me, me.currentColumn);
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
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox_T(0, "r_shadow_usenormalmap", _("Use normal maps"),
			_("Directional shading of certain textures to simulate interaction of realtime light with a bumpy surface")));
			setDependent(e, "r_shadow_realtime_dlight", 1, 1);
			setDependentOR(e, "r_shadow_realtime_world", 1, 1);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_shadow_shadowmapping", _("Soft shadows")));
			setDependentWeird(e, someShadowCvarIsEnabled);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox_T(1, "mod_q3bsp_nolightmaps", _("Use lightmaps"),
			_("Use high resolution lightmaps, which will look pretty but use up some extra video memory")));
			e.applyButton = effectsApplyButton;
		me.TD(me, 1, 1, e = makeXonoticCheckBox_T(0, "r_glsl_deluxemapping", _("Deluxe mapping"),
			_("Use per-pixel lighting effects")));
			setDependent(e, "mod_q3bsp_nolightmaps", 0, 0);
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependentAND(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 1, e = makeXonoticCheckBox_T(0, "r_shadow_gloss", _("Gloss"),
			_("Enable the use of glossmaps on textures supporting them")));
			setDependent(e, "mod_q3bsp_nolightmaps", 0, 0);
			setDependentAND(e, "r_glsl_deluxemapping", 1, 1);
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependentAND(e, "vid_gl20", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox_T(0, "r_glsl_offsetmapping", _("Offset mapping"),
			_("Offset mapping effect that will make textures with bumpmaps appear like they \"pop out\" of the flat 2D surface")));
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticCheckBox_T(0, "r_glsl_offsetmapping_reliefmapping", _("Relief mapping"),
			_("Higher quality offset mapping, which also has a huge impact on performance")));
			setDependent(e, "r_glsl_offsetmapping", 1, 1);
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependentAND(e, "vid_gl20", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox_T(0, "r_water", _("Reflections:"),
			_("Reflection and refraction quality, has a huge impact on performance on maps with reflecting surfaces")));
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("r_water_resolutionmultiplier", _("Resolution of reflections/refractions")));
			e.addText(e,      _("Blurred"),    0.25);
			e.addText(e, ZCTX(_("REFL^Good")), 0.5);
			e.addText(e,      _("Sharp"),      1);
			e.configureXonoticMixedSliderValues(e);
			setDependent(e, "r_water", 1, 1);
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependentAND(e, "vid_gl20", 1, 1);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Corona brightness:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 1.5, 0.1, "r_coronas", _("Flare effects around certain lights")));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox_T(0, "r_coronas_occlusionquery", _("Fade coronas according to visibility"),
			_("Corona fading using occlusion queries")));
			setDependentNOT(e, "r_coronas", 0);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox_T(0, "r_bloom", _("Bloom"),
			_("Enable bloom effect, which brightens the neighboring pixels of very bright pixels. Has a big impact on performance.")));
		me.TD(me, 1, 2, e = makeXonoticCheckBoxEx_T(0.5, 0, "hud_postprocessing_maxbluralpha", _("Extra postprocessing effects"),
			_("Enables special postprocessing effects for when damaged or under water or using a powerup")));
			makeMulti(e, "hud_powerup");
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
	me.TR(me);
		s = makeXonoticSlider_T(0.1, 1, 0.1, "r_motionblur", _("Motion blur strength - 0.4 recommended"));
		me.TD(me, 1, 1, e = makeXonoticSliderCheckBox(0, 1, s, _("Motion blur:")));
			e.applyButton = effectsApplyButton;
			if (s.value != e.savedValue)
				e.savedValue = 0.4; // default
		me.TD(me, 1, 2, s);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, effectsApplyButton);
}
