#include "checkbox_slider_invalid.qh"

#include "slider.qh"

entity makeXonoticSliderCheckBox(float theOffValue, float isInverted, entity theControlledSlider, string theText)
{
	entity me;
	me = NEW(XonoticSliderCheckBox);
	me.configureXonoticSliderCheckBox(me, theOffValue, isInverted, theControlledSlider, theText);
	return me;
}
void XonoticSliderCheckBox_configureXonoticSliderCheckBox(entity me, float theOffValue, float isInverted, entity theControlledSlider, string theText)
{
	me.offValue = theOffValue;
	me.inverted = isInverted;
	me.checked = (theControlledSlider.value == theOffValue);
	if(theControlledSlider.value == median(theControlledSlider.valueMin, theControlledSlider.value, theControlledSlider.valueMax))
		me.savedValue = theControlledSlider.value;
	else
		me.savedValue = theControlledSlider.valueMin;
	me.controlledSlider = theControlledSlider;
	me.configureCheckBox(me, theText, me.fontSize, me.image);
	me.controlledCvar = theControlledSlider.controlledCvar; // in case we want to display the cvar in the tooltip
	me.tooltip = theControlledSlider.tooltip;
}
void XonoticSliderCheckBox_draw(entity me)
{
	me.checked = ((me.controlledSlider.value == me.offValue) != me.inverted);
	if(me.controlledSlider.value == median(me.controlledSlider.valueMin, me.controlledSlider.value, me.controlledSlider.valueMax))
		me.savedValue = me.controlledSlider.value;
	SUPER(XonoticSliderCheckBox).draw(me);
}
void XonoticSliderCheckBox_setChecked(entity me, bool val)
{
	if(me.checked == val)
		return;
	me.checked = val;
	if(val == me.inverted)
		me.controlledSlider.setValue(me.controlledSlider, median(me.controlledSlider.valueMin, me.savedValue, me.controlledSlider.valueMax), autocvar_menu_animations > 0);
	else
		me.controlledSlider.setValue(me.controlledSlider, me.offValue, autocvar_menu_animations > 0);
}
