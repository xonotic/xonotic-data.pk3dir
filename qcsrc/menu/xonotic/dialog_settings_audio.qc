#include "dialog_settings_audio.qh"

#include "slider_decibels.qh"
#include "commandbutton.qh"
#include "textlabel.qh"
#include "checkbox.qh"
#include "radiobutton.qh"
#include "mixedslider.qh"
#include "checkbox_slider_invalid.qh"

entity makeXonoticAudioSettingsTab()
{
	entity me;
	me = NEW(XonoticAudioSettingsTab);
	me.configureDialog(me);
	return me;
}

void XonoticAudioSettingsTab_fill(entity me)
{
	entity e, e2, s;
	entity audioApplyButton = makeXonoticCommandButton(_("Apply immediately"), '0 0 0',
		"snd_restart; "
		"snd_attenuation_method_${menu_snd_attenuation_method}"
		, COMMANDBUTTON_APPLY);
	audioApplyButton.disableOnClick = true;

	me.TR(me);
		s = makeXonoticDecibelsSlider_T(-40, 0, 0.4, "mastervolume", "-");
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Master:")));
		me.TD(me, 1, 2, s);
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider_T(-40, 0, 0.4, "bgmvolume", "-");
		makeMulti(s, "snd_channel8volume");
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Music:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider_T(-40, 0, 0.4, "snd_staticvolume", "-");
		makeMulti(s, "snd_channel9volume");
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, ZCTX(_("VOL^Ambient:"))));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider_T(-40, 0, 0.4, "snd_channel0volume", "-");
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Info:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider_T(-40, 0, 0.4, "snd_channel3volume", "-");
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Items:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider_T(-40, 0, 0.4, "snd_channel6volume", "-");
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Pain:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider_T(-40, 0, 0.4, "snd_channel7volume", "-");
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Player:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider_T(-40, 0, 0.4, "snd_channel4volume", "-");
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Shots:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider_T(-40, 0, 0.4, "snd_channel2volume", "-");
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Voice:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
		me.TDempty(me, 0.2);
		s = makeXonoticDecibelsSlider_T(-40, 0, 0.4, "snd_channel1volume", "-");
		makeMulti(s, "snd_channel5volume"); // @!#%'n Tuba
		me.TD(me, 1, 0.8, e = makeXonoticTextLabel(0, _("Weapons:")));
		me.TD(me, 1, 2, s);
		setDependentStringNotEqual(e, "mastervolume", "0");
		setDependentStringNotEqual(s, "mastervolume", "0");
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox(0, "menu_snd_attenuation_method", _("New style sound attenuation")));
			e.applyButton = audioApplyButton;
	me.TR(me);
		me.TD(me, 1, 3, makeXonoticCheckBox(0, "snd_mutewhenidle", _("Mute sounds when not active")));

	me.gotoRC(me, 0, 3.2); me.setFirstColumn(me, me.currentColumn);
		me.TD(me, 1, 1, makeXonoticTextLabel(0, _("Frequency:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("snd_speed",
			_("Sound output frequency")));
			e.addText(e, _("8 kHz"), 8000);
			e.addText(e, _("11.025 kHz"), 11025);
			e.addText(e, _("16 kHz"), 16000);
			e.addText(e, _("22.05 kHz"), 22050);
			e.addText(e, _("24 kHz"), 24000);
			e.addText(e, _("32 kHz"), 32000);
			e.addText(e, _("44.1 kHz"), 44100);
			e.addText(e, _("48 kHz"), 48000);
			e.configureXonoticMixedSliderValues(e);
			e.applyButton = audioApplyButton;
	me.TR(me);
		me.TD(me, 1, 1, makeXonoticTextLabel(0, _("Channels:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("snd_channels",
			_("Number of channels for the sound output")));
			e.addText(e, _("Mono"), 1);
			e.addText(e, _("Stereo"), 2);
			e.addText(e, _("2.1"), 3);
			e.addText(e, _("4"), 4);
			e.addText(e, _("5"), 5);
			e.addText(e, _("5.1"), 6);
			e.addText(e, _("6.1"), 7);
			e.addText(e, _("7.1"), 8);
			e.configureXonoticMixedSliderValues(e);
			e.applyButton = audioApplyButton;
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "snd_swapstereo", _("Swap stereo output channels"),
			_("Swap left/right channels")));
		setDependent(e, "snd_channels", 1.5, 0.5);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "snd_spatialization_control", _("Headphone friendly mode"),
			_("Enable spatialization (blend the right and left channel slightly to decrease stereo separation a bit for headphones)")));
		setDependent(e, "snd_channels", 1.5, 0.5);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 3, e = makeXonoticCheckBox_T(0, "cl_hitsound", _("Hit indication sound"),
			_("Play a hit indicator sound when your shot hits an enemy")));
		e.sendCvars = true;
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, 1, 2.8 / 3, e = makeXonoticRadioButton_T(3, "cl_hitsound", "1", ZCTX(_("SND^Fixed")), "-"));
		e.sendCvars = true;
		setDependent(e, "cl_hitsound", 1, 3);
		me.TD(me, 1, 2.8 / 3, e = makeXonoticRadioButton_T(3, "cl_hitsound", "2", _("Decreasing"), _("Decrease pitch with more damage")));
		e.sendCvars = true;
		setDependent(e, "cl_hitsound", 1, 3);
		me.TD(me, 1, 2.8 / 3, e = makeXonoticRadioButton_T(3, "cl_hitsound", "3", _("Increasing"), _("Increase pitch with more damage")));
		e.sendCvars = true;
		setDependent(e, "cl_hitsound", 1, 3);
	me.TR(me);
		me.TD(me, 1, 3, makeXonoticCheckBox(0, "con_chatsound", _("Chat message sound")));
	me.TR(me);
		me.TD(me, 1, 1.2, e = makeXonoticCheckBox_T(0, "menu_sounds", _("Menu sounds"),
			_("Play sounds when clicking menu items")));
		me.TD(me, 1, 1.2, e.linkedCheckBox = e2 = makeXonoticCheckBoxEx_T(2, 1, "menu_sounds", _("Focus sounds"),
			_("Play sounds when hovering over menu items too")));
		setDependent(e2, "menu_sounds", 1, 2);
	me.TR(me);
	me.TR(me);
		me.TD(me, 1, 1, makeXonoticTextLabel(0, _("Time announcer:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider("cl_announcer_maptime"));
			e.addText(e, ZCTX(_("WRN^Disabled")), 0);
			e.addText(e, _("1 minute"), 1);
			e.addText(e, _("5 minutes"), 2);
			e.addText(e, ZCTX(_("WRN^Both")), 3);
			e.configureXonoticMixedSliderValues(e);
	me.TR(me);
		me.TD(me, 1, 1, makeXonoticTextLabel(0, _("Automatic taunts:")));
		me.TD(me, 1, 2, e = makeXonoticMixedSlider_T("cl_autotaunt",
			_("Automatically taunt enemies after fragging them")));
			e.addText(e, _("Never"), 0);
			e.addText(e, _("Sometimes"), 0.35);
			e.addText(e, _("Often"), 0.65);
			e.addText(e, _("Always"), 1);
			e.configureXonoticMixedSliderValues(e);
			e.sendCvars = true;

	me.gotoRC(me, me.rows - 1, 0);
		me.TD(me, 1, me.columns, audioApplyButton);
}
