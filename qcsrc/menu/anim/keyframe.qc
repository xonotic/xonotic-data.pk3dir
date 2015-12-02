#ifndef ANIM_KEYFRAME_H
	#define ANIM_KEYFRAME_H
	#include "animation.qc"
	CLASS(Keyframe, Animation)
		METHOD(Keyframe, addEasing, entity(entity, float, float, float(float, float, float, float)));
		METHOD(Keyframe, addAnim, void(entity, entity));
		METHOD(Keyframe, calcValue, float(entity, float, float, float, float));
		ATTRIB(Keyframe, currentChild, entity, NULL)
		ATTRIB(Keyframe, firstChild, entity, NULL)
		ATTRIB(Keyframe, lastChild, entity, NULL)
	ENDCLASS(Keyframe)
	entity makeHostedKeyframe(entity, void(entity, float), float, float, float);
	entity makeKeyframe(entity, void(entity, float), float, float, float);
	float getNewChildStart(entity);
	float getNewChildDuration(entity, float);
	float getNewChildValue(entity);
#endif

#ifdef IMPLEMENTATION
	entity makeHostedKeyframe(entity obj, void(entity, float) objSetter, float animDuration, float animStart, float animEnd)
	{
		entity this = makeKeyframe(obj, objSetter, animDuration, animStart, animEnd);
		anim.addAnim(anim, this);
		return this;
	}

	entity makeKeyframe(entity obj, void(entity, float) objSetter, float animDuration, float animStart, float animEnd)
	{
		entity this = NEW(Keyframe);
		this.configureAnimation(this, obj, objSetter, time, animDuration, animStart, animEnd);
		return this;
	}

	METHOD(Keyframe, addEasing, entity(entity this, float animDurationTime, float animEnd, float(float, float, float, float) func))
	{
		entity other = makeEasing(this.object, this.setter, func, getNewChildStart(this), getNewChildDuration(this, animDurationTime), getNewChildValue(this), animEnd);
		this.addAnim(this, other);
		return other;
	}

	float getNewChildStart(entity this)
	{
		if (this.lastChild) return this.lastChild.startTime + this.lastChild.duration;
		else return 0;
	}

	float getNewChildDuration(entity this, float durationTime)
	{
		float maxDura = this.duration;
		if (this.lastChild) maxDura = maxDura - (this.lastChild.startTime + this.lastChild.duration);
		float dura = durationTime;
		if (0 >= dura || dura > maxDura) dura = maxDura;
		return dura;
	}

	float getNewChildValue(entity this)
	{
		if (this.lastChild) return this.lastChild.startValue + this.lastChild.delta;
		else return this.startValue;
	}

	METHOD(Keyframe, addAnim, void(entity this, entity other))
	{
		if (other.parent) error("Can't add already added anim!");

		if (other.isFinished(other)) error("Can't add finished anim!");

		other.parent = this;

		entity l = this.lastChild;

		if (l)
		{
			l.nextSibling = other;
		}
		else
		{
			this.currentChild = other;
			this.firstChild = other;
		}

		other.prevSibling = l;
		other.nextSibling = NULL;
		this.lastChild = other;
	}

	METHOD(Keyframe, calcValue, float(entity this, float tickTime, float animDuration, float animStartValue, float animDelta))
	{
		if (this.currentChild)
			if (this.currentChild.isFinished(this.currentChild)) this.currentChild = this.currentChild.nextSibling;

		if (this.currentChild)
		{
			this.currentChild.tick(this.currentChild, tickTime);
			return this.currentChild.value;
		}

		return animStartValue + animDelta;
	}
#endif
