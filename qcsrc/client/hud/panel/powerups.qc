// Powerups (#2)

// Powerup item fields (reusing existing fields)
.string message;  // Human readable name
.string netname;  // Icon name
.vector colormod; // Color
.float count;     // Time left
.float lifetime;  // Maximum time

entity powerupItems;
int powerupItemsCount;

void resetPowerupItems()
{
	entity item;
	for(item = powerupItems; item; item = item.chain)
		item.count = 0;

	powerupItemsCount = 0;
}

void addPowerupItem(string name, string icon, vector color, float currentTime, float lifeTime)
{
	if(!powerupItems)
		powerupItems = spawn();

	entity item;
	for(item = powerupItems; item.count; item = item.chain)
		if(!item.chain)
			item.chain = spawn();

	item.message  = name;
	item.netname  = icon;
	item.colormod = color;
	item.count    = currentTime;
	item.lifetime = lifeTime;

	++powerupItemsCount;
}

int getPowerupItemAlign(int align, int column, int row, int columns, int rows, bool isVertical)
{
	if(align < 2)
		return align;

	bool isTop    =  isVertical && rows > 1 && row == 0;
	bool isBottom =  isVertical && rows > 1 && row == rows-1;
	bool isLeft   = !isVertical && columns > 1 && column == 0;
	bool isRight  = !isVertical && columns > 1 && column == columns-1;

	if(isTop    || isLeft)  return (align == 2) ? 1 : 0;
	if(isBottom || isRight) return (align == 2) ? 0 : 1;

	return 2;
}

void HUD_Powerups()
{
	int allItems = STAT(ITEMS);
	int allBuffs = STAT(BUFFS);
	int strengthTime, shieldTime, superTime;

	// Initialize items
	if(!autocvar__hud_configure)
	{
		if(!autocvar_hud_panel_powerups) return;
		if(spectatee_status == -1) return;
		if(STAT(HEALTH) <= 0) return;
		if(!(allItems & (ITEM_Strength.m_itemid | ITEM_Shield.m_itemid | IT_SUPERWEAPON)) && !allBuffs) return;

		strengthTime = bound(0, STAT(STRENGTH_FINISHED) - time, 99);
		shieldTime = bound(0, STAT(INVINCIBLE_FINISHED) - time, 99);
		superTime = bound(0, STAT(SUPERWEAPONS_FINISHED) - time, 99);

		if(allItems & IT_UNLIMITED_SUPERWEAPONS)
			superTime = 99;

		// Prevent stuff to show up on mismatch that will be fixed next frame
		if(!(allItems & IT_SUPERWEAPON))
			superTime = 0;
	}
	else
	{
		strengthTime = 15;
		shieldTime = 27;
		superTime = 13;
		allBuffs = 0;
	}

	// Add items to linked list
	resetPowerupItems();

	if(strengthTime)
		addPowerupItem("Strength", "strength", autocvar_hud_progressbar_strength_color, strengthTime, 30);
	if(shieldTime)
		addPowerupItem("Shield", "shield", autocvar_hud_progressbar_shield_color, shieldTime, 30);
	if(superTime)
		addPowerupItem("Superweapons", "superweapons", autocvar_hud_progressbar_superweapons_color, superTime, 30);

	MUTATOR_CALLHOOK(HUD_Powerups_add);

	if(!powerupItemsCount)
		return;

	// Draw panel background
	HUD_Panel_UpdateCvars();
	HUD_Panel_DrawBg(1);

	// Set drawing area
	vector pos = panel_pos;
	vector size = panel_size;
	bool isVertical = size.y > size.x;

	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		size -= '2 2 0' * panel_bg_padding;
	}

	// Find best partitioning of the drawing area
	const float DESIRED_ASPECT = 6;
	float aspect = 0, a;
	int columns = 0, c;
	int rows = 0, r;
	int i = 1;

	do
	{
		c = floor(powerupItemsCount / i);
		r = ceil(powerupItemsCount / c);
		a = isVertical ? (size.y/r) / (size.x/c) : (size.x/c) / (size.y/r);

		if(i == 1 || fabs(DESIRED_ASPECT - a) < fabs(DESIRED_ASPECT - aspect))
		{
			aspect = a;
			columns = c;
			rows = r;
		}
	}
	while(++i <= powerupItemsCount);

	// Prevent single items from getting too wide
	if(powerupItemsCount == 1 && aspect > DESIRED_ASPECT)
	{
		if(isVertical)
		{
			size.y *= 0.5;
			pos.y += size.y * 0.5;
		}
		else
		{
			size.x *= 0.5;
			pos.x += size.x * 0.5;
		}
	}

	// Draw items from linked list
	vector itemPos = pos;
	vector itemSize = eX * (size.x / columns) + eY * (size.y / rows);
	vector textColor = '1 1 1';

	int fullSeconds = 0;
	int align = 0;
	int column = 0;
	int row = 0;

	draw_beginBoldFont();
	for(entity item = powerupItems; item.count; item = item.chain)
	{
		itemPos = eX * (pos.x + column * itemSize.x) + eY * (pos.y + row * itemSize.y);

		// Draw progressbar
		if(autocvar_hud_panel_powerups_progressbar)
		{
			align = getPowerupItemAlign(autocvar_hud_panel_powerups_baralign, column, row, columns, rows, isVertical);
			HUD_Panel_DrawProgressBar(itemPos, itemSize, "progressbar", item.count / item.lifetime, isVertical, align, item.colormod, autocvar_hud_progressbar_alpha * panel_fg_alpha, DRAWFLAG_NORMAL);
		}

		// Draw icon and text
		if(autocvar_hud_panel_powerups_text)
		{
			align = getPowerupItemAlign(autocvar_hud_panel_powerups_iconalign, column, row, columns, rows, isVertical);
			fullSeconds = ceil(item.count);
			textColor = '0.6 0.6 0.6' + (item.colormod * 0.4);

			if(item.count > 1)
				DrawNumIcon(itemPos, itemSize, fullSeconds, item.netname, isVertical, align, textColor, panel_fg_alpha);
			if(item.count <= 5)
				DrawNumIcon_expanding(itemPos, itemSize, fullSeconds, item.netname, isVertical, align, textColor, panel_fg_alpha, bound(0, (fullSeconds - item.count) / 0.5, 1));
		}

		// Determine next section
		if(isVertical)
		{
			if(++column >= columns)
			{
				column = 0;
				++row;
			}
		}
		else
		{
			if(++row >= rows)
			{
				row = 0;
				++column;
			}
		}
	}
	draw_endBoldFont();
}
