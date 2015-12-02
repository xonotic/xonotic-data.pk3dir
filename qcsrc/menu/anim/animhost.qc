#include "../menu.qh"

#ifndef ANIM_ANIMHOST_H
	#define ANIM_ANIMHOST_H
	CLASS(AnimHost, Object)
		METHOD(AnimHost, addAnim, void(entity, entity));
		METHOD(AnimHost, removeAnim, void(entity, entity));
		METHOD(AnimHost, removeAllAnim, void(entity));
		METHOD(AnimHost, removeObjAnim, void(entity, entity));
		METHOD(AnimHost, stopAllAnim, void(entity));
		METHOD(AnimHost, stopObjAnim, void(entity, entity));
		METHOD(AnimHost, resumeAllAnim, void(entity));
		METHOD(AnimHost, resumeObjAnim, void(entity, entity));
		METHOD(AnimHost, finishAllAnim, void(entity));
		METHOD(AnimHost, finishObjAnim, void(entity, entity));
		METHOD(AnimHost, tickAll, void(entity));
		ATTRIB(AnimHost, firstChild, entity, NULL)
		ATTRIB(AnimHost, lastChild, entity, NULL)
	ENDCLASS(AnimHost)
	.entity nextSibling;
	.entity prevSibling;
#endif

#ifdef IMPLEMENTATION
	METHOD(AnimHost, addAnim, void(entity this, entity other))
	{
		if (other.parent) error("Can't add already added anim!");

		if (other.isFinished(other)) error("Can't add finished anim!");

		other.parent = this;

		entity l = this.lastChild;

		if (l) l.nextSibling = other;
		else this.firstChild = other;

		other.prevSibling = l;
		other.nextSibling = NULL;
		this.lastChild = other;
	}

	METHOD(AnimHost, removeAnim, void(entity this, entity other))
	{
		if (other.parent != this) error("Can't remove from wrong AnimHost!");

		other.parent = NULL;

		entity n = other.nextSibling;
		entity p = other.prevSibling;

		if (p) p.nextSibling = n;
		else this.firstChild = n;

		if (n) n.prevSibling = p;
		else this.lastChild = p;
		remove(other);
	}

	METHOD(AnimHost, removeAllAnim, void(entity this))
	{
		for (entity e = this.firstChild; e; e = e.nextSibling)
		{
			entity tmp = e;
			e = tmp.prevSibling;
			this.removeAnim(this, tmp);
		}
	}

	METHOD(AnimHost, removeObjAnim, void(entity this, entity obj))
	{
		for (entity e = this.firstChild; e; e = e.nextSibling)
		{
			if (e.object == obj)
			{
				entity tmp = e;
				e = tmp.prevSibling;
				this.removeAnim(this, tmp);
			}
		}
	}

	METHOD(AnimHost, stopAllAnim, void(entity this))
	{
		for (entity e = this.firstChild; e; e = e.nextSibling)
			e.stopAnim(e);
	}

	METHOD(AnimHost, stopObjAnim, void(entity this, entity obj))
	{
		for (entity e = this.firstChild; e; e = e.nextSibling)
			if (e.object == obj) e.stopAnim(e);
	}

	METHOD(AnimHost, resumeAllAnim, void(entity this))
	{
		for (entity e = this.firstChild; e; e = e.nextSibling)
			e.resumeAnim(e);
	}

	METHOD(AnimHost, resumeObjAnim, void(entity this, entity obj))
	{
		for (entity e = this.firstChild; e; e = e.nextSibling)
			if (e.object == obj) e.resumeAnim(e);
	}

	METHOD(AnimHost, finishAllAnim, void(entity this))
	{
		for (entity e = this.firstChild; e; e = e.nextSibling)
		{
			entity tmp = e;
			e = tmp.prevSibling;
			tmp.finishAnim(tmp);
		}
	}

	METHOD(AnimHost, finishObjAnim, void(entity this, entity obj))
	{
		for (entity e = this.firstChild; e; e = e.nextSibling)
		{
			if (e.object == obj)
			{
				entity tmp = e;
				e = tmp.prevSibling;
				tmp.finishAnim(tmp);
			}
		}
	}

	METHOD(AnimHost, tickAll, void(entity this))
	{
		for (entity e = this.firstChild; e; e = e.nextSibling)
		{
			e.tick(e, time);
			if (e.isFinished(e))
			{
				entity tmp = e;
				e = tmp.prevSibling;
				this.removeAnim(this, tmp);
			}
		}
	}
#endif
