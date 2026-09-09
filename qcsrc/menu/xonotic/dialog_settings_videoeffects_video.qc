#include "dialog_settings_videoeffects_video.qh"

#include "checkbox.qh"
#include "commandbutton.qh"
#include "mixedslider.qh"
#include "slider.qh"
#include "slider_resolution.qh"
#include "textlabel.qh"

void XonoticVideoEffectsVideoSettingsTab_showNotify(entity me)
{
	loadAllCvars(me);
}
entity makeXonoticVideoEffectsVideoSettingsTab()
{
	entity me = NEW(XonoticVideoEffectsVideoSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticVideoEffectsVideoSettingsTab_fill(entity me)
{
	entity e;
	entity videoApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0',
		"vid_width $_menu_vid_width; "
		"vid_height $_menu_vid_height; "
		"vid_pixelheight $_menu_vid_pixelheight; "
		"vid_desktopfullscreen $_menu_vid_desktopfullscreen; "
		"menu_cmd update_conwidths_before_vid_restart; "
		"vid_restart; "
		"menu_cmd sync",
		COMMANDBUTTON_APPLY);
		videoApplyButton.disableOnClick = true;

	me.gotoRC(me, 0, 1); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Video")));
	me.TR(me);
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox(0, "vid_fullscreen", _("Full screen")));
			e.applyButton = videoApplyButton;
		me.TD(me, 1, 3/2, e = makeXonoticCheckBox(0, "vid_borderless", _("Borderless window")));
			setDependent(e, "vid_fullscreen", 0, 0);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Resolution:")));
		me.TD(me, 1, 2, e = makeXonoticResolutionSlider());
			e.applyButton = videoApplyButton;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Font/UI size:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("menu_vid_scale"));
			e.addText(e, ZCTX(_("SZ^Unreadable")), -1);
			e.addText(e, ZCTX(_("SZ^Tiny")),       -0.75);
			e.addText(e, ZCTX(_("SZ^Little")),     -0.5);
			e.addText(e, ZCTX(_("SZ^Small")),      -0.25);
			e.addText(e, ZCTX(_("SZ^Medium")),      0);
			e.addText(e, ZCTX(_("SZ^Large")),       0.25);
			e.addText(e, ZCTX(_("SZ^Huge")),        0.5);
			e.addText(e, ZCTX(_("SZ^Gigantic")),    0.75);
			e.addText(e, ZCTX(_("SZ^Colossal")),    1);
			e.configureXonoticMixedSliderValues(e);
			e.applyButton = videoApplyButton;
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "gl_finish", _("Wait for GPU to finish each frame"),
			_("Make the CPU wait for the GPU to finish each frame, can help with some strange input or video lag on some machines")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBoxEx(2, 0, "r_viewfbo", _("High-quality frame buffer")));
			if (cvar_type("vid_gl20") & CVAR_TYPEFLAG_ENGINE)
				setDependent(e, "vid_samples", 0, 1);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "r_stereo_redcyan", _("Anaglyph 3D (red-cyan)")));

	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticHeaderLabel(_("Framerate")));
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Maximum:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_maxfps"));
			e.formatString = _("%s fps");
			e.addRange(e, 128, 256, 128);    // 128, 256
			e.addRange(e, 512, 1024, 512);   // 512, 1024
			e.addRange(e, 2048, 2048, 2048); // 2048
			e.addText(e, ZCTX(_("MAXFPS^Unlimited")), 0);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Target:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_minfps"));
			e.formatString = _("%s fps");
			e.addText(e, ZCTX(_("TRGT^Disabled")), 0);
			e.addRange(e, 40, 60, 20);    // 40, 60
			e.addRange(e, 100, 150, 25);  // 100, 125, 150
			e.addRange(e, 200, 250, 50);  // 200, 250
			e.addRange(e, 400, 400, 100); // 400
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Idle limit:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_maxidlefps"));
			e.formatString = _("%s fps");
			e.addRange(e, 16, 32, 16);  // 16, 32
			e.addRange(e, 64, 128, 64); // 64, 128
			e.addText(e, ZCTX(_("IDLFPS^Unlimited")), 0);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "vid_vsync", _("Vertical Synchronization"),
			_("Vsync prevents tearing, but increases latency and caps your fps at the screen refresh rate")));
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "showfps", _("Show frames per second"),
			_("Show your rendered frames per second")));

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, videoApplyButton);
}
