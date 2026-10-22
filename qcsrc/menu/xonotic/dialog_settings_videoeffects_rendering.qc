#include "dialog_settings_videoeffects_rendering.qh"

#include "checkbox.qh"
#include "commandbutton.qh"
#include "mixedslider.qh"
#include "radiobutton.qh"
#include "slider.qh"
#include "textlabel.qh"

void XonoticVideoEffectsRenderingSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticVideoEffectsRenderingSettingsTab()
{
	entity me = NEW(XonoticVideoEffectsRenderingSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticVideoEffectsRenderingSettingsTab_fill(entity me)
{
	entity e;
	entity videoApplyButton = NULL; // may not need one

	me.gotoRC(me, 0, (me.columns - 3) * 0.5); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Rendering")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Brightness:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.0, 0.5, 0.02, "v_brightness", _("Brightness of black")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Contrast:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1.0, 3.0, 0.05, "v_contrast", _("Brightness of white")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Gamma:")));
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.5, 2.0, 0.05, "v_gamma",
			_("Inverse gamma correction value, a brightness effect that does not affect white or black")));
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Contrast boost:")));
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1.0, 5.0, 0.1, "v_contrastboost",
			_("By how much to multiply the contrast in dark areas")));
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Saturation:")));
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.5, 2.0, 0.05, "r_glsl_saturation",
			_("Saturation adjustment (0 = grayscale, 1 = normal, 2 = oversaturated), requires GLSL color control")));
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, ZCTX(_("LIT^Ambient:"))));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0, 20.0, 0.25, "r_ambient",
			_("Ambient lighting, if set too high it tends to make light on maps look dull and flat")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Intensity:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.5, 2.0, 0.05, "r_hdr_scenebrightness",
			_("Global rendering brightness")));

	me.TR(me);
	me.TR(me);
	if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
	{
		videoApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0', "vid_restart; menu_cmd sync", COMMANDBUTTON_APPLY);
			videoApplyButton.disableOnClick = true;

		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Antialiasing:")));
			setDependent(e, "r_viewfbo", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("vid_samples",
			_("Enable antialiasing, which smooths the edges of 3D geometry. Note that it might decrease performance by quite a lot")));
			e.formatString = _("%sx");
			e.addText(e, ZCTX(_("AA^Disabled")), 1);
			e.addRange(e, 2, 4, 2); // 2, 4
			e.configureXonoticMixedSliderValues(e);
			setDependent(e, "r_viewfbo", 0, 0);
			e.applyButton = videoApplyButton;
	}
	else
	{
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Resolution scaling:")));
		me.TD(me, 1, 1.8, e = makeXonoticSlider_T(0.5, 2, 0.25, "r_viewscale",
			_("Screen or window size multiplier, above 1x does antialiasing, below 1x may help slow GPUs")));
			e.setValueSpace(e, e.valueSpace * (10/9));
			e.formatString = _("%sx");
	}
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticTextLabel(0, _("Anisotropy:")));
		me.TD(me, 1, 1.8, e = makeXonoticMixedSlider_T("gl_texture_anisotropy", _("Anisotropic filtering quality")));
			e.setValueSpace(e, e.valueSpace * (10/9));
			e.formatString = _("%sx");
			e.addText(e, ZCTX(_("ANISO^Disabled")), 1);
			e.addRange(e, 2, 4, 2);  // 2, 4
			e.addRange(e, 8, 16, 8); // 8, 16
			e.configureXonoticMixedSliderValues(e);

	string df_tooltip = _("Eliminate overdraw by rendering a depth-only version of the scene before the normal rendering starts");
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Depth first:")));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton_T(1, "r_depthfirst", "0", ZCTX(_("DF^Disabled")), df_tooltip));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton_T(1, "r_depthfirst", "1", ZCTX(_("DF^World")),    df_tooltip));
		me.TD(me, 1, 2/3, e = makeXonoticRadioButton_T(1, "r_depthfirst", "2", ZCTX(_("DF^All")),      df_tooltip));

	if (videoApplyButton)
	{
		me.gotoRC(me, me.rows - 1, 0);
			me.TD(me, 1, me.columns, videoApplyButton);
	}
}
