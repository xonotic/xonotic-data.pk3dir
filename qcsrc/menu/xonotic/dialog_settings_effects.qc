#ifndef DIALOG_SETTINGS_EFFECTS_H
#define DIALOG_SETTINGS_EFFECTS_H
#include "tab.qc"
CLASS(XonoticEffectsSettingsTab, XonoticTab)
	METHOD(XonoticEffectsSettingsTab, fill, void(entity))
	ATTRIB(XonoticEffectsSettingsTab, title, string, _("Effects"))
	ATTRIB(XonoticEffectsSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticEffectsSettingsTab, rows, float, 15.5)
	ATTRIB(XonoticEffectsSettingsTab, columns, float, 6.2) // added extra .2 for center space
ENDCLASS(XonoticEffectsSettingsTab)
entity makeXonoticEffectsSettingsTab();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticEffectsSettingsTab()
{
	entity me;
	me = NEW(XonoticEffectsSettingsTab);
	me.configureDialog(me);
	return me;
}

float someShadowCvarIsEnabled(entity box)
{
	if(cvar("r_shadow_realtime_dlight"))
		if(cvar("r_shadow_realtime_dlight_shadows"))
			return true;
	if(cvar("r_shadow_realtime_world"))
		if(cvar("r_shadow_realtime_world_shadows"))
			return true;
	return false;
}

void XonoticEffectsSettingsTab_fill(entity me)
{
	entity e, s;
	float n;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Quality preset:")));
		n = 5 + 2 * !!cvar("developer");
		if(cvar("developer"))
			me.TD(me, 1, 5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^OMG!")), '1 0 1', "exec effects-omg.cfg", 0));
		me.TD(me, 1, 5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^Low")), '0 0 0', "exec effects-low.cfg", 0));
		me.TD(me, 1, 5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^Medium")), '0 0 0', "exec effects-med.cfg", 0));
		me.TD(me, 1, 5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^Normal")), '0 0 0', "exec effects-normal.cfg", 0));
		me.TD(me, 1, 5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^High")), '0 0 0', "exec effects-high.cfg", 0));
		me.TD(me, 1, 5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^Ultra")), '0 0 0', "exec effects-ultra.cfg", 0));
		if(cvar("developer"))
			me.TD(me, 1, 5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^Ultimate")), '0.5 0 0', "exec effects-ultimate.cfg", 0));

	me.gotoRC(me, 1.25, 0);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Geometry detail:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("r_subdivisions_tolerance"));
			e.addValue(e, ZCTX(_("DET^Lowest")), "16");
			e.addValue(e, ZCTX(_("DET^Low")), "8");
			e.addValue(e, ZCTX(_("DET^Normal")), "4");
			e.addValue(e, ZCTX(_("DET^Good")), "3");
			e.addValue(e, ZCTX(_("DET^Best")), "2");
			e.addValue(e, ZCTX(_("DET^Insane")), "1");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Player detail:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_playerdetailreduction"));
			e.addValue(e, ZCTX(_("PDET^Low")), "4");
			e.addValue(e, ZCTX(_("PDET^Medium")), "3");
			e.addValue(e, ZCTX(_("PDET^Normal")), "2");
			e.addValue(e, ZCTX(_("PDET^Good")), "1");
			e.addValue(e, ZCTX(_("PDET^Best")), "0");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Texture resolution:")));
			setDependent(e, "r_showsurfaces", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticPicmipSlider());
			if(cvar("developer"))
				e.addValue(e, ZCTX(_("RES^Leet")), "1337");
			e.addValue(e, ZCTX(_("RES^Lowest")), "3");
			e.addValue(e, ZCTX(_("RES^Very low")), "2");
			e.addValue(e, ZCTX(_("RES^Low")), "1");
			e.addValue(e, ZCTX(_("RES^Normal")), "0");
			e.addValue(e, ZCTX(_("RES^Good")), "-1");
			e.addValue(e, ZCTX(_("RES^Best")), "-2");
			e.configureXonoticTextSliderValues(e);
			setDependent(e, "r_showsurfaces", 0, 0);
	me.TR(me);
		me.TDempty(me, 0.2);
		{
			// detect texture compression method
			float f;
			f = updateCompression();
			switch(f)
			{
				case 0:
					me.TD(me, 1, 2.8, e = makeXonoticCheckBox(1, "r_texture_dds_load", _("Avoid lossy texture compression")));
						e.disabled = 1; // just show the checkbox anyway, but with no ability to control it
					break;
				case 1:
					me.TD(me, 1, 2.8, e = makeXonoticCheckBox(1, "r_texture_dds_load", _("Avoid lossy texture compression")));
						setDependent(e, "r_showsurfaces", 0, 0);
					break;
				case 2:
					me.TD(me, 1, 2.8, e = makeXonoticCheckBox(1, "r_texture_dds_load", _("Avoid lossy texture compression")));
						setDependent(e, "r_showsurfaces", 0, 0);
						makeMulti(e, "gl_texturecompression");
					break;
			}
		}
	me.TR(me);
		if(cvar("developer"))
		{
			me.TDempty(me, 0.2);
			me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx(3, 0, "r_showsurfaces", _("Show surfaces")));
		}
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(1, "mod_q3bsp_nolightmaps", _("Use lightmaps")));
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_glsl_deluxemapping", _("Deluxe mapping")));
			setDependentAND(e, "vid_gl20", 1, 1, "mod_q3bsp_nolightmaps", 0, 0);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_shadow_gloss", _("Gloss")));
			setDependentAND3(e, "vid_gl20", 1, 1, "mod_q3bsp_nolightmaps", 0, 0, "r_glsl_deluxemapping", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_glsl_offsetmapping", _("Offset mapping")));
			setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_glsl_offsetmapping_reliefmapping", _("Relief mapping")));
			setDependentAND(e, "vid_gl20", 1, 1, "r_glsl_offsetmapping", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_water", _("Reflections:")));
			setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticTextSlider("r_water_resolutionmultiplier"));
			e.addValue(e, _("Blurred"), "0.25");
			e.addValue(e, ZCTX(_("REFL^Good")), "0.5");
			e.addValue(e, _("Sharp"), "1");
			e.configureXonoticTextSliderValues(e);
			setDependentAND(e, "vid_gl20", 1, 1, "r_water", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "cl_decals", _("Decals")));
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "cl_decals_models", _("Decals on models")));
			setDependent(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Distance:")));
			setDependent(e, "cl_decals", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(200, 500, 20, "r_drawdecals_drawdistance"));
			setDependent(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Time:")));
			setDependent(e, "cl_decals", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(1, 20, 1, "cl_decals_fadetime"));
			setDependent(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Damage effects:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("cl_damageeffect"));
			e.addValue(e, ZCTX(_("DMGFX^Disabled")), "0");
			e.addValue(e, _("Skeletal"), "1");
			e.addValue(e, ZCTX(_("DMGFX^All")), "2");
			e.configureXonoticTextSliderValues(e);

	me.gotoRC(me, 1.25, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, "r_coronas", "0", _("No dynamic lighting")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, "gl_flashblend", string_null, _("Fake corona lighting")));
		makeMulti(e, "r_coronas");
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, "r_shadow_realtime_dlight", string_null, _("Realtime dynamic lighting")));
		makeMulti(e, "r_coronas");
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_shadow_realtime_dlight_shadows", _("Shadows")));
			setDependent(e, "r_shadow_realtime_dlight", 1, 1);
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "r_shadow_realtime_world", _("Realtime world lighting")));
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_shadow_realtime_world_shadows", _("Shadows")));
			setDependent(e, "r_shadow_realtime_world", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox(0, "r_shadow_usenormalmap", _("Use normal maps")));
			setDependentOR(e, "r_shadow_realtime_dlight", 1, 1, "r_shadow_realtime_world", 1, 1);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_shadow_shadowmapping", _("Soft shadows")));
			setDependentWeird(e, someShadowCvarIsEnabled);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox(0, "r_coronas_occlusionquery", _("Fade corona according to visibility")));
			setDependent(e, "r_coronas", 1, 1);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_bloom", _("Bloom")));
		me.TD(me, 1, 2, e = makeXonoticCheckBoxEx(0.5, 0, "hud_postprocessing_maxbluralpha", _("Extra postprocessing effects")));
			makeMulti(e, "hud_powerup");
			setDependent(e, "vid_gl20", 1, 1);
	me.TR(me);
		s = makeXonoticSlider(0.1, 1, 0.1, "r_motionblur");
		me.TD(me, 1, 1, e = makeXonoticSliderCheckBox(0, 1, s, _("Motion blur:")));
		if(s.value != e.savedValue)
			e.savedValue = 0.4; // default
		me.TD(me, 1, 2, s);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "cl_particles", _("Particles")));
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "cl_spawn_point_particles", _("Spawnpoint effects")));
			makeMulti(e, "cl_spawn_event_particles");
			setDependent(e, "cl_particles", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Quality:")));
			setDependent(e, "cl_particles", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticParticlesSlider());
			setDependent(e, "cl_particles", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Distance:")));
			setDependent(e, "cl_particles", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(200, 500, 20, "r_drawparticles_drawdistance"));
			setDependent(e, "cl_particles", 1, 1);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "vid_restart", COMMANDBUTTON_APPLY));
}
#endif
