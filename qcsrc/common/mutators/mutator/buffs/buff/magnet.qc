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
