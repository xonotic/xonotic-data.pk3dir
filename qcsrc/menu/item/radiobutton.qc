#include "radiobutton.qh"

	void RadioButton_configureRadioButton(entity me, string txt, float sz, string gfx, float theGroup, float doAllowDeselect)
	{
		me.configureCheckBox(me, txt, sz, gfx);
		me.align = 0;
		me.group = theGroup;
		me.allowDeselect = doAllowDeselect;
	}
	void RadioButton_Click(entity me, entity other)
	{
		if (me.checked)
		{
			if (me.allowDeselect) me.setChecked(me, false);
		}
		else
		{
			entity e;
			for (e = me.parent.firstChild; e; e = e.nextSibling)
				if (e != me)
					if (e.group == me.group) e.setChecked(e, false);
			me.setChecked(me, true);
		}
	}
