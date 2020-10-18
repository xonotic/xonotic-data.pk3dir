#include "item.qh"

#include "item/container.qh"
#include "item/borderimage.qh"

	METHOD(MenuItem, destroy, void(MenuItem this))
	{
		// free memory associated with this
	}

	METHOD(MenuItem, relinquishFocus, void(MenuItem this))
	{
		entity par = this.parent;
		if (!par) return;
		if (par.instanceOfContainer) par.setFocus(par, NULL);
	}

	METHOD(MenuItem, resizeNotify, void(MenuItem this, vector relOrigin, vector relSize, vector absOrigin, vector absSize))
	{
		this.origin = absOrigin;
		this.size = absSize;
	}

	int autocvar_menu_showboxes;
	METHOD(MenuItem, draw, void(MenuItem this))
	{
		if (!autocvar_menu_showboxes) return;
		vector rgb = '1 0 1';
		float a = fabs(autocvar_menu_showboxes);

		// don't draw containers and border images
		if (this.instanceOfContainer || this.instanceOfBorderImage)
		{
			rgb = '0 0 0';
			a = 0;
		}

		#if 0
			// hack to detect multi drawing
			float r = random() * 3;
			if (r >= 2) rgb = '1 0 0';
			else if (r >= 1) rgb = '0 1 0';
			else rgb = '0 0 1';
		#endif
		if (autocvar_menu_showboxes < 0)
		{
			draw_Fill('0 0 0', '0.5 0.5 0', rgb, a);
			draw_Fill('0.5 0.5 0', '0.5 0.5 0', rgb, a);
		}
		else if (autocvar_menu_showboxes > 0)
		{
			draw_Fill('0 0 0', '1 1 0', rgb, a);
		}
	}

	METHOD(MenuItem, showNotify, void(MenuItem this))
	{}

	METHOD(MenuItem, hideNotify, void(MenuItem this))
	{}

	METHOD(MenuItem, keyDown, float(MenuItem this, float scan, float ascii, float shift))
	{
		return 0;  // unhandled
	}

	METHOD(MenuItem, keyUp, float(MenuItem this, float scan, float ascii, float shift))
	{
		return 0;  // unhandled
	}

	METHOD(MenuItem, mouseMove, float(MenuItem this, vector pos))
	{
		return 0;  // unhandled
	}

	METHOD(MenuItem, mousePress, bool(MenuItem this, vector pos))
	{
		return false;  // unhandled
	}

	METHOD(MenuItem, mouseDrag, float(MenuItem this, vector pos))
	{
		return 0;  // unhandled
	}

	METHOD(MenuItem, mouseRelease, float(MenuItem this, vector pos))
	{
		return 0;  // unhandled
	}

    void m_play_focus_sound();

	METHOD(MenuItem, focusEnter, void(MenuItem this))
	{
		if (this.allowFocusSound) m_play_focus_sound();
	}

	METHOD(MenuItem, focusLeave, void(MenuItem this))
	{}

	METHOD(MenuItem, toString, string(MenuItem this))
	{
		return string_null;
	}
