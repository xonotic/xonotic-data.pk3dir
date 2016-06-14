#include "item.qh"

#include "item/container.qh"
#include "item/borderimage.qh"

	METHOD(Item, destroy, void(Item this))
	{
		// free memory associated with this
	}

	METHOD(Item, relinquishFocus, void(Item this))
	{
		entity par = this.parent;
		if (!par) return;
		if (par.instanceOfContainer) par.setFocus(par, NULL);
	}

	METHOD(Item, resizeNotify, void(Item this, vector relOrigin, vector relSize, vector absOrigin, vector absSize))
	{
		this.origin = absOrigin;
		this.size = absSize;
	}

	int autocvar_menu_showboxes;
	METHOD(Item, draw, void(Item this))
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

	METHOD(Item, showNotify, void(Item this))
	{}

	METHOD(Item, hideNotify, void(Item this))
	{}

	METHOD(Item, keyDown, float(Item this, float scan, float ascii, float shift))
	{
		return 0;  // unhandled
	}

	METHOD(Item, keyUp, float(Item this, float scan, float ascii, float shift))
	{
		return 0;  // unhandled
	}

	METHOD(Item, mouseMove, float(Item this, vector pos))
	{
		return 0;  // unhandled
	}

	METHOD(Item, mousePress, float(Item this, vector pos))
	{
		return 0;  // unhandled
	}

	METHOD(Item, mouseDrag, float(Item this, vector pos))
	{
		return 0;  // unhandled
	}

	METHOD(Item, mouseRelease, float(Item this, vector pos))
	{
		return 0;  // unhandled
	}

    void m_play_focus_sound();

	METHOD(Item, focusEnter, void(Item this))
	{
		if (this.allowFocusSound) m_play_focus_sound();
	}

	METHOD(Item, focusLeave, void(Item this))
	{}

	METHOD(Item, toString, string(Item this))
	{
		return string_null;
	}
