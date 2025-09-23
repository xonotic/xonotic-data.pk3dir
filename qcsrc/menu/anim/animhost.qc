#include "animhost.qh"

#include "../menu.qh"

#include "animation.qh"

    .entity parent;
	METHOD(AnimHost, addAnim, void(entity this, entity other))
	{
		if (other.parent) error("Can't add already added anim!");
		if (other.finished) error("Can't add finished anim!");

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
		delete(other);
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
			if (e.finished)
			{
				entity tmp = e;
				e = tmp.prevSibling;
				this.removeAnim(this, tmp);
			}
		}
	}
