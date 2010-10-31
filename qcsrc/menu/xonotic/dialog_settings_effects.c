#ifdef INTERFACE
CLASS(XonoticEffectsSettingsTab) EXTENDS(XonoticTab)
	METHOD(XonoticEffectsSettingsTab, fill, void(entity))
	ATTRIB(XonoticEffectsSettingsTab, title, string, "Effects")
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

float updateCompression()
{
	float fh;
	float have_dds, have_jpg, have_tga;
	if((have_dds = ((fh = fopen("dds/particles/particlefont.dds", FILE_READ)) >= 0)))
		fclose(fh);
	if((have_jpg = ((fh = fopen("particles/particlefont.jpg", FILE_READ)) >= 0)))
		fclose(fh);
	if((have_tga = ((fh = fopen("particles/particlefont.tga", FILE_READ)) >= 0)))
		fclose(fh);
	if(have_dds && (have_jpg || have_tga))
	{
		cvar_set("gl_texturecompression", "0");
		return 1;
	}
	else if(have_dds)
	{
		cvar_set("gl_texturecompression", "0");
		cvar_set("r_texture_dds_load", "1");
		return 0;
	}
	else
	{
		cvar_set("gl_texturecompression", cvar_string("r_texture_dds_load"));
		return 2;
	}
}

void XonoticEffectsSettingsTab_fill(entity me)
{
	entity e, s;
	float n;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Quality preset:"));
		n = 5 + 2 * !!cvar("developer");
		if(cvar("developer"))
			me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton("OMG!", '1 0 1', "exec effects-omg.cfg", 0));
		me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton("Low", '0 0 0', "exec effects-low.cfg", 0));
		me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton("Medium", '0 0 0', "exec effects-med.cfg", 0));
		me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton("Normal", '0 0 0', "exec effects-normal.cfg", 0));
		me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton("High", '0 0 0', "exec effects-high.cfg", 0));
		me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton("Ultra", '0 0 0', "exec effects-ultra.cfg", 0));
		if(cvar("developer"))
			me.TD(me, 1, 5.5 / n, e = makeXonoticCommandButton("Ultimate", '0 0 0', "exec effects-ultimate.cfg", 0));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Geometry detail:"));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("r_subdivisions_tolerance"));
			e.addValue(e, "Lowest", "16");
			e.addValue(e, "Low", "8");
			e.addValue(e, "Normal", "4");
			e.addValue(e, "Good", "3");
			e.addValue(e, "Best", "2");
			e.addValue(e, "Insane", "1");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Antialiasing:"));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("vid_samples"));
			e.addValue(e, "Disabled", "1");
			e.addValue(e, "2x", "2");
			e.addValue(e, "4x", "4");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Texture resolution:"));
		me.TD(me, 1, 2, e = makeXonoticPicmipSlider());
			if(cvar("developer"))
				e.addValue(e, "Leet", "1337");
			e.addValue(e, "Lowest", "2");
			e.addValue(e, "Low", "1");
			e.addValue(e, "Normal", "0");
			e.addValue(e, "Good", "-1");
			e.addValue(e, "Best", "-2");
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
					me.TD(me, 1, 2.8, e = makeXonoticCheckBox(1, "r_texture_dds_load", "Avoid lossy texture compression"));
					break;
				case 2:
					me.TD(me, 1, 2.8, e = makeXonoticCheckBox(1, "r_texture_dds_load", "Avoid lossy texture compression"));
						makeMulti(e, "gl_texturecompression");
					break;
			}
		}
	me.TR(me);
	me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Anisotropy:"));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("gl_texture_anisotropy"));
			e.addValue(e, "Disabled", "1");
			e.addValue(e, "2x", "2");
			e.addValue(e, "4x", "4");
			e.addValue(e, "8x", "8");
			e.addValue(e, "16x", "16");
			e.configureXonoticTextSliderValues(e);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Particle quality:"));
		me.TD(me, 1, 2, e = makeXonoticSlider(0.2, 1.0, 0.1, "cl_particles_quality"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, "Particle dist.:"));
		me.TD(me, 1, 2, e = makeXonoticSlider(500, 2000, 100, "r_drawparticles_drawdistance"));
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "cl_decals", "Decals"));
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, "Distance:"));
			setDependent(e, "cl_decals", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider(200, 500, 20, "r_drawdecals_drawdistance"));
			setDependent(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
	    me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, "Time:"));
	        setDependent(e, "cl_decals", 1, 1);
	    me.TD(me, 1, 2, e = makeXonoticSlider(1, 20, 1, "cl_decals_time"));
	        setDependent(e, "cl_decals", 1, 1);

	me.gotoRC(me, 2, 3.5); me.setFirstColumn(me, me.currentColumn);
	me.TD(me, 1, 2, e = makeXonoticCheckBox(1, "mod_q3bsp_nolightmaps", "Use lightmaps"));
	me.TD(me, 1, 1.9, e = makeXonoticCheckBox(0, "r_glsl_deluxemapping", "Deluxe mapping"));
		setDependentAND(e, "vid_gl20", 1, 1, "mod_q3bsp_nolightmaps", 0, 0);
	me.TD(me, 1, 0.7, e = makeXonoticCheckBox(0, "r_shadow_gloss", "Gloss"));
		setDependentAND3(e, "vid_gl20", 1, 1, "r_glsl_deluxemapping", 1, 2, "mod_q3bsp_nolightmaps", 0, 0);
	me.TR(me);
		me.TD(me, 1, 1.5, e = makeXonoticCheckBox(0, "r_glsl_offsetmapping", "Offset mapping"));
			setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 1.9, e = makeXonoticCheckBox(0, "r_glsl_offsetmapping_reliefmapping", "Relief mapping"));
			setDependentAND(e, "vid_gl20", 1, 1, "r_glsl_offsetmapping", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_water", "Reflections:"));
			setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticTextSlider("r_water_resolutionmultiplier"));
			e.addValue(e, "Blurred", "0.25");
			e.addValue(e, "Good", "0.5");
			e.addValue(e, "Sharp", "1");
			e.configureXonoticTextSliderValues(e);
			setDependentAND(e, "vid_gl20", 1, 1, "r_water", 1, 1);
	me.TR(me);
		if(cvar("developer"))
			me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(3, 0, "r_showsurfaces", "Show surfaces"));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, string_null, string_null, "No dynamic lighting"));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticRadioButton(1, "gl_flashblend", string_null, "Flash blend approximation"));
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticRadioButton(1, "r_shadow_realtime_dlight", string_null, "Realtime dynamic lighting"));
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_shadow_realtime_dlight_shadows", "Shadows"));
			setDependent(e, "r_shadow_realtime_dlight", 1, 1);
	me.TR(me);
		me.TD(me, 1, 2, e = makeXonoticCheckBox(0, "r_shadow_realtime_world", "Realtime world lighting"));
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_shadow_realtime_world_shadows", "Shadows"));
			setDependent(e, "r_shadow_realtime_world", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1.8, e = makeXonoticCheckBox(0, "r_shadow_usenormalmap", "Use normal maps"));
			setDependentOR(e, "r_shadow_realtime_dlight", 1, 1, "r_shadow_realtime_world", 1, 1);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_shadow_shadowmapping", "Soft shadows"));
			setDependentWeird(e, someShadowCvarIsEnabled);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_coronas", "Coronas"));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "r_bloom", "Bloom"));
			setDependent(e, "r_hdr", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticCheckBoxEx(2, 0, "r_hdr", "High Dynamic Range (HDR)"));
	
	me.TR(me);
		s = makeXonoticSlider(0.1, 1, 0.1, "r_motionblur");
		me.TD(me, 1, 1, e = makeXonoticSliderCheckBox(0, 1, s, "Motion blur:"));
		if(s.value != e.savedValue)
			e.savedValue = 0.5; // default
		me.TD(me, 1, 2, s);
	me.TR(me);
		s = makeXonoticSlider(0.1, 1, 0.1, "r_damageblur");
		me.TD(me, 1, 1, e = makeXonoticSliderCheckBox(0, 1, s, "Damage blur:"));
		if(s.value != e.savedValue)
			e.savedValue = 0.4; // default
		me.TD(me, 1, 2, s);
	
	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, makeXonoticCommandButton("Apply immediately", '0 0 0', "vid_restart", COMMANDBUTTON_APPLY));
}
#endif
