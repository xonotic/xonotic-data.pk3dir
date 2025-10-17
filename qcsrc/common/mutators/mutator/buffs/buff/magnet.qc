#include "magnet.qh"

#ifdef SVQC
METHOD(MagnetBuff, m_tick, void(StatusEffect this, entity actor))
{
	if (IS_PLAYER(actor))
	{
		vector pickup_size;
		IL_EACH(g_items, it.itemdef, {
			if (it.buffdef)
				pickup_size = '1 1 1' * autocvar_g_buffs_magnet_range_buff;
			else
				pickup_size = '1 1 1' * autocvar_g_buffs_magnet_range_item;

			if (boxesoverlap(actor.absmin - pickup_size, actor.absmax + pickup_size, it.absmin, it.absmax))
			if (gettouch(it))
				gettouch(it)(it, actor);
		});
	}

	SUPER(MagnetBuff).m_tick(this, actor);
}
#endif // SVQC
#ifdef MENUQC
METHOD(MagnetBuff, describe, string(MagnetBuff this))
{
	TC(MagnetBuff, this);
	PAGE_TEXT_INIT();
	PAR(_("The %s buff greatly increases your item pickup range, collecting nearby items for you while the buff is active."), COLORED_NAME(this));
	return PAGE_TEXT;
}
#endif // MENUQC
