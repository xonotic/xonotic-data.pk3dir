#include "magnet.qh"

#ifdef SVQC
METHOD(MagnetBuff, m_tick, void(StatusEffect this, entity actor))
{
	if (IS_PLAYER(actor))
	{
		entity head = WarpZone_FindRadius(
			actor.origin + actor.view_ofs,  // line from eyes
			autocvar_g_buffs_magnet_range,
			true                            // require line of sight
		);
		for (; head; head = head.chain)
			if (head.itemdef // this (intentionally) doesn't include buffs
			&&  gettouch(head))
				gettouch(head)(head, actor);
	}

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
