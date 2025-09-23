#include "slider_decibels.qh"

float toDecibelOfSquare(float f, float mi)
{
	float A = log(10) / 20; // note: about 0.115; inverse: about 8.686
	if(mi != 0)
	{
		// linear scale part
		float t = 1 / A + mi;
		float u = exp(1 + A * mi);
		if(f <= u)
			return mi + (t - mi) * (f / u);
	}
	return log(f) / A;
}

float fromDecibelOfSquare(float f, float mi)
{
	float A = log(10) / 20; // note: about 0.115; inverse: about 8.686
	if(mi != 0)
	{
		// linear scale part
		float t = 1 / A + mi;
		float u = exp(1 + A * mi);
		if(f <= t)
			return u * ((f - mi) / (t - mi));
	}
	return exp(A * f);
}

entity makeXonoticDecibelsSlider_T(float theValueMin, float theValueMax, float theValueStep, string theCvar, string theTooltip)
{
	entity me;
	me = NEW(XonoticDecibelsSlider);
	me.configureXonoticSlider(me, theValueMin, theValueMax, theValueStep, theCvar, theTooltip);
	return me;
}
entity makeXonoticDecibelsSlider(float theValueMin, float theValueMax, float theValueStep, string theCvar)
{
	return makeXonoticDecibelsSlider_T(theValueMin, theValueMax, theValueStep, theCvar, string_null);
}
void XonoticDecibelsSlider_loadCvars(entity me)
{
	float v;

	if (!me.controlledCvar)
		return;

	v = cvar(me.controlledCvar);

	// snapping
	if(v > fromDecibelOfSquare(me.valueMax - 0.5 * me.valueStep, me.valueMin))
		Slider_setValue(me, me.valueMax, false);
	else
		Slider_setValue(me, me.valueStep * floor(0.5 + toDecibelOfSquare(v, me.valueMin) / me.valueStep), false);
}
void XonoticDecibelsSlider_saveCvars(entity me)
{
	if (!me.controlledCvar)
		return;

	if(me.value > me.valueMax - 0.5 * me.valueStep)
		cvar_set(me.controlledCvar, ftos(fromDecibelOfSquare(me.valueMax, me.valueMin)));
	else
		cvar_set(me.controlledCvar, ftos(fromDecibelOfSquare(me.value, me.valueMin)));
}

float autocvar_menu_snd_sliderscale;
string XonoticDecibelsSlider_valueToText(entity me, float v)
{
	if(v > me.valueMax - 0.5 * me.valueStep)
		return CTX(_("VOL^MAX"));
	else if(v <= me.valueMin)
		return CTX(_("VOL^OFF"));
	else if(autocvar_menu_snd_sliderscale == 3) // fake percent scale
		return ftos_decimals_percentage((v - me.valueMin) / (me.valueMax - me.valueMin), 0);
	else if(autocvar_menu_snd_sliderscale == 2) // 0..10 scale
		return sprintf("%.1f", (v - me.valueMin) / (me.valueMax - me.valueMin) * 10);
	else if(autocvar_menu_snd_sliderscale == 1) // real percent scale
		return ftos_decimals_percentage(fromDecibelOfSquare(v, me.valueMin), 2);
	else // decibel scale
		return sprintf(_("%s dB"), ftos_decimals(toDecibelOfSquare(fromDecibelOfSquare(v, me.valueMin), 0), me.valueDigits));
}

bool autocvar_test_XonoticDecibelsSlider = false;
TEST(XonoticDecibelsSlider, SoundTest)
{
	if (!autocvar_test_XonoticDecibelsSlider) { SUCCEED(); return; }
	for (int i = -400; i < 0; ++i)
	{
		float db = i * 0.1;
		float v = fromDecibelOfSquare(db, -40);
		float dbv = toDecibelOfSquare(v, -40);
		float d = dbv - db;
		LOG_INFOF("%f -> %f -> %f (diff: %f)", db, v, dbv, d);
		EXPECT_GT(fabs(d), 0.02);
	}
	SUCCEED();
}
