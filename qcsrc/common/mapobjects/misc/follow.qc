#include "follow.qh"
// the way this entity works makes it no use to CSQC, as it removes itself instantly

#ifdef SVQC
void follow_init(entity this)
{
	entity src, dst;
	src = NULL;
	dst = NULL;
	if(this.killtarget != "")
		src = find(NULL, targetname, this.killtarget);
	if(this.target != "")
		dst = find(NULL, targetname, this.target);

	if(!src && !dst)
	{
		objerror(this, "follow: could not find target/killtarget");
		return;
	}

	if(this.jointtype)
	{
		// already done :P entity must stay
		this.aiment = src;
		this.enemy = dst;
	}
	else if(!src || !dst)
	{
		objerror(this, "follow: could not find target/killtarget");
		return;
	}
	else if(this.spawnflags & FOLLOW_ATTACH)
	{
		// attach
		if(this.spawnflags & FOLLOW_LOCAL)
		{
			setattachment(dst, src, this.message);
		}
		else
		{
			attach_sameorigin(dst, src, this.message);
		}

		dst.solid = SOLID_NOT; // solid doesn't work with attachment
		delete(this);
	}
	else
	{
		if(this.spawnflags & FOLLOW_LOCAL)
		{
			set_movetype(dst, MOVETYPE_FOLLOW);
			dst.aiment = src;
			// dst.punchangle = '0 0 0'; // keep unchanged
			dst.view_ofs = dst.origin;
			dst.v_angle = dst.angles;
		}
		else
		{
			follow_sameorigin(dst, src);
		}

		delete(this);
	}
}

spawnfunc(misc_follow)
{
	InitializeEntity(this, follow_init, INITPRIO_FINDTARGET);
}
#endif
