#include "button.qh"

	void Button_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
	{
		if (me.srcMulti) me.keepspaceLeft = 0;
		else me.keepspaceLeft = min(0.8, absSize.x == 0 ? 0 : (absSize.y / absSize.x));
		SUPER(Button).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

		if(me.disableOnClick)
			me.disabled = true; // initially disabled
	}
	void Button_configureButton(entity me, string txt, float sz, string gfx)
	{
		SUPER(Button).configureLabel(me, txt, sz, me.srcMulti ? 0.5 : 0);
		me.src = gfx;
	}
	float Button_keyDown(entity me, float key, float ascii, float shift)
	{
		if (key == K_ENTER || key == K_SPACE || key == K_KP_ENTER)
		{
			if(!me.disabled)
			{
				me.playClickSound(me);
				me.clickTime = 0.1;  // delayed for effect
			}
			return 1;
		}
		return 0;
	}
	float Button_mouseDrag(entity me, vector pos)
	{
		me.pressed = 1;
		if (pos.x < 0) me.pressed = 0;
		if (pos.y < 0) me.pressed = 0;
		if (pos.x >= 1) me.pressed = 0;
		if (pos.y >= 1) me.pressed = 0;
		return 1;
	}
	METHOD(Button, mousePress, bool(Button this, vector pos))
	{
		this.mouseDrag(this, pos);  // verify coordinates
		return true;
	}
	float Button_mouseRelease(entity me, vector pos)
	{
		me.mouseDrag(me, pos);  // verify coordinates
		if (me.pressed)
		{
			if (!me.disabled)
			{
				me.playClickSound(me);
				if (me.onClick)
				{
					if(me.applyButton)
						me.applyButton.disabled = false;
					me.onClick(me, me.onClickEntity);
					if(me.disableOnClick)
						me.disabled = true;
				}
			}
			me.pressed = 0;
		}
		return 1;
	}
	void Button_showNotify(entity me)
	{
		me.focusable = !me.disabled;
	}
	void Button_draw(entity me)
	{
		vector bOrigin, bSize;
		float save;

		me.focusable = !me.disabled;

		save = draw_alpha;
		if (me.disabled) draw_alpha *= me.disabledAlpha;

		if (me.src)
		{
			if (me.srcMulti)
			{
				bOrigin = '0 0 0';
				bSize = '1 1 0';
				if (me.disabled)
					draw_ButtonPicture(bOrigin, strcat(me.src, "_d", me.srcSuffix), bSize, me.colorD, 1);
				else if (me.forcePressed || me.pressed || me.clickTime > 0)
					draw_ButtonPicture(bOrigin, strcat(me.src, "_c", me.srcSuffix), bSize, me.colorC, 1);
				else if (me.focused)
					draw_ButtonPicture(bOrigin, strcat(me.src, "_f", me.srcSuffix), bSize, me.colorF, 1);
				else if (me.pulse)
				{
					float alpha = min(1, 1 + sin(1.2*M_PI * time));
					draw_ButtonPicture(bOrigin, strcat(me.src, "_f", me.srcSuffix), bSize, me.colorF, 1 - alpha);
					draw_ButtonPicture(bOrigin, strcat(me.src, "_n", me.srcSuffix), bSize, me.color, alpha);
				}
				else
					draw_ButtonPicture(bOrigin, strcat(me.src, "_n", me.srcSuffix), bSize, me.color,  1);
			}
			else
			{
				if (me.realFontSize_y == 0)
				{
					bOrigin = '0 0 0';
					bSize = '1 1 0';
				}
				else
				{
					bOrigin = eY * (0.5 * (1 - me.realFontSize.y)) + eX * (0.5 * (me.keepspaceLeft - me.realFontSize.x));
					bSize = me.realFontSize;
				}
				if (me.disabled)
					draw_Picture(bOrigin, strcat(me.src, "_d", me.srcSuffix), bSize, me.colorD, 1);
				else if (me.forcePressed || me.pressed || me.clickTime > 0)
					draw_Picture(bOrigin, strcat(me.src, "_c", me.srcSuffix), bSize, me.colorC, 1);
				else if (me.focused)
					draw_Picture(bOrigin, strcat(me.src, "_f", me.srcSuffix), bSize, me.colorF, 1);
				else if (me.pulse)
				{
					float alpha = min(1, 1 + sin(1.2*M_PI * time));
					draw_ButtonPicture(bOrigin, strcat(me.src, "_f", me.srcSuffix), bSize, me.colorF, 1 - alpha);
					draw_ButtonPicture(bOrigin, strcat(me.src, "_n", me.srcSuffix), bSize, me.color, alpha);
				}
				else
					draw_Picture(bOrigin, strcat(me.src, "_n", me.srcSuffix), bSize, me.color,  1);
			}
		}
		if (me.src2)
		{
			bOrigin = me.keepspaceLeft * eX;
			bSize = eY + eX * (1 - me.keepspaceLeft);

			bOrigin += bSize * (0.5 - 0.5 * me.src2scale);
			bSize = bSize * me.src2scale;

			draw_Picture(bOrigin, me.src2, bSize, me.color2, me.alpha2);
		}

		draw_alpha = save;

		if (me.clickTime > 0 && me.clickTime <= frametime)
		{
			// keyboard click timer expired? Fire the event then.
			if (!me.disabled && me.onClick)
			{
				if(me.applyButton)
					me.applyButton.disabled = false;
				me.onClick(me, me.onClickEntity);
				if(me.disableOnClick)
					me.disabled = true;
			}
		}
		me.clickTime -= frametime;

		SUPER(Button).draw(me);
	}
	void Dialog_Close(entity button, entity me);
	void Button_playClickSound(entity me)
	{
		if (me.onClick == DialogOpenButton_Click) m_play_click_sound(MENU_SOUND_OPEN);
		else if (me.onClick == Dialog_Close) m_play_click_sound(MENU_SOUND_CLOSE);
		else m_play_click_sound(MENU_SOUND_EXECUTE);
	}
