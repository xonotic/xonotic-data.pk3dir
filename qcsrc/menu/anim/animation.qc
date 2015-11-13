#ifndef ANIM_ANIMATION_H
	#define ANIM_ANIMATION_H
	CLASS(Animation, Object)
		METHOD(Animation, configureAnimation, void(entity, entity, void(entity, float), float, float, float, float));
		METHOD(Animation, update, void(entity, float, float, float));
		METHOD(Animation, setTimeStartEnd, void(entity, float, float));
		METHOD(Animation, setTimeStartDuration, void(entity, float, float));
		METHOD(Animation, setValueStartEnd, void(entity, float, float));
		METHOD(Animation, setValueStartDelta, void(entity, float, float));
		METHOD(Animation, setObjectSetter, void(entity, entity, void(entity, float)));
		METHOD(Animation, tick, void(entity, float));
		METHOD(Animation, calcValue, float(entity, float, float, float, float));
		METHOD(Animation, isStopped, float(entity));
		METHOD(Animation, stopAnim, void(entity));
		METHOD(Animation, resumeAnim, void(entity));
		METHOD(Animation, isFinished, float(entity));
		METHOD(Animation, finishAnim, void(entity));
		ATTRIB(Animation, object, entity, NULL)
		void setterDummy(entity, float) {}
		ATTRIB(Animation, setter, void(entity, float), setterDummy)
		ATTRIB(Animation, value, float, 0)
		ATTRIB(Animation, startTime, float, 0)
		ATTRIB(Animation, duration, float, 0)
		ATTRIB(Animation, startValue, float, 0)
		ATTRIB(Animation, delta, float, 0)
		ATTRIB(Animation, stopped, float, false)
		ATTRIB(Animation, finished, float, false)
	ENDCLASS(Animation)
#endif

#ifdef IMPLEMENTATION
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

	METHOD(Animation, setValueStartDelta, void(entity this, float s, float d))
	{
		this.startValue = s;
		this.delta = d;
	}

	METHOD(Animation, setObjectSetter, void(entity this, entity o, void(entity, float) s))
	{
		this.object = o;
		this.setter = s;
	}

	METHOD(Animation, tick, void(entity this, float tickTime))
	{
		if (this.isStopped(this) || this.isFinished(this) || (tickTime < this.startTime)) return;

		if (tickTime >= (this.startTime + this.duration)) this.finishAnim(this);
		else this.value = this.calcValue(this, (tickTime - this.startTime), this.duration, this.startValue, this.delta);

		this.setter(this.object, this.value);
	}

	METHOD(Animation, calcValue, float(entity this, float tickTime, float animDuration, float animStartValue, float animDelta))
	{
		return animStartValue;
	}

	METHOD(Animation, isStopped, bool(entity this))
	{
		return this.stopped;
	}

	METHOD(Animation, stopAnim, void(entity this))
	{
		this.stopped = true;
	}

	METHOD(Animation, resumeAnim, void(entity this))
	{
		this.stopped = false;
	}

	METHOD(Animation, isFinished, bool(entity this))
	{
		return this.finished;
	}

	METHOD(Animation, finishAnim, void(entity this))
	{
		this.value = this.delta + this.startValue;
		this.finished = true;
		this.setter(this.object, this.value);
	}

#endif
