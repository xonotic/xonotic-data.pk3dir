#ifdef INTERFACE
CLASS(XonoticDecibelsSlider) EXTENDS(XonoticSlider)
	METHOD(XonoticDecibelsSlider, loadCvars, void(entity))
	METHOD(XonoticDecibelsSlider, saveCvars, void(entity))
	METHOD(XonoticDecibelsSlider, valueToText, string(entity, float))
ENDCLASS(XonoticDecibelsSlider)
entity makeXonoticDecibelsSlider(float, float, float, string);
#endif

#ifdef IMPLEMENTATION

entity makeXonoticDecibelsSlider(float theValueMin, float theValueMax, float theValueStep, string theCvar)
{
	entity me;
	me = spawnXonoticDecibelsSlider();
	me.configureXonoticSlider(me, theValueMin, theValueMax, theValueStep, theCvar);
	return me;
}
void XonoticDecibelsSlider_loadCvars(entity me)
{
	float v;

	if not(me.cvarName)
		return;

	v = cvar(me.cvarName);
	if(v >= 0.98)
		Slider_setValue( me, 0 );
	else if(v < 0.0005)
		Slider_setValue( me, -1000000 );
	else
		Slider_setValue( me, 0.1 * floor(0.5 + 10.0 * log10(cvar(me.cvarName)) * 10) );
}
void XonoticDecibelsSlider_saveCvars(entity me)
{
	if not(me.cvarName)
		return;

	if(me.value >= -0.1)
		cvar_set(me.cvarName, "1");
	if(me.value < -33)
		cvar_set(me.cvarName, "0");
	else
		cvar_set(me.cvarName, ftos(pow(10, me.value / 10)));
}

string XonoticDecibelsSlider_valueToText(entity me, float v)
{
	if(v < -33)
		return "OFF";
	else if(v >= -0.1)
		return "MAX";
	return strcat(SUPER(XonoticDecibelsSlider).valueToText(me, v), " dB");
}

#endif
