#include "magnet.qh"

#ifdef SVQC
METHOD(MagnetBuff, m_tick, void(StatusEffect this, entity actor))
{
	SUPER(MagnetBuff).m_tick(this, actor);
	if(!this.m_active(this, actor))
		return;
	if (IS_PLAYER(actor))
	{
		entity next, head = WarpZone_FindRadius(
			actor.origin + actor.view_ofs,  // line from eyes
			autocvar_g_buffs_magnet_range,
			true                            // require line of sight
		);
		for (; head; head = next)
		{
			next = head.chain; // save next entity in case head is deleted (or head.chain changed) by gettouch(head)
			if (head.itemdef // this (intentionally) doesn't include buffs -- they use .buffdef not .itemdef
			&&  gettouch(head))
				gettouch(head)(head, actor);
		}
	}

	vector vel = randomvec() * 75;
	buff_Effect(actor, EFFECT_MAGNET, CENTER_OF_ENT(actor) - vel, vel, 1, true); // needs countabsolute 1, spawning more requires calling buff_Effect repeatedly but that uses more bandwidth
}
#endif // SVQC
#ifdef MENUQC
METHOD(MagnetBuff, describe, string(MagnetBuff this))
{
	TC(MagnetBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s buff increases your item pickup range, collecting nearby items for you while the buff is active."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif // MENUQC
