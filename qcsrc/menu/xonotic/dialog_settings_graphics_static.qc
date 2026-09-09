#include "dialog_settings_graphics_static.qh"

#include "dialog_settings_graphics.qh"

#include "checkbox.qh"
#include "commandbutton.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "slider_picmip.qh"
#include "textlabel.qh"

void XonoticGraphicsStaticSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticGraphicsStaticSettingsTab()
{
	entity me = NEW(XonoticGraphicsStaticSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticGraphicsStaticSettingsTab_fill(entity me)
{
	entity e;
	entity effectsApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "vid_restart", COMMANDBUTTON_APPLY);
		effectsApplyButton.disableOnClick = true;

	GraphicsSettings_addPresetButtons(me, effectsApplyButton);

	me.gotoRC(me, 2, 1); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1.1, e = makeXonoticTextLabel(0, _("Geometry detail:")));
		me.TD(me, 1, 1.9, e = makeXonoticMixedSlider_T("r_subdivisions_tolerance",
			_("Change the smoothness of the curves on the map")));
			e.setValueSpace(e, e.valueSpace * (20/19));
			e.addText(e, ZCTX(_("DET^Lowest")), 16);
			e.addText(e, ZCTX(_("DET^Low")),    8);
			e.addText(e, ZCTX(_("DET^Normal")), 4);
			e.addText(e, ZCTX(_("DET^Good")),   3);
			e.addText(e, ZCTX(_("DET^Best")),   2);
			e.addText(e, ZCTX(_("DET^Insane")), 1);
			e.configureXonoticMixedSliderValues(e);
			e.applyButton = effectsApplyButton;
	me.TR(me);
		me.TD(me, 1, 1.1, e = makeXonoticTextLabel(0, _("Player detail:")));
		me.TD(me, 1, 1.9, e = makeXonoticMixedSlider("cl_playerdetailreduction"));
			e.setValueSpace(e, e.valueSpace * (20/19));
			e.addText(e, ZCTX(_("PDET^Low")),    4);
			e.addText(e, ZCTX(_("PDET^Medium")), 3);
			e.addText(e, ZCTX(_("PDET^Normal")), 2);
			e.addText(e, ZCTX(_("PDET^Good")),   1);
			e.addText(e, ZCTX(_("PDET^Best")),   0);
			e.configureXonoticMixedSliderValues(e);
			e.applyButton = effectsApplyButton;
	me.TR(me);
		me.TD(me, 1, 1.1, e = makeXonoticTextLabel(0, _("Texture resolution:")));
			setDependent(e, "r_showsurfaces", 0, 0);
		me.TD(me, 1, 1.9, e = makeXonoticPicmipSlider());
			e.setValueSpace(e, e.valueSpace * (20/19));
			e.addText(e, ZCTX(_("RES^Lowest")),   1337);
			e.addText(e, ZCTX(_("RES^Very low")), 2);
			e.addText(e, ZCTX(_("RES^Low")),      1);
			e.addText(e, ZCTX(_("RES^Normal")),   0);
			e.addText(e, ZCTX(_("RES^Good")),    -1);
			e.addText(e, ZCTX(_("RES^Best")),    -2);
			e.configureXonoticMixedSliderValues(e);
			setDependent(e, "r_showsurfaces", 0, 0);
			e.applyButton = effectsApplyButton;
	me.TR(me);
		bool can_dds = GL_Have_TextureCompression();
		me.TD(me, 1, 1.1, e = makeXonoticTextLabel(0, _("Texture compression:")));
			if (can_dds)
				setDependent(e, "r_showsurfaces", 0, 0);
			else
				e.disabled = true;
		me.TD(me, 1, 1.9, e = makeXonoticMixedSlider("gl_texturecompression"));
			e.setValueSpace(e, e.valueSpace * (20/19));
			e.addText(e, ZCTX(_("TCOMP^Fast")), 1);
			e.addText(e, ZCTX(_("TCOMP^Good")), 2);
			e.addText(e, ZCTX(_("TCOMP^None")), 0);
			e.configureXonoticMixedSliderValues(e);
			if (can_dds)
				setDependent(e, "r_showsurfaces", 0, 0);
			else
				e.disabled = true;
			e.applyButton = effectsApplyButton;

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx_T(1, 0, "r_sky", _("Show sky"), _("Disable sky for performance and visibility")));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "r_glsl_offsetmapping", _("Offset mapping"),
			_("Offset mapping effect that will make textures with bumpmaps appear like they \"pop out\" of the flat 2D surface")));
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8, e = makeXonoticCheckBox_T(0, "r_glsl_offsetmapping_reliefmapping", _("Relief mapping"),
			_("Higher quality offset mapping, which also has a huge impact on performance")));
			setDependent(e, "r_glsl_offsetmapping", 1, 1);
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependentAND(e, "vid_gl20", 1, 1);

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, effectsApplyButton);
}
