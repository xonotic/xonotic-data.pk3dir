#include "magnet.qh"

#ifdef SVQC
bool buff_Magnet_cond(entity e)
{
	return (e.itemdef // this (intentionally) doesn't include buffs -- they use .buffdef not .itemdef
		&& gettouch(e));
}
METHOD(MagnetBuff, m_tick, void(StatusEffect this, entity actor))
{
	if (IS_PLAYER(actor))
	{
		entity next, head = WarpZone_SearchInRadius(
			actor.origin + actor.view_ofs,  // line from eyes
			autocvar_g_buffs_magnet_range,
			MOVE_NOMONSTERS,                // require line of sight
			buff_Magnet_cond);
		for (; head; head = next)
		{
			next = head.chain; // save next entity in case head is deleted (or head.chain changed) by gettouch(head)
			gettouch(head)(head, actor);
		}
	}

	vector vel = randomvec() * 75;
	buff_Effect(actor, EFFECT_MAGNET, CENTER_OF_ENT(actor) - vel, vel, 1, true); // needs countabsolute 1, spawning more requires calling buff_Effect repeatedly but that uses more bandwidth
	SUPER(MagnetBuff).m_tick(this, actor);
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
