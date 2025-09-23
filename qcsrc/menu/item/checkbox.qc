#include "checkbox.qh"

	void CheckBox_setChecked(entity me, bool val)
	{
		me.checked = val;
	}
	void CheckBox_Click(entity me, entity other)
	{
		me.setChecked(me, !me.checked);
	}
	string CheckBox_toString(entity me)
	{
		return strcat(SUPER(CheckBox).toString(me), ", ", me.checked ? "checked" : "unchecked");
	}
	void CheckBox_configureCheckBox(entity me, string txt, float sz, string gfx)
	{
		me.configureButton(me, txt, sz, gfx);
		me.align = 0;
	}
	void CheckBox_draw(entity me)
	{
		float s;
		s = me.pressed;
		if (me.useDownAsChecked)
		{
			me.srcSuffix = string_null;
			me.forcePressed = me.checked;
		}
		else
		{
			me.srcSuffix = (me.checked ? "1" : "0");
		}
		me.pressed = s;
		SUPER(CheckBox).draw(me);
	}
	void CheckBox_playClickSound(entity me)
	{
		m_play_click_sound(MENU_SOUND_SELECT);
	}
