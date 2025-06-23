#include "slider.qh"

#include "../anim/easing.qh"
#include "../anim/animhost.qh"

string formatStringSpecial(string formatStr, float value, int decs)
{
	/* .formatString is usually in the format of "%sx" to print "2" as "2x".
	 * Special options:
	 *   "%": apply ftos_decimals_percentage
	 *   Any of "smhdwy": apply time-counting functions
	 *   Any of "SMHDWY": apply time-counting functions, allowing decimals
	 */
	if (strlen(formatStr) == 1)
		switch (formatStr)
		{
			case "%": return ftos_decimals_percentage(value, max(0, decs - 2));
			case "s": return count_seconds(value);
			case "m": return count_minutes(value);
			case "h": return count_hours(value);
			case "d": return count_days(value);
			case "w": return count_weeks(value);
			case "y": return count_years(value);
			case "S": return count_seconds_decs(value, decs);
			case "M": return count_minutes_decs(value, decs);
			case "H": return count_hours_decs(value, decs);
			case "D": return count_days_decs(value, decs);
			case "W": return count_weeks_decs(value, decs);
			case "Y": return count_years_decs(value, decs);
			default:  break;
		}
	const string txt = ftos_decimals(value, decs);
	if (formatStr != "")
		return sprintf(formatStr, txt);
	return txt;
}

.entity applyButton;

	void Slider_setValue(entity me, float val, bool allowAnim)
	{
		if (allowAnim && me.animated)
		{
			const float t = me.pressed ? autocvar_menu_animations * 0.5 : autocvar_menu_animations;
			if (!me.sliderAnim)
				me.sliderAnim = makeHostedEasing(me, Slider_setSliderValue, easingQuadOut, t, me.sliderValue, val);
			else
				me.sliderAnim.update(me.sliderAnim, t, me.sliderValue, val);
		}
		else
		{
			me.setSliderValue(me, val);
		}
		me.value = val;
	}
	void Slider_setSliderValue(entity me, float val)
	{
		me.sliderValue = val;
	}
	string Slider_toString(entity me)
	{
		return sprintf("%d (%s)", me.value, me.valueToText(me, me.value));
	}
	void Slider_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
	{
		SUPER(Slider).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
		me.controlWidth = absSize.x == 0 ? 0 : (absSize.y / absSize.x);
	}
	string Slider_valueToText(entity me, float val)
	{
		if (!almost_in_bounds(me.valueMin, val, me.valueMax))
			return "";
		val *= me.valueDisplayMultiplier;
		return formatStringSpecial(me.formatString, val, me.valueDigits);
	}
	void Slider_configureSliderVisuals(entity me, float sz, float theAlign, float theValueSpace, string gfx)
	{
		SUPER(Slider).configureLabel(me, string_null, sz, theAlign);
		me.valueSpace = bound(0, theValueSpace, 1);
		me.keepspaceLeft = 1 - me.valueSpace;
		me.src = gfx;
	}
	void Slider_configureSliderValues(entity me, float theValueMin, float theValue, float theValueMax, float theValueStep, float theValueKeyStep, float theValuePageStep)
	{
		me.value = theValue;
		me.sliderValue = theValue;
		me.valueStep = theValueStep;
		me.valueMin = theValueMin;
		me.valueMax = theValueMax;
		me.valueKeyStep = theValueKeyStep;
		me.valuePageStep = theValuePageStep;
		me.valueDigits = 3;
		if (fabs(floor(me.valueStep * 100 + 0.5) - (me.valueStep * 100)) < 0.01) // about a whole number of 100ths
			me.valueDigits = 2;
		if (fabs(floor(me.valueStep * 10 + 0.5) - (me.valueStep * 10)) < 0.01)   // about a whole number of 10ths
			me.valueDigits = 1;
		if (fabs(floor(me.valueStep * 1 + 0.5) - (me.valueStep * 1)) < 0.01)     // about a whole number
			me.valueDigits = 0;
	}
	float Slider_keyDown(entity me, float key, float ascii, float shift)
	{
		if (me.disabled) return 0;
		const float inRange = almost_in_bounds(me.valueMin, me.value, me.valueMax);
		float ret_value = 0;
		if (key == K_HOME || key == K_KP_HOME
			|| ((shift & S_CTRL) && (key == K_PGDN || key == K_KP_PGDN)))
		{
			me.setValue(me, me.valueMin, autocvar_menu_animations > 0);
			ret_value = 1;
		}
		else if (key == K_PGDN || key == K_KP_PGDN || ascii == '-'
			|| key == K_LEFTARROW || key == K_KP_LEFTARROW || key == K_MWHEELDOWN)
		{
			if (inRange) me.setValue(me, median(me.valueMin, me.value - me.valuePageStep, me.valueMax), autocvar_menu_animations > 0);
			else me.setValue(me, me.valueMax, autocvar_menu_animations > 0);
			ret_value = 1;
		}
		else if (key == K_END || key == K_KP_END
			|| ((shift & S_CTRL) && (key == K_PGUP || key == K_KP_PGUP)))
		{
			me.setValue(me, me.valueMax, autocvar_menu_animations > 0);
			ret_value = 1;
		}
		else if (key == K_PGUP || key == K_KP_PGUP || ascii == '+'
			|| key == K_RIGHTARROW || key == K_KP_RIGHTARROW || key == K_MWHEELUP)
		{
			if (inRange) me.setValue(me, median(me.valueMin, me.value + me.valuePageStep, me.valueMax), autocvar_menu_animations > 0);
			else me.setValue(me, me.valueMin, autocvar_menu_animations > 0);
			ret_value = 1;
		}
		if(ret_value == 1)
			if(me.applyButton)
				me.applyButton.disabled = false;
		// TODO more keys (NOTE also add them to Slider_keyUp)
		return ret_value;
	}
	float Slider_keyUp(entity me, float key, float ascii, float shift)
	{
		if (me.disabled) return 0;
		switch (key)
		{
			case K_LEFTARROW:
			case K_KP_LEFTARROW:
			case K_RIGHTARROW:
			case K_KP_RIGHTARROW:
			case K_PGUP:
			case K_KP_PGUP:
			case K_PGDN:
			case K_KP_PGDN:
			case K_HOME:
			case K_KP_HOME:
			case K_END:
			case K_KP_END:
				m_play_click_sound(MENU_SOUND_SLIDE);
		}
		return 0;
	}
	float Slider_mouseDrag(entity me, vector pos)
	{
		float hit;
		float v;
		if (me.disabled) return 0;

		if (me.pressed)
		{
			hit = 1;
			if (pos.x < 0 - me.tolerance.x) hit = 0;
			if (pos.y < 0 - me.tolerance.y) hit = 0;
			if (pos.x >= 1 - me.valueSpace + me.tolerance.x) hit = 0;
			if (pos.y >= 1 + me.tolerance.y) hit = 0;
			if (hit)
			{
				// handle dragging
				me.pressed = 2;

				float f = bound(0, (pos.x - me.pressOffset - 0.5 * me.controlWidth) / (1 - me.valueSpace - me.controlWidth), 1);
				v = f * (me.valueMax - me.valueMin) + me.valueMin;
				// there's no need to round min and max value... also if we did, v could be set
				// to an out of bounds value due to precision errors
				if (f > 0 && f < 1 && me.valueStep)
					v = floor(0.5 + v / me.valueStep) * me.valueStep;
				me.setValue(me, v, autocvar_menu_animations > 0);
				if(me.applyButton)
				if(me.previousValue != me.value)
					me.applyButton.disabled = false;
			}
			else
			{
				me.setValue(me, me.previousValue, autocvar_menu_animations > 0);
			}
		}

		return 1;
	}
	METHOD(Slider, mousePress, bool(Slider this, vector pos))
	{
		float controlCenter;
		if (this.disabled) return false;
		if (pos.x < 0) return false;
		if (pos.y < 0) return false;
		if (pos.x >= 1 - this.valueSpace) return false;
		if (pos.y >= 1) return false;
		controlCenter = (this.value - this.valueMin) / (this.valueMax - this.valueMin) * (1 - this.valueSpace - this.controlWidth) + 0.5 * this.controlWidth;
		if (fabs(pos.x - controlCenter) <= 0.5 * this.controlWidth)
		{
			this.pressed = 1;
			this.pressOffset = pos.x - controlCenter;
			this.previousValue = this.value;
			// this.mouseDrag(this, pos);
		}
		else
		{
			float clickValue, pageValue, inRange;
			clickValue = median(0, (pos.x - this.pressOffset - 0.5 * this.controlWidth) / (1 - this.valueSpace - this.controlWidth), 1) * (this.valueMax - this.valueMin) + this.valueMin;
			inRange = (almost_in_bounds(this.valueMin, this.value, this.valueMax));
			if (pos.x < controlCenter)
			{
				pageValue = this.value - this.valuePageStep;
				if (this.valueStep) clickValue = floor(clickValue / this.valueStep) * this.valueStep;
				pageValue = max(pageValue, clickValue);
			}
			else
			{
				pageValue = this.value + this.valuePageStep;
				if (this.valueStep) clickValue = ceil(clickValue / this.valueStep) * this.valueStep;
				pageValue = min(pageValue, clickValue);
			}
			if (inRange) this.setValue(this, median(this.valueMin, pageValue, this.valueMax), autocvar_menu_animations > 0);
			else this.setValue(this, this.valueMax, autocvar_menu_animations > 0);
			if(this.applyButton)
				this.applyButton.disabled = false;
			if (pageValue == clickValue)
			{
				controlCenter = (this.value - this.valueMin) / (this.valueMax - this.valueMin) * (1 - this.valueSpace - this.controlWidth) + 0.5 * this.controlWidth;
				this.pressed = 1;
				this.pressOffset = pos.x - controlCenter;
				this.previousValue = this.value;
				// this.mouseDrag(this, pos);
			}
		}
		return true;
	}
	float Slider_mouseRelease(entity me, vector pos)
	{
		me.pressed = 0;
		if (me.disabled) return 0;
		m_play_click_sound(MENU_SOUND_SLIDE);
		return 1;
	}
	void Slider_showNotify(entity me)
	{
		me.focusable = !me.disabled;
	}
	void Slider_draw(entity me)
	{
		float controlLeft;
		float save;
		me.focusable = !me.disabled;
		save = draw_alpha;
		if (me.disabled) draw_alpha *= me.disabledAlpha;
		draw_ButtonPicture('0 0 0', strcat(me.src, "_s"), eX * (1 - me.valueSpace) + eY, me.color2, 1);
		if (me.valueMax > me.valueMin) // valid?
		if (almost_in_bounds(me.valueMin, me.sliderValue, me.valueMax))
		{
			controlLeft = (me.sliderValue - me.valueMin) / (me.valueMax - me.valueMin) * (1 - me.valueSpace - me.controlWidth);
			if (me.disabled) draw_Picture(eX * controlLeft, strcat(me.src, "_d"), eX * me.controlWidth + eY, me.colorD, 1);
			else if (me.pressed) draw_Picture(eX * controlLeft, strcat(me.src, "_c"), eX * me.controlWidth + eY, me.colorC, 1);
			else if (me.focused) draw_Picture(eX * controlLeft, strcat(me.src, "_f"), eX * me.controlWidth + eY, me.colorF, 1);
			else draw_Picture(eX * controlLeft, strcat(me.src, "_n"), eX * me.controlWidth + eY, me.color, 1);
		}

		if (me.sliderAnim)
			if (me.sliderAnim.finished)
			{
				anim.removeObjAnim(anim, me);
				me.sliderAnim = NULL;
			}

		if (me.valueMax > me.valueMin) // valid?
			me.setText(me, me.valueToText(me, me.value));
		draw_alpha = save;
		if (me.valueSpace > 0)
		{
			SUPER(Slider).draw(me);
		}
		me.text = string_null;  // TEMPSTRING!
	}
