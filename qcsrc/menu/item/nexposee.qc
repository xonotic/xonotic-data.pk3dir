#include "nexposee.qh"

	void Nexposee_close(entity me)
	{
		// user must override this
	}

	void ExposeeCloseButton_Click(entity button, entity other)
	{
		other.selectedChild = other.focusedChild;
		other.setFocus(other, NULL);
		other.animationState = 3;
	}

	void Nexposee_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
	{
		me.calc(me);
		me.resizeNotifyLie(me, relOrigin, relSize, absOrigin, absSize, Nexposee_initialOrigin, Nexposee_initialSize, Nexposee_initialFontScale);
	}

	void Nexposee_Calc_Scale(entity me, float scale)
	{
		entity e;
		for (e = me.firstChild; e; e = e.nextSibling)
		{
			e.Nexposee_smallOrigin = (e.Nexposee_initialOrigin - e.Nexposee_scaleCenter) * scale + e.Nexposee_scaleCenter;
			e.Nexposee_smallSize = e.Nexposee_initialSize * scale;
			if (e.Nexposee_align.x > 0) e.Nexposee_smallOrigin_x = 1 - e.Nexposee_align.x * scale;
			if (e.Nexposee_align.x < 0) e.Nexposee_smallOrigin_x = -e.Nexposee_smallSize.x + e.Nexposee_align.x * scale;
			if (e.Nexposee_align.y > 0) e.Nexposee_smallOrigin_y = 1 - e.Nexposee_align.y * scale;
			if (e.Nexposee_align.y < 0) e.Nexposee_smallOrigin_y = -e.Nexposee_smallSize.y + e.Nexposee_align.y * scale;
		}
	}

	void Nexposee_calc(entity me)
	{
		/*
		 * patented by Apple
		 * can't put that here ;)
		 */
		float scale;
		entity e, e2;
		vector emins, emaxs, e2mins, e2maxs;

		for (scale = 0.7; ; scale *= 0.99)
		{
			Nexposee_Calc_Scale(me, scale);

			for (e = me.firstChild; e; e = e.nextSibling)
			{
				emins = e.Nexposee_smallOrigin;
				emaxs = emins + e.Nexposee_smallSize;
				for (e2 = e.nextSibling; e2; e2 = e2.nextSibling)
				{
					e2mins = e2.Nexposee_smallOrigin;
					e2maxs = e2mins + e2.Nexposee_smallSize;

					// two intervals [amins, amaxs] and [bmins, bmaxs] overlap if:
					//   amins < bmins < amaxs < bmaxs
					// for which suffices
					//   bmins < amaxs
					//   amins < bmaxs
					if ((e2mins.x - emaxs.x) * (emins.x - e2maxs.x) > 0)     // x overlap
						if ((e2mins.y - emaxs.y) * (emins.y - e2maxs.y) > 0) // y overlap
							goto have_overlap;
				}
			}

			break;
LABEL(have_overlap)
		}

		scale *= 0.95;

		Nexposee_Calc_Scale(me, scale);
	}

	void Nexposee_setNexposee(entity me, entity other, vector scalecenter, float a0, float a1)
	{
		other.Nexposee_scaleCenter = scalecenter;
		other.Nexposee_smallAlpha = a0;
		me.setAlphaOf(me, other, a0);
		other.Nexposee_mediumAlpha = a1;
	}

	void Nexposee_draw(entity me)
	{
		float a;
		float a0;
		entity e;
		float f;
		vector fs;

		if (me.animationState == -1) me.animationState = 0;

		f = min(1, frametime * 5);
		switch (me.animationState)
		{
			case 0:
				me.animationFactor = 0;
				break;
			case 1:
				me.animationFactor += f;
				if (me.animationFactor >= 1)
				{
					me.animationFactor = 1;
					me.animationState = 2;
					SUPER(Nexposee).setFocus(me, me.selectedChild);
				}
				break;
			case 2:
				me.animationFactor = 1;
				break;
			case 3:
				me.animationFactor -= f;
				me.mouseFocusedChild = me.itemFromPoint(me, me.mousePosition);
				if (me.animationFactor <= 0)
				{
					me.animationFactor = 0;
					me.animationState = 0;
					me.selectedChild = me.mouseFocusedChild;
				}
				break;
		}

		f = min(1, frametime * 10);
		for (e = me.firstChild; e; e = e.nextSibling)
		{
			if (e == me.selectedChild)
			{
				e.Container_origin = e.Nexposee_smallOrigin * (1 - me.animationFactor) + e.Nexposee_initialOrigin * me.animationFactor;
				e.Container_size = e.Nexposee_smallSize * (1 - me.animationFactor) + e.Nexposee_initialSize * me.animationFactor;
				e.Nexposee_animationFactor = me.animationFactor;
				a0 = e.Nexposee_mediumAlpha;
				if (me.animationState == 3)
					if (e != me.mouseFocusedChild) a0 = e.Nexposee_smallAlpha;
				a = a0 * (1 - me.animationFactor) + me.animationFactor;
			}
			else
			{
				// minimum theSize counts
				e.Container_origin = e.Nexposee_smallOrigin;
				e.Container_size = e.Nexposee_smallSize;
				e.Nexposee_animationFactor = 0;
				a = e.Nexposee_smallAlpha * (1 - me.animationFactor);
			}
			me.setAlphaOf(me, e, e.Container_alpha * (1 - f) + a * f);

			fs = globalToBoxSize(e.Container_size, e.Nexposee_initialSize);
			e.Container_fontscale_x = fs.x * e.Nexposee_initialFontScale.x;
			e.Container_fontscale_y = fs.y * e.Nexposee_initialFontScale.y;
		}

		SUPER(Nexposee).draw(me);
	}

	METHOD(Nexposee, mousePress, bool(Nexposee this, vector pos))
	{
		if (this.animationState == 0)
		{
			this.mouseFocusedChild = NULL;
			Nexposee_mouseMove(this, pos);
			if (this.mouseFocusedChild)
			{
				m_play_click_sound(MENU_SOUND_OPEN);
				this.animationState = 1;
				SUPER(Nexposee).setFocus(this, NULL);
			}
			else
			{
				this.close(this);
			}
			return true;
		}
		else if (this.animationState == 2)
		{
			if (!(SUPER(Nexposee).mousePress(this, pos)))
			{
				m_play_click_sound(MENU_SOUND_CLOSE);
				this.animationState = 3;
				SUPER(Nexposee).setFocus(this, NULL);
			}
			return true;
		}
		return false;
	}

	float Nexposee_mouseRelease(entity me, vector pos)
	{
		if (me.animationState == 2) return SUPER(Nexposee).mouseRelease(me, pos);
		return 0;
	}

	float Nexposee_mouseDrag(entity me, vector pos)
	{
		if (me.animationState == 2) return SUPER(Nexposee).mouseDrag(me, pos);
		return 0;
	}

	float Nexposee_mouseMove(entity me, vector pos)
	{
		entity e;
		me.mousePosition = pos;
		e = me.mouseFocusedChild;
		me.mouseFocusedChild = me.itemFromPoint(me, pos);
		if (me.animationState == 2) return SUPER(Nexposee).mouseMove(me, pos);
		if (me.animationState == 0)
		{
			if (me.mouseFocusedChild)
				if (me.mouseFocusedChild != e || me.mouseFocusedChild != me.selectedChild) me.selectedChild = me.mouseFocusedChild;
			return 1;
		}
		return 0;
	}

	float Nexposee_keyUp(entity me, float scan, float ascii, float shift)
	{
		if (me.animationState == 2) return SUPER(Nexposee).keyUp(me, scan, ascii, shift);
		return 0;
	}

	float Nexposee_keyDown(entity me, float scan, float ascii, float shift)
	{
		float nexposeeKey = 0;
		if (me.animationState == 2)
			if (SUPER(Nexposee).keyDown(me, scan, ascii, shift)) return 1;
		if (scan == K_TAB)
		{
			if (me.animationState == 0)
			{
				if (shift & S_SHIFT)
				{
					if (me.selectedChild) me.selectedChild = me.selectedChild.prevSibling;
					if (!me.selectedChild) me.selectedChild = me.lastChild;
				}
				else
				{
					if (me.selectedChild) me.selectedChild = me.selectedChild.nextSibling;
					if (!me.selectedChild) me.selectedChild = me.firstChild;
				}
			}
		}
		switch (me.animationState)
		{
			default:
			case 0:
			case 3:
				nexposeeKey = ((scan == K_SPACE) || (scan == K_ENTER) || (scan == K_KP_ENTER));
				break;
			case 1:
			case 2:
				nexposeeKey = (scan == K_ESCAPE);
				break;
		}
		if (nexposeeKey)
		{
			switch (me.animationState)
			{
				default:
				case 0:
				case 3:
					m_play_click_sound(MENU_SOUND_OPEN);
					me.animationState = 1;
					break;
				case 1:
				case 2:
					m_play_click_sound(MENU_SOUND_CLOSE);
					me.animationState = 3;
					break;
			}
			if (me.focusedChild) me.selectedChild = me.focusedChild;
			if (!me.selectedChild) me.animationState = 0;
			SUPER(Nexposee).setFocus(me, NULL);
			return 1;
		}
		return 0;
	}

	void Nexposee_addItem(entity me, entity other, vector theOrigin, vector theSize, float theAlpha)
	{
		SUPER(Nexposee).addItem(me, other, theOrigin, theSize, theAlpha);
		other.Nexposee_initialFontScale = other.Container_fontscale;
		other.Nexposee_initialSize = other.Container_size;
		other.Nexposee_initialOrigin = other.Container_origin;
		other.Nexposee_initialAlpha = other.Container_alpha;
		if (other.Nexposee_initialFontScale == '0 0 0') other.Nexposee_initialFontScale = '1 1 0';
	}

	void Nexposee_focusEnter(entity me)
	{
		if (me.animationState == 2) SUPER(Nexposee).setFocus(me, me.selectedChild);
	}

	void Nexposee_pullNexposee(entity me, entity other, vector theAlign)
	{
		other.Nexposee_align = theAlign;
	}
