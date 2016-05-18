#include "textslider.qh"

	string TextSlider_valueToIdentifier(entity me, int val)
	{
		if (val >= me.nValues) return "custom";
		if (val < 0) return "custom";
		return me.(valueIdentifiers[val]);
	}
	string TextSlider_valueToText(entity me, int val)
	{
		if (val >= me.nValues) return _("Custom");
		if (val < 0) return _("Custom");
		return me.(valueStrings[val]);
	}
	void TextSlider_setValueFromIdentifier_allowAnim(entity me, string id, bool allowAnim)
	{
		int i;
		for (i = 0; i < me.nValues; ++i)
			if (me.valueToIdentifier(me, i) == id)
			{
				SUPER(TextSlider).setValue_allowAnim(me, i, allowAnim);
				return;
			}
		SUPER(TextSlider).setValue_allowAnim(me, -1, allowAnim);
	}
	void TextSlider_setValueFromIdentifier_noAnim(entity me, string id)
	{
		TextSlider_setValueFromIdentifier_allowAnim(me, id, false);
	}
	void TextSlider_setValueFromIdentifier(entity me, string id)
	{
		TextSlider_setValueFromIdentifier_allowAnim(me, id, true);
	}
	string TextSlider_getIdentifier(entity me)
	{
		return me.valueToIdentifier(me, me.value);
	}
	void TextSlider_clearValues(entity me)
	{
		me.nValues = 0;
	}
	void TextSlider_addValue(entity me, string theString, string theIdentifier)
	{
		me.(valueStrings[me.nValues]) = theString;
		me.(valueIdentifiers[me.nValues]) = theIdentifier;
		me.nValues += 1;
	}
	void TextSlider_insertValue(entity me, int pos, string theString, string theIdentifier)
	{
		int i;
		for (i = me.nValues; i > pos; --i)
		{
			me.(valueStrings[i]) = me.(valueStrings[i - 1]);
			me.(valueIdentifiers[i]) = me.(valueIdentifiers[i - 1]);
		}
		me.(valueStrings[pos]) = theString;
		me.(valueIdentifiers[pos]) = theIdentifier;
		me.nValues += 1;
	}
	void TextSlider_configureTextSliderValues(entity me, string theDefault)
	{
		me.configureSliderValues(me, 0, 0, me.nValues - 1, 1, 1, 1);
		me.setValueFromIdentifier_noAnim(me, theDefault);
	}
