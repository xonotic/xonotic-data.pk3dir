#include "dialog_settings_video.qh"

#include "commandbutton.qh"
#include "textlabel.qh"
#include "textslider.qh"
#include "checkbox.qh"
#include "slider.qh"
#include "slider_resolution.qh"
#include "radiobutton.qh"

entity makeXonoticVideoSettingsTab()
{
	entity me;
	me = NEW(XonoticVideoSettingsTab);
	me.configureDialog(me);
	return me;
}
void XonoticVideoSettingsTab_fill(entity me)
{
	entity e;
	entity videoApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0',
		"vid_width $_menu_vid_width;"
		"vid_height $_menu_vid_height;"
		"vid_pixelheight $_menu_vid_pixelheight;"
		"vid_desktopfullscreen $_menu_vid_desktopfullscreen;"
		"menu_cmd update_conwidths_before_vid_restart;"
		"vid_restart;"
		"menu_cmd sync;"
		, COMMANDBUTTON_APPLY);
	videoApplyButton.disableOnClick = true;

	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Resolution:")));
		me.TD(me, 1, 2, e = makeXonoticResolutionSlider());
			e.applyButton = videoApplyButton;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Font/UI size:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider("menu_vid_scale"));
			e.addValue(e, ZCTX(_("SZ^Unreadable")), "-1");
			e.addValue(e, ZCTX(_("SZ^Tiny")), "-0.75");
			e.addValue(e, ZCTX(_("SZ^Little")), "-0.5");
			e.addValue(e, ZCTX(_("SZ^Small")), "-0.25");
			e.addValue(e, ZCTX(_("SZ^Medium")), "0");
			e.addValue(e, ZCTX(_("SZ^Large")), "0.25");
			e.addValue(e, ZCTX(_("SZ^Huge")), "0.5");
			e.addValue(e, ZCTX(_("SZ^Gigantic")), "0.75");
			e.addValue(e, ZCTX(_("SZ^Colossal")), "1");
			e.configureXonoticTextSliderValues(e);
			e.applyButton = videoApplyButton;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Color depth:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("vid_bitsperpixel",
			_("How many bits per pixel (BPP) to render at, 32 is recommended")));
			e.addValue(e, _("16bit"), "16");
			e.addValue(e, _("32bit"), "32");
			e.configureXonoticTextSliderValues(e);
			e.applyButton = videoApplyButton;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticCheckBox(0, "vid_fullscreen", _("Full screen")));
			e.applyButton = videoApplyButton;
		me.TD(me, 1, 2, e = makeXonoticCheckBox_T(0, "vid_vsync", _("Vertical Synchronization"),
			_("Vsync prevents tearing, but increases latency and caps your fps at the screen refresh rate")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 0, "r_viewfbo", _("High-quality frame buffer")));
		if(cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
			setDependent(e, "vid_samples", 0, 1);

	me.TR(me);
	me.TR(me);
	if(cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
	{
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Antialiasing:")));
			setDependent(e, "r_viewfbo", 0, 0);
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("vid_samples",
			_("Enable antialiasing, which smooths the edges of 3D geometry. Note that it might decrease performance by quite a lot")));
			e.addValue(e, ZCTX(_("AA^Disabled")), "1");
			e.addValue(e, _("2x"), "2");
			e.addValue(e, _("4x"), "4");
			e.configureXonoticTextSliderValues(e);
			setDependent(e, "r_viewfbo", 0, 0);
			e.applyButton = videoApplyButton;
	}
	else
	{
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Resolution scaling:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.5, 2, 0.25, "r_viewscale",
			_("Screen or window size multiplier, above 1x does antialiasing, below 1x may help slow GPUs")));
	}
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Anisotropy:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("gl_texture_anisotropy",
			_("Anisotropic filtering quality")));
			e.addValue(e, ZCTX(_("ANISO^Disabled")), "1");
			e.addValue(e, _("2x"), "2");
			e.addValue(e, _("4x"), "4");
			e.addValue(e, _("8x"), "8");
			e.addValue(e, _("16x"), "16");
			e.configureXonoticTextSliderValues(e);

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Depth first:")));
		me.TD(me, 1, 2, e = makeXonoticTextSlider_T("r_depthfirst",
			_("Eliminate overdraw by rendering a depth-only version of the scene before the normal rendering starts")));
			e.addValue(e, ZCTX(_("DF^Disabled")), "0");
			e.addValue(e, ZCTX(_("DF^World")), "1");
			e.addValue(e, ZCTX(_("DF^All")), "2");
			e.configureXonoticTextSliderValues(e);

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Brightness:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.0, 0.5, 0.02, "v_brightness",
			_("Brightness of black")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Contrast:")));
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1.0, 3.0, 0.05, "v_contrast",
			_("Brightness of white")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Gamma:")));
		if(cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
			setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.5, 2.0, 0.05, "v_gamma",
			_("Inverse gamma correction value, a brightness effect that does not affect white or black")));
		if(cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
			setDependent(e, "vid_gl20", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Contrast boost:")));
		if(cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
			setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(1.0, 5.0, 0.1, "v_contrastboost",
			_("By how much to multiply the contrast in dark areas")));
		if(cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
			setDependent(e, "vid_gl20", 1, 1);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Saturation:")));
		if(cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
			setDependent(e, "vid_gl20", 1, 1);
		me.TD(me, 1, 2, e = makeXonoticSlider_T(0.5, 2.0, 0.05, "r_glsl_saturation",
			_("Saturation adjustment (0 = grayscale, 1 = normal, 2 = oversaturated), requires GLSL color control")));
		if(cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
			setDependent(e, "vid_gl20", 1, 1);
	me.TR(me);
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
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "gl_finish", _("Wait for GPU to finish each frame"),
			_("Make the CPU wait for the GPU to finish each frame, can help with some strange input or video lag on some machines")));
	me.TR(me);
	if(cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
	{
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "vid_gl20", _("Use OpenGL 2.0 shaders (GLSL)")));
			e.applyButton = videoApplyButton;
	}
	if(cvar("developer") > 0)
	{
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "v_flipped", _("Flip view horizontally"),
				_("Poor man's left handed mode")));
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "v_psycho", _("Psycho coloring (easter egg)")));
			if(cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
		me.TR(me);
			me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "r_trippy", _("Trippy vertices (easter egg)")));
			if(cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_gl20", 1, 1);
	}

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, videoApplyButton);
}
