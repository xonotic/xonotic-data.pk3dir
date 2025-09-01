#include "animation.qh"

#include "../menu.qh"

	METHOD(Animation, configureAnimation, void(entity this, entity obj, void(entity, float) objSetter, float animStartTime, float animDuration, float animStartValue, float animEndValue))
	{
		this.setObjectSetter(this, obj, objSetter);
		this.setTimeStartDuration(this, animStartTime, animDuration);
		this.setValueStartEnd(this, animStartValue, animEndValue);
	}

	METHOD(Animation, update, void(entity this, float animDuration, float animStartValue, float animEndValue))
	{
		this.setTimeStartDuration(this, time, animDuration);
		this.setValueStartEnd(this, animStartValue, animEndValue);
	}

	METHOD(Animation, setTimeStartEnd, void(entity this, float s, float e))
	{
		this.startTime = s;
		this.duration = e - s;
	}

	METHOD(Animation, setTimeStartDuration, void(entity this, float s, float d))
	{
		this.startTime = s;
		this.duration = d;
	}

	METHOD(Animation, setValueStartEnd, void(entity this, float s, float e))
	{
		this.startValue = s;
		this.delta = e - s;
	}

	METHOD(Animation, setObjectSetter, void(entity this, entity o, void(entity, float) s))
	{
		this.object = o;
		this.setter = s;
	}

	METHOD(Animation, tick, void(entity this, float tickTime))
	{
		if (this.stopped || this.finished || (tickTime < this.startTime)) return;

		if (tickTime >= (this.startTime + this.duration)) this.finishAnim(this);
		else this.value = this.calcValue(this, (tickTime - this.startTime), this.duration, this.startValue, this.delta);

		this.setter(this.object, this.value);
	}

	METHOD(Animation, calcValue, float(entity this, float tickTime, float animDuration, float animStartValue, float animDelta))
	{
		return animStartValue;
	}

	METHOD(Animation, stopAnim, void(entity this))
	{
		this.stopped = true;
	}

	METHOD(Animation, resumeAnim, void(entity this))
	{
		this.stopped = false;
	}

	METHOD(Animation, finishAnim, void(entity this))
	{
		this.value = this.delta + this.startValue;
		this.finished = true;
		this.setter(this.object, this.value);
	}
