#include "slider.qh"

#include "../anim/easing.qh"
#include "../anim/animhost.qh"

.entity applyButton;

	void Slider_setValue_allowAnim(entity me, float val, bool allowAnim)
	{
		if (allowAnim && me.animated)
		{
			float t = 0.5;
			if (!me.sliderAnim) me.sliderAnim = makeHostedEasing(me, Slider_setSliderValue, easingQuadOut, t, me.sliderValue, val);
			else me.sliderAnim.update(me.sliderAnim, t, me.sliderValue, val);
		}
		else
		{
			me.setSliderValue(me, val);
		}
		me.value = val;
	}
	void Slider_setValue_noAnim(entity me, float val)
	{
		Slider_setValue_allowAnim(me, val, false);
	}
	void Slider_setValue(entity me, float val)
	{
		Slider_setValue_allowAnim(me, val, true);
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
		if (almost_in_bounds(me.valueMin, val, me.valueMax)) return ftos_decimals(val * me.valueDisplayMultiplier, me.valueDigits);
		return "";
	}
	void Slider_configureSliderVisuals(entity me, float sz, float theAlign, float theTextSpace, string gfx)
	{
		SUPER(Slider).configureLabel(me, string_null, sz, theAlign);
		me.textSpace = theTextSpace;
		me.keepspaceLeft = (theTextSpace == 0) ? 0 : (1 - theTextSpace);
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
		float inRange;
		float ret_value = 0;
		if (me.disabled) return 0;
		inRange = (almost_in_bounds(me.valueMin, me.value, me.valueMax));
		if (key == K_LEFTARROW || key == K_KP_LEFTARROW || key == K_MWHEELDOWN)
		{
			if (inRange) me.setValue(me, median(me.valueMin, me.value - me.valueKeyStep, me.valueMax));
			else me.setValue(me, me.valueMax);
			ret_value = 1;
		}
		if (key == K_RIGHTARROW || key == K_KP_RIGHTARROW || key == K_MWHEELUP)
		{
			if (inRange) me.setValue(me, median(me.valueMin, me.value + me.valueKeyStep, me.valueMax));
			else me.setValue(me, me.valueMin);
			ret_value = 1;
		}
		if (key == K_PGDN || key == K_KP_PGDN)
		{
			if (inRange) me.setValue(me, median(me.valueMin, me.value - me.valuePageStep, me.valueMax));
			else me.setValue(me, me.valueMax);
			ret_value = 1;
		}
		if (key == K_PGUP || key == K_KP_PGUP)
		{
			if (inRange) me.setValue(me, median(me.valueMin, me.value + me.valuePageStep, me.valueMax));
			else me.setValue(me, me.valueMin);
			ret_value = 1;
		}
		if (key == K_HOME || key == K_KP_HOME)
		{
			me.setValue(me, me.valueMin);
			ret_value = 1;
		}
		if (key == K_END || key == K_KP_END)
		{
			me.setValue(me, me.valueMax);
			ret_value = 1;
		}
		if(ret_value == 1)
		{
			if(me.applyButton)
				me.applyButton.disabled = false;
			return 1;
		}
		// TODO more keys (NOTE also add them to Slider_keyUp)
		return 0;
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
			if (pos.x >= 1 - me.textSpace + me.tolerance.x) hit = 0;
			if (pos.y >= 1 + me.tolerance.y) hit = 0;
			if (hit)
			{
				// handle dragging
				me.pressed = 2;

				float f = bound(0, (pos.x - me.pressOffset - 0.5 * me.controlWidth) / (1 - me.textSpace - me.controlWidth), 1);
				v = f * (me.valueMax - me.valueMin) + me.valueMin;
				// there's no need to round min and max value... also if we did, v could be set
				// to an out of bounds value due to precision errors
				if (f > 0 && f < 1 && me.valueStep)
					v = floor(0.5 + v / me.valueStep) * me.valueStep;
				me.setValue_noAnim(me, v);
				if(me.applyButton)
				if(me.previousValue != me.value)
					me.applyButton.disabled = false;
			}
			else
			{
				me.setValue(me, me.previousValue);
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
		if (pos.x >= 1 - this.textSpace) return false;
		if (pos.y >= 1) return false;
		controlCenter = (this.value - this.valueMin) / (this.valueMax - this.valueMin) * (1 - this.textSpace - this.controlWidth) + 0.5 * this.controlWidth;
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
			clickValue = median(0, (pos.x - this.pressOffset - 0.5 * this.controlWidth) / (1 - this.textSpace - this.controlWidth), 1) * (this.valueMax - this.valueMin) + this.valueMin;
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
			if (inRange) this.setValue(this, median(this.valueMin, pageValue, this.valueMax));
			else this.setValue(this, this.valueMax);
			if(this.applyButton)
				this.applyButton.disabled = false;
			if (pageValue == clickValue)
			{
				controlCenter = (this.value - this.valueMin) / (this.valueMax - this.valueMin) * (1 - this.textSpace - this.controlWidth) + 0.5 * this.controlWidth;
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
		draw_ButtonPicture('0 0 0', strcat(me.src, "_s"), eX * (1 - me.textSpace) + eY, me.color2, 1);
		if (me.valueMax > me.valueMin) // valid?
		if (almost_in_bounds(me.valueMin, me.sliderValue, me.valueMax))
		{
			controlLeft = (me.sliderValue - me.valueMin) / (me.valueMax - me.valueMin) * (1 - me.textSpace - me.controlWidth);
			if (me.disabled) draw_Picture(eX * controlLeft, strcat(me.src, "_d"), eX * me.controlWidth + eY, me.colorD, 1);
			else if (me.pressed) draw_Picture(eX * controlLeft, strcat(me.src, "_c"), eX * me.controlWidth + eY, me.colorC, 1);
			else if (me.focused) draw_Picture(eX * controlLeft, strcat(me.src, "_f"), eX * me.controlWidth + eY, me.colorF, 1);
			else draw_Picture(eX * controlLeft, strcat(me.src, "_n"), eX * me.controlWidth + eY, me.color, 1);
		}

		if (me.sliderAnim)
			if (me.sliderAnim.isFinished(me.sliderAnim))
			{
				anim.removeObjAnim(anim, me);
				me.sliderAnim = NULL;
			}

		if (me.valueMax > me.valueMin) // valid?
			me.setText(me, me.valueToText(me, me.value));
		draw_alpha = save;
		SUPER(Slider).draw(me);
		me.text = string_null;  // TEMPSTRING!
	}
