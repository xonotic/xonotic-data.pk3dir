#include "dialog_settings_graphics_dynamic.qh"

#include "dialog_settings_graphics.qh"

#include "checkbox.qh"
#include "checkbox_slider_invalid.qh"
#include "commandbutton.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "textlabel.qh"

void XonoticGraphicsDynamicSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGraphicsDynamicSettingsTab()
{
	entity me = NEW(XonoticGraphicsDynamicSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGraphicsDynamicSettingsTab_fill(entity me)
{
	entity e, s;
	entity effectsApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "vid_restart", COMMANDBUTTON_APPLY);
		effectsApplyButton.disableOnClick = true;

	GraphicsSettings_addPresetButtons(me, effectsApplyButton);

	me.gotoRC(me, 2, 1); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeXonoticCheckBox_T(0, "r_bloom", _("Bloom"),
			_("Enable bloom effect, which brightens the neighboring pixels of very bright pixels. Has a big impact on performance.")));
		me.TD(me, 1, 2, e = makeXonoticCheckBoxEx_T(0.5, 0, "hud_postprocessing_maxbluralpha", _("Extra postprocessing effects"),
			_("Enables special postprocessing effects for when damaged or under water or using a powerup")));
			makeMulti(e, "hud_powerup");
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);

	me.TR(me);
		s = makeXonoticSlider_T(0.1, 1, 0.1, "r_motionblur", _("Motion blur strength - 0.4 recommended"));
		s.formatString = _("%sx");
		me.TD(me, 1, 1, e = makeXonoticSliderCheckBox(0, 1, s, _("Motion blur:")));
			e.applyButton = effectsApplyButton;
			if (s.value != e.savedValue)
				e.savedValue = 0.4; // default
		me.TD(me, 1, 2, s);

	me.TR(me);
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
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox_T(0, "cl_decals", _("Decals"), _("Enable decals (bullet holes and blood)")));
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox(0, "cl_decals_models", _("Decals on models")));
			setDependent(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Distance:")));
			setDependentNOT(e, "cl_decals_fadetime", 0);
			setDependentAND(e, "cl_decals", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(200, 500, 20, "r_drawdecals_drawdistance",
			_("Decals further away than this will not be drawn")));
			e.formatString = _("%s qu");
			setDependentNOT(e, "cl_decals_fadetime", 0);
			setDependentAND(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Fade time:")));
			setDependent(e, "cl_decals", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1, 20, 1, "cl_decals_fadetime", _("Time in seconds before decals fade away")));
			e.formatString = "s";
			setDependent(e, "cl_decals", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Damage effects:")));
		me.TD(me, 1, 1.8, e = makeXonoticMixedSlider("cl_damageeffect"));
			e.setValueSpace(e, e.valueSpace * (10/9));
			e.addText(e, ZCTX(_("DMGFX^Disabled")), 0);
			e.addText(e,      _("Skeletal"),        1);
			e.addText(e, ZCTX(_("DMGFX^All")),      2);
			e.configureXonoticMixedSliderValues(e);

	me.TR(me);
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox(0, "cl_particles", _("Particles")));
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox_T(0, "cl_spawn_point_particles", _("Spawnpoint effects"),
			_("Particle effects at all spawn points and whenever a player spawns")));
			makeMulti(e, "cl_spawn_event_particles");
			setDependent(e, "cl_particles", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Quality:")));
			setDependent(e, "cl_particles", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 3.0, 0.25, "cl_particles_quality",
			_("Multiplier for amount of particles. Less means less particles, which in turn gives for better performance")));
			e.formatString = _("%sx");
			setDependent(e, "cl_particles", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Distance:")));
			setDependent(e, "cl_particles", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(200, 3000, 200, "r_drawparticles_drawdistance",
			_("Particles further away than this will not be drawn")));
			e.formatString = _("%s qu");
			setDependent(e, "cl_particles", 1, 1);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, effectsApplyButton);
}
