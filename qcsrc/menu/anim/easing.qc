#include "easing.qh"

#include "../menu.qh"
#include "keyframe.qh"

	entity makeHostedEasing(entity obj, void(entity, float) objSetter, float(float, float, float, float) func, float animDuration, float animStartValue, float animEnd)
	{
		entity this = makeEasing(obj, objSetter, func, time, animDuration, animStartValue, animEnd);
		anim.addAnim(anim, this);
		return this;
	}

	entity makeEasing(entity obj, void(entity, float) objSetter, float(float, float, float, float) func, float animStartTime, float animDuration, float animStartValue, float animEnd)
	{
		entity this = NEW(Easing);
		this.configureAnimation(this, obj, objSetter, animStartTime, animDuration, animStartValue, animEnd);
		this.setMath(this, func);
		return this;
	}

	METHOD(Easing, calcValue, float(entity this, float tickTime, float animDuration, float animStart, float animDelta))
	{
		return this.math(tickTime, animDuration, animStart, animDelta);
	}

	METHOD(Easing, setMath, void(entity this, float(float, float, float, float) func))
	{
		this.math = func;
	}

	float easingLinear(float tickTime, float animDuration, float animStart, float animDelta)
	{
		return (animDelta * (tickTime / animDuration)) + animStart;
	}

	float easingQuadIn(float tickTime, float animDuration, float animStart, float animDelta)
	{
		float frac = tickTime / animDuration;
		return (animDelta * frac * frac) + animStart;
	}

	float easingQuadOut(float tickTime, float animDuration, float animStart, float animDelta)
	{
		float frac = tickTime / animDuration;
		return (-animDelta * frac * (frac - 2)) + animStart;
	}

	float easingQuadInOut(float tickTime, float animDuration, float animStart, float animDelta)
	{
		if (tickTime < (animDuration / 2)) return easingQuadIn(tickTime, (animDuration / 2), animStart, (animDelta / 2));
		else return easingQuadOut((tickTime - (animDuration / 2)), (animDuration / 2), (animStart + (animDelta / 2)), (animDelta / 2));
	}
