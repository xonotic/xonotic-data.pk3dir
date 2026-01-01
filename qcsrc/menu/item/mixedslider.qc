#include "mixedslider.qh"

	string MixedSlider_valueToText(entity me, int val)
	{
		if (val >= me.nValues || val < 0)
			return _("Custom");
		return me.(valueStrings[val]);
	}
	float MixedSlider_valueToNumberIdentifier(entity me, int val)
	{
		if (val >= me.nValues || val < 0)
			return -1; // this shouldn't occur
		return me.(valueNumberIdentifiers[val]);
	}
	void MixedSlider_setValueFromNumberIdentifier(entity me, float id, bool allowAnim)
	{
		for (int i = 0; i < me.nValues; ++i)
			if (me.valueToNumberIdentifier(me, i) == id)
			{
				SUPER(MixedSlider).setValue(me, i, allowAnim);
				return;
			}
		SUPER(MixedSlider).setValue(me, -1, allowAnim);
	}
	float MixedSlider_getNumberIdentifier(entity me)
	{
		return me.valueToNumberIdentifier(me, me.value);
	}
	string MixedSlider_rangedIdentifierToText(entity me, float id)
	{
		return formatStringSpecial(me.formatString, id, me.valueDigits);
	}
	void MixedSlider_adjustDigitsForStep(entity me, float valueStep)
	{
		float newDigits = 3;
		if (fabs(floor(valueStep * 100 + 0.5) - (valueStep * 100)) < 0.01) // about a whole number of 100ths
			newDigits = 2;
		if (fabs(floor(valueStep * 10 + 0.5) - (valueStep * 10)) < 0.01)   // about a whole number of 10ths
			newDigits = 1;
		if (fabs(floor(valueStep * 1 + 0.5) - (valueStep * 1)) < 0.01)     // about a whole number
			newDigits = 0;
		if (newDigits > me.valueDigits)
			me.valueDigits = newDigits;
	}
	void MixedSlider_clearValues(entity me)
	{
		me.nValues = 0;
	}
	void MixedSlider_addRange(entity me, float theValueMin, float theValueMax, float theValueStep)
	{
		me.adjustDigitsForStep(me, theValueStep);
		for (float id = theValueMin; id <= theValueMax + theValueStep / 2; id += theValueStep)
		{ // plus half to prevent almost all floating point errors
			me.(valueStrings[me.nValues]) = strzone(me.rangedIdentifierToText(me, id));
			me.(valueNumberIdentifiers[me.nValues]) = stof(ftos_decimals(id, me.valueDigits));
			++me.nValues;
		}
	}
	void MixedSlider_addText(entity me, string theString, float theIdentifier)
	{
		me.(valueStrings[me.nValues]) = theString;
		me.(valueNumberIdentifiers[me.nValues]) = theIdentifier;
		++me.nValues;
	}
	void MixedSlider_insertRange(entity me, int pos, float theValueMin, float theValueMax, float theValueStep)
	{
		me.adjustDigitsForStep(me, theValueStep);
		// calculate insertedCount first to prevent needing to duplicate valueStrings and valueNumberIdentifiers
		int insertedCount = ceil((theValueMax - theValueMin) / theValueStep + 0.5);
		me.nValues += insertedCount;

		for (int i = me.nValues - 1; i > pos; --i)
		{
			me.(valueStrings[i]) = me.(valueStrings[i - insertedCount]);
			me.(valueNumberIdentifiers[i]) = me.(valueNumberIdentifiers[i - insertedCount]);
		}
		for (float id = theValueMin; id <= theValueMax + theValueStep / 2; id += theValueStep)
		{
			string rounded_id_str = me.rangedIdentifierToText(me, id);
			me.(valueStrings[pos]) = strzone(rounded_id_str);
			me.(valueNumberIdentifiers[pos]) = stof(rounded_id_str);
			++pos;
		}
	}
	void MixedSlider_insertText(entity me, int pos, string theString, float theIdentifier)
	{
		++me.nValues;
		for (int i = me.nValues - 1; i > pos; --i)
		{
			me.(valueStrings[i]) = me.(valueStrings[i - 1]);
			me.(valueNumberIdentifiers[i]) = me.(valueNumberIdentifiers[i - 1]);
		}
		me.(valueStrings[pos]) = theString;
		me.(valueNumberIdentifiers[pos]) = theIdentifier;
	}
	void MixedSlider_configureMixedSliderValues(entity me, float theDefault)
	{
		me.configureSliderValues(me, 0, 0, me.nValues - 1, 1, 1, 1);
		me.setValueFromNumberIdentifier(me, theDefault, false);
	}
