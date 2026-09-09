#include "dialog_settings_videoeffects_detail.qh"

#include "checkbox.qh"
#include "commandbutton.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "slider_picmip.qh"
#include "textlabel.qh"

void XonoticVideoEffectsDetailSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticVideoEffectsDetailSettingsTab()
{
	entity me = NEW(XonoticVideoEffectsDetailSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticVideoEffectsDetailSettingsTab_fill(entity me)
{
	entity e;
	entity detailApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "vid_restart", COMMANDBUTTON_APPLY);
		detailApplyButton.disableOnClick = true;

	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Quality preset:")));
			e.align = 1;
			e.marginRight = 0.2;
		float width = (me.columns - 0.2 - 0.8) / 5;
	#define ADD_PRESET_BUTTON(translated_name, file_name) \
		me.TD(me, 1, width, e = makeXonoticCommandButton(ZCTX(translated_name), '0 0 0', "exec detail-" file_name ".cfg", 0)); \
			e.applyButton = detailApplyButton;
			ADD_PRESET_BUTTON(_("PRE^Low"),    "low")
			ADD_PRESET_BUTTON(_("PRE^Medium"), "med")
			ADD_PRESET_BUTTON(_("PRE^Normal"), "normal")
			ADD_PRESET_BUTTON(_("PRE^High"),   "high")
			ADD_PRESET_BUTTON(_("PRE^Ultra"),  "ultra")
	#undef ADD_PRESET_BUTTON

	me.gotoRC(me, 2, 1); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Geometry detail:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("r_subdivisions_tolerance",
			_("Change the smoothness of the curves on the map")));
			e.addText(e, ZCTX(_("DET^Lowest")), 16);
			e.addText(e, ZCTX(_("DET^Low")),    8);
			e.addText(e, ZCTX(_("DET^Normal")), 4);
			e.addText(e, ZCTX(_("DET^Good")),   3);
			e.addText(e, ZCTX(_("DET^Best")),   2);
			e.addText(e, ZCTX(_("DET^Insane")), 1);
			e.configureXonoticMixedSliderValues(e);
			e.applyButton = detailApplyButton;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Player detail:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_playerdetailreduction"));
			e.addText(e, ZCTX(_("PDET^Low")),    4);
			e.addText(e, ZCTX(_("PDET^Medium")), 3);
			e.addText(e, ZCTX(_("PDET^Normal")), 2);
			e.addText(e, ZCTX(_("PDET^Good")),   1);
			e.addText(e, ZCTX(_("PDET^Best")),   0);
			e.configureXonoticMixedSliderValues(e);
			e.applyButton = detailApplyButton;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Texture resolution:")));
			setDependent(e, "r_showsurfaces", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticPicmipSlider());
			e.addText(e, ZCTX(_("RES^Lowest")),   1337);
			e.addText(e, ZCTX(_("RES^Very low")), 2);
			e.addText(e, ZCTX(_("RES^Low")),      1);
			e.addText(e, ZCTX(_("RES^Normal")),   0);
			e.addText(e, ZCTX(_("RES^Good")),    -1);
			e.addText(e, ZCTX(_("RES^Best")),    -2);
			e.configureXonoticMixedSliderValues(e);
			setDependent(e, "r_showsurfaces", 0, 0);
			e.applyButton = detailApplyButton;
	bool can_dds = GL_Have_TextureCompression();
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Texture compression:")));
			if (can_dds)
				setDependent(e, "r_showsurfaces", 0, 0);
			else
				e.disabled = true;
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("gl_texturecompression"));
			e.addText(e, ZCTX(_("TCOMP^Fast")), 1);
			e.addText(e, ZCTX(_("TCOMP^Good")), 2);
			e.addText(e, ZCTX(_("TCOMP^None")), 0);
			e.configureXonoticMixedSliderValues(e);
			if (can_dds)
				setDependent(e, "r_showsurfaces", 0, 0);
			else
				e.disabled = true;
			e.applyButton = detailApplyButton;

	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBoxEx_T(1, 0, "r_sky", _("Show sky"), _("Disable sky for performance and visibility")));

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
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Damage effects:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_damageeffect"));
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
		me.TD(me, 1, me.columns, detailApplyButton);
}
