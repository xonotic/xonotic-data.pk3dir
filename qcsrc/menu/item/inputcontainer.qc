#include "inputcontainer.qh"

	void InputContainer_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
	{
		SUPER(InputContainer).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);
		//me.isTabRoot = !me.parent.instanceOfInputContainer;
	}

	void InputContainer_focusLeave(entity me)
	{
		SUPER(InputContainer).focusLeave(me);
		me.mouseFocusedChild = NULL;
	}

	float InputContainer_keyDown(entity me, float scan, float ascii, float shift)
	{
		entity f, ff;
		if (SUPER(InputContainer).keyDown(me, scan, ascii, shift))
			return 1;
		if (scan == K_ESCAPE)
		{
			f = me.focusedChild;
			if (f)
			{
				me.setFocus(me, NULL);
				return 1;
			}
			return 0;
		}
		if (scan == K_TAB)
		{
			f = me.focusedChild;
			if (shift & S_SHIFT)
			{
				if (f)
				{
					for (ff = f.prevSibling; ff; ff = ff.prevSibling)
					{
						if (!ff.focusable) continue;
						me.setFocus(me, ff);
						return 1;
					}
				}
				if (!f || me.isTabRoot)
				{
					for (ff = me.lastChild; ff; ff = ff.prevSibling)
					{
						if (!ff.focusable) continue;
						me.setFocus(me, ff);
						return 1;
					}
					return 0;  // AIIIIEEEEE!
				}
			}
			else
			{
				if (f)
				{
					for (ff = f.nextSibling; ff; ff = ff.nextSibling)
					{
						if (!ff.focusable) continue;
						me.setFocus(me, ff);
						return 1;
					}
				}
				if (!f || me.isTabRoot)
				{
					for (ff = me.firstChild; ff; ff = ff.nextSibling)
					{
						if (!ff.focusable) continue;
						me.setFocus(me, ff);
						return 1;
					}
					return 0;  // AIIIIEEEEE!
				}
			}
		}
		return 0;
	}

	bool InputContainer__changeFocusXY(entity this, vector pos)
	{
		entity e = this.itemFromPoint(this, pos);
		if (e && !e.focusable) e = NULL;
		entity prev = this.mouseFocusedChild;
		this.mouseFocusedChild = e;
		if (e != prev)
		{
			this.setFocus(this, e);
			if (e && e.instanceOfInputContainer)
			{
				e.focusedChild = NULL;
				e._changeFocusXY(e, globalToBox(pos, e.Container_origin, e.Container_size));
			}
		}
		return true;  // have focus
	}

	float InputContainer_mouseDrag(entity me, vector pos)
	{
		if (SUPER(InputContainer).mouseDrag(me, pos)) return 1;
		if (pos.x >= 0 && pos.y >= 0 && pos.x < 1 && pos.y < 1) return 1;
		return 0;
	}
	float InputContainer_mouseMove(entity me, vector pos)
	{
		if (me.mouseFocusedChild != me.focusedChild) // if the keyboard moved the focus away
			me.mouseFocusedChild = NULL;             // force focusing
		if (me._changeFocusXY(me, pos))
			if (SUPER(InputContainer).mouseMove(me, pos)) return 1;
		if (pos.x >= 0 && pos.y >= 0 && pos.x < 1 && pos.y < 1) return 1;
		return 0;
	}
	METHOD(InputContainer, mousePress, bool(InputContainer this, vector pos))
	{
		this.mouseFocusedChild = NULL;  // force focusing
		if (this._changeFocusXY(this, pos))
			if (SUPER(InputContainer).mousePress(this, pos)) return true;
		if (pos.x >= 0 && pos.y >= 0 && pos.x < 1 && pos.y < 1) return true;
		return false;
	}
	float InputContainer_mouseRelease(entity me, vector pos)
	{
		SUPER(InputContainer).mouseRelease(me, pos); // return value?
		if (me.focused)                              // am I still eligible for this? (UGLY HACK, but a mouse event could have changed focus away)
			if (me._changeFocusXY(me, pos)) return 1;
		if (pos.x >= 0 && pos.y >= 0 && pos.x < 1 && pos.y < 1) return 1;
		return 0;
	}
