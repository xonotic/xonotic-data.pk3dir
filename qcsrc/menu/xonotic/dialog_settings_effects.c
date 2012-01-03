#ifdef INTERFACE
CLASS(XonoticEffectsSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticEffectsSettingsTab, fill, void(entity))
	ATTRIB(XonoticEffectsSettingsTab, title, string, _("Effects"))
	ATTRIB(XonoticEffectsSettingsTab, intendedWidth, float, 0.9)
	ATTRIB(XonoticEffectsSettingsTab, rows, float, 17)
	ATTRIB(XonoticEffectsSettingsTab, columns, float, 6.5)
ENDCLASS(XonoticEffectsSettingsTab)
entity makeXonoticEffectsSettingsTab();
float updateCompression();
#endif

#ifdef IMPLEMENTATION
entity makeXonoticEffectsSettingsTab()
{
	entity me;
	me = spawnXonoticEffectsSettingsTab();
	me.configureDialog(me);
	return me;
}

float someShadowCvarIsEnabled(entity box)
{
	if(cvar("r_shadow_realtime_dlight"))
		if(cvar("r_shadow_realtime_dlight_shadows"))
			return TRUE;
	if(cvar("r_shadow_realtime_world"))
		if(cvar("r_shadow_realtime_world_shadows"))
			return TRUE;
	return FALSE;
}

void XonoticEffectsSettingsTab_fill(entity me)
{
	entity e, s;
	float n;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Quality preset:")));
		n = 5 + 2 * !!cvar("developer");
		if(cvar("developer"))
			me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^OMG!")), '1 0 1', "exec effects-omg.cfg", 0));
		me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^Low")), '0 0 0', "exec effects-low.cfg", 0));
		me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^Medium")), '0 0 0', "exec effects-med.cfg", 0));
		me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^Normal")), '0 0 0', "exec effects-normal.cfg", 0));
		me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^High")), '0 0 0', "exec effects-high.cfg", 0));
		me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^Ultra")), '0 0 0', "exec effects-ultra.cfg", 0));
		if(cvar("developer"))
			me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton(ZCTX(_("PRE^Ultimate")), '0 0 0', "exec effects-ultimate.cfg", 0));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.1, e = makeXonoticTextLabel(0, _("Geometry detail:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("r_subdivisions_tolerance"));
			e.addValue(e, ZCTX(_("DET^Lowest")), "16");
			e.addValue(e, ZCTX(_("DET^Low")), "8");
			e.addValue(e, ZCTX(_("DET^Normal")), "4");
			e.addValue(e, ZCTX(_("DET^Good")), "3");
			e.addValue(e, ZCTX(_("DET^Best")), "2");
			e.addValue(e, ZCTX(_("DET^Insane")), "1");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1.1, e = makeXonoticTextLabel(0, _("Antialiasing:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("vid_samples"));
			e.addValue(e, ZCTX(_("AA^Disabled")), "1");
			e.addValue(e, _("2x"), "2");
			e.addValue(e, _("4x"), "4");
			e.configureXonoticTextSliderValues(e);
			setDependent(e, "r_viewfbo", 0, 0);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 0, "r_viewfbo", _("High-quality frame buffer")));
			setDependent(e, "vid_samples", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1.1, e = makeXonoticTextLabel(0, _("Texture resolution:")));
		me.TD(me, 1, 2, e = makeXonoticPicmipSlider());
			if(cvar("developer"))
				e.addValue(e, ZCTX(_("RES^Leet")), "1337");
			e.addValue(e, ZCTX(_("RES^Lowest")), "2");
			e.addValue(e, ZCTX(_("RES^Low")), "1");
			e.addValue(e, ZCTX(_("RES^Normal")), "0");
			e.addValue(e, ZCTX(_("RES^Good")), "-1");
			e.addValue(e, ZCTX(_("RES^Best")), "-2");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TDempty(me, 0.2);
		{
			// detect texture compression method
			float f;
			f = updateCompression();
			switch(f)
			{
				case 0:
					break;
				case 1:
					me.TD(me, 1, 2.8, e = makeXonoticCheckBox(1, "r_texture_dds_load", _("Avoid lossy texture compression")));
					break;
				case 2:
					me.TD(me, 1, 2.8, e = makeXonoticCheckBox(1, "r_texture_dds_load", _("Avoid lossy texture compression")));
						makeMulti(e, "gl_texturecompression");
					break;
			}
		}
	me.TR(me);
	me.TD(me, 1, 1.1, e = makeXonoticTextLabel(0, _("Anisotropy:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("gl_texture_anisotropy"));
			e.addValue(e, ZCTX(_("ANISO^Disabled")), "1");
			e.addValue(e, _("2x"), "2");
			e.addValue(e, _("4x"), "4");
			e.addValue(e, _("8x"), "8");
			e.addValue(e, _("16x"), "16");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.1, e = makeXonoticTextLabel(0, _("Particle quality:")));
		me.TD(me, 1, 1.9, e = makeXonoticSlider(0.2, 1.0, 0.1, "cl_particles_quality"));
	me.TR(me);
		me.TD(me, 1, 1.1, e = makeXonoticTextLabel(0, _("Particle distance:")));
		me.TD(me, 1, 1.9, e = makeXonoticSlider(500, 2000, 100, "r_drawparticles_drawdistance"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticCheckBox(0, "cl_decals", _("Decals")));
		me.TD(me, 1, 1.5, e = makeXonoticCheckBox(0, "cl_decals_models", _("Decals on models")));
			setDependent(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Distance:")));
			setDependent(e, "cl_decals", 1, 1);
		me.TD(me, 1, 1.9, e = makeXonoticSlider(200, 500, 20, "r_drawdecals_drawdistance"));
			setDependent(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
	    me.TD(me, 1, 0.9, e = makeXonoticTextLabel(0, _("Time:")));
	        setDependent(e, "cl_decals", 1, 1);
	    me.TD(me, 1, 1.9, e = makeXonoticSlider(1, 20, 1, "cl_decals_time"));
	        setDependent(e, "cl_decals", 1, 1);

	me.gotoRC(me, 2, 3.5); me.setFirstColumn(me, me.currentColumn);
	me.TD(me, 1, 1.2, e = makeXonoticCheckBox(1, "mod_q3bsp_nolightmaps", _("Use lightmaps")));
	me.TD(me, 1, 1.2, e = makeXonoticCheckBox(0, "r_glsl_deluxemapping", _("Deluxe mapping")));
		setDependentAND(e, "vid_gl20", 1, 1, "mod_q3bsp_nolightmaps", 0, 0);
	me.TD(me, 1, 0.6, e = makeXonoticCheckBox(0, "r_shadow_gloss", _("Gloss"))); // FIXME move this box elsewhere, it has nothing to do with Q3BSP lightmaps
		setDependent(e, "vid_gl20", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticCheckBox(0, "r_glsl_offsetmapping", _("Offset mapping")));
			setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox(0, "r_glsl_offsetmapping_reliefmapping", _("Relief mapping")));
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
		if(cvar("developer"))
			me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(3, 0, "r_showsurfaces", _("Show surfaces")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, string_null, string_null, _("No dynamic lighting")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, "gl_flashblend", string_null, _("Flash blend approximation")));
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, "r_shadow_realtime_dlight", string_null, _("Realtime dynamic lighting")));
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
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_coronas", _("Coronas")));
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "r_coronas_occlusionquery", _("Use Occlusion Queries")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "r_bloom", _("High Dynamic Range (HDR)")));
	
	me.TR(me);
		s = makeXonoticSlider(0.1, 1, 0.1, "r_motionblur");
		me.TD(me, 1, 1, e = makeXonoticSliderCheckBox(0, 1, s, _("Motion blur:")));
		if(s.value != e.savedValue)
			e.savedValue = 0.5; // default
		me.TD(me, 1, 2, s);
	me.TR(me);
		e = makeXonoticCheckBoxEx(0.5, 0, "hud_postprocessing_maxbluralpha", _("Blur and sharpen postprocessing"));
		makeMulti(e, "hud_powerup");
		me.TD(me, 1, 2, e);
	
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "vid_restart", COMMANDBUTTON_APPLY));
}
#endif
