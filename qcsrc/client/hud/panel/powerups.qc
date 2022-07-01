#include "powerups.qh"

#include <client/draw.qh>
#include <common/items/_mod.qh>
#include <common/util.qh>

// Powerups (#2)

void HUD_Powerups_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
	HUD_Write_Cvar("hud_panel_powerups_iconalign");
	HUD_Write_Cvar("hud_panel_powerups_baralign");
	HUD_Write_Cvar("hud_panel_powerups_progressbar");
	HUD_Write_Cvar("hud_panel_powerups_text");
}

// Powerup item fields (reusing existing fields)
.string message;  // Human readable name
.string netname;  // Icon name
.vector colormod; // Color
.float count;     // Time left
.float lifetime;  // Maximum time
.float cnt;       // Infinite timer

entity powerupItems;
int powerupItemsCount;

void resetPowerupItems()
{
	entity item;
	for(item = powerupItems; item; item = item.chain)
		item.count = 0;

	powerupItemsCount = 0;
}

void addPowerupItem(string name, string icon, vector color, float currentTime, float lifeTime, bool isInfinite)
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
	item.cnt      = isInfinite;

	++powerupItemsCount;
}

int getPowerupItemAlign(int align, int column, int row, int columns, int rows, bool isVertical)
{
	TC(int, align); TC(int, column); TC(int, row); TC(int, columns); TC(int, rows); TC(bool, isVertical);
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
	// Initialize items
	if(!autocvar__hud_configure)
	{
		if((!autocvar_hud_panel_powerups) || (spectatee_status == -1))
			return;
		if(STAT(HEALTH) <= 0 && autocvar_hud_panel_powerups_hide_ondeath)
			return;
	}

	// Add items to linked list
	resetPowerupItems();

	MUTATOR_CALLHOOK(HUD_Powerups_add);

	if(!powerupItemsCount)
		return;

	// Draw panel background
	HUD_Panel_LoadCvars();

	if (autocvar_hud_panel_powerups_dynamichud)
		HUD_Scale_Enable();
	else
		HUD_Scale_Disable();
	HUD_Panel_DrawBg();

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
	vector itemSize = vec2(size.x / columns, size.y / rows);
	vector textColor = '1 1 1';

	int fullSeconds = 0;
	int align = 0;
	int column = 0;
	int row = 0;

	draw_beginBoldFont();
	for(entity item = powerupItems; item.count; item = item.chain)
	{
		itemPos = vec2(pos.x + column * itemSize.x, pos.y + row * itemSize.y);

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

			if(item.cnt)
				DrawNumIcon(itemPos, itemSize, fullSeconds, item.netname, isVertical, true, align, textColor, panel_fg_alpha);
			else
			{
				if(item.count > 1)
					DrawNumIcon(itemPos, itemSize, fullSeconds, item.netname, isVertical, false, align, textColor, panel_fg_alpha);
				if(item.count <= 5)
					DrawNumIcon_expanding(itemPos, itemSize, fullSeconds, item.netname, isVertical, false, align, textColor, panel_fg_alpha, bound(0, (fullSeconds - item.count) / 0.5, 1));
			}
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
