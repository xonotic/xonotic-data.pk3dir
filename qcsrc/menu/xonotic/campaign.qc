#include "campaign.qh"

#include <common/campaign_common.qh>
#include "inputbox.qh"

string campaign_longdesc_wrapped[CAMPAIGN_MAX_ENTRIES];

void rewrapCampaign(float w, float l0, float emptyheight, vector theFontSize)
{
	int i, j;
	int n;
	float l;
	string r, s;
	for(i = 0; i < campaign_entries; ++i)
	{
		l = l0;
		strfree(campaign_longdesc_wrapped[i]);
		n = tokenizebyseparator(campaign_longdesc[i], "\n");
		r = "";
		for(j = 0; j < n; ++j)
		{
			s = argv(j);
			if(s == "")
			{
				l -= emptyheight;
				r = strcat(r, "\n");
				continue;
			}

			getWrappedLine_remaining = s;
			while(getWrappedLine_remaining)
			{
				s = getWrappedLine(w, theFontSize, draw_TextWidth_WithoutColors);
				if(--l < 0) goto toolong;
				r = strcat(r, s, "\n");
			}
		}
		goto nottoolong;
LABEL(toolong)
		while(substring(r, strlen(r) - 1, 1) == "\n")
			r = substring(r, 0, strlen(r) - 1);
		r = strcat(r, "...\n");
LABEL(nottoolong)
		campaign_longdesc_wrapped[i] = strzone(substring(r, 0, strlen(r) - 1));
	}
}

entity makeXonoticCampaignList()
{
	entity me;
	me = NEW(XonoticCampaignList);
	me.configureXonoticCampaignList(me);
	return me;
}
void XonoticCampaignList_configureXonoticCampaignList(entity me)
{
	me.configureXonoticListBox(me);
	me.campaignGlob = search_begin("maps/campaign*.txt", true, true);
	me.loadCvars(me);
	me.campaignGo(me, 0); // it makes work buttons too
}

void XonoticCampaignList_destroy(entity me)
{
	if(me.campaignGlob >= 0)
		search_end(me.campaignGlob);
}

void XonoticCampaignList_loadCvars(entity me)
{
	// read campaign cvars
	strcpy(campaign_name, cvar_string("g_campaign_name"));
	strcpy(me.controlledCvar, strcat("g_campaign", campaign_name, "_index"));
	registercvar(me.controlledCvar, "", 0); // saved by server QC anyway
	CampaignFile_Unload();
	CampaignFile_Load(0, CAMPAIGN_MAX_ENTRIES);
	me.campaignIndex = bound(0, cvar(me.controlledCvar), campaign_entries);
	cvar_set(me.controlledCvar, ftos(me.campaignIndex));
	if(me.columnNameSize)
		rewrapCampaign(me.columnNameSize, me.rowsPerItem - 3, me.emptyLineHeight, me.realFontSize);
	me.nItems = min(me.campaignIndex + 2, campaign_entries);
	me.setSelected(me, min(me.campaignIndex, me.nItems - 1));
	if(me.nItems - 1 > me.campaignIndex)
		me.scrollToItem(me, me.nItems - 1);
	if(me.labelTitle)
		me.labelTitle.setText(me.labelTitle, campaign_title);
}

void XonoticCampaignList_saveCvars(entity me)
{
	// write campaign cvars
	// no reason to do this!
	// cvar_set("g_campaign_name", campaign_name);
	// cvar_set(me.controlledCvar, ftos(me.campaignIndex)); // NOTE: only server QC does that!
}

void XonoticCampaignList_campaignGo(entity me, float step)
{
	string s;
	float i, j, n;

	if(me.campaignGlob >= 0)
	{
		n = search_getsize(me.campaignGlob);
		if(n > 0)
		{
			j = -1;
			s = strcat("maps/campaign", campaign_name, ".txt");
			for(i = 0; i < n; ++i)
			{
				if(search_getfilename(me.campaignGlob, i) == s)
					j = i;
			}
			if(j < 0)
			{
				s = strcat("maps/campaign", cvar_defstring("g_campaign_name"), ".txt");
				for(i = 0; i < n; ++i)
				{
					if(search_getfilename(me.campaignGlob, i) == s)
						j = i;
				}
			}
			if(j < 0)
			{
				if(step >= 0)
					j = 0;
				else
					j = n - 1;
			}
			else
				j = mod(j + step, n);
			s = search_getfilename(me.campaignGlob, j);
			s = substring(s, 13, strlen(s) - 17);
			cvar_set("g_campaign_name", s);
			me.loadCvars(me);
			me.hasNextCampaign = (j != n - 1);
			me.hasPrevCampaign = (j != 0);
		}
	}
}

void MultiCampaign_Next(entity btn, entity me)
{
	me.campaignGo(me, +1);
}
void MultiCampaign_Prev(entity btn, entity me)
{
	me.campaignGo(me, -1);
}

void XonoticCampaignList_draw(entity me)
{
	if(me.buttonNext)
		me.buttonNext.disabled = !me.hasNextCampaign;
	if(me.buttonPrev)
		me.buttonPrev.disabled = !me.hasPrevCampaign;

	if(cvar(me.controlledCvar) != me.campaignIndex || cvar_string("g_campaign_name") != campaign_name)
		me.loadCvars(me);
	SUPER(XonoticCampaignList).draw(me);
}

void XonoticCampaignList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticCampaignList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin1 = 0.5 * me.realFontSize.y;
	me.realUpperMargin2 = me.realUpperMargin1 + 2 * me.realFontSize.y;

	me.checkMarkSize = (eX * (me.itemAbsSize.y / me.itemAbsSize.x) + eY) * 0.5;

	me.columnPreviewOrigin = 0;
	me.columnPreviewSize = me.itemAbsSize.y / me.itemAbsSize.x * 4 / 3;
	me.columnCheckMarkSize = me.checkMarkSize.x;
	me.columnNameSize = 1 - me.columnPreviewSize - me.columnCheckMarkSize - 4 * me.realFontSize.x;
	me.columnNameOrigin = me.columnPreviewOrigin + me.columnPreviewSize + me.realFontSize.x;
	me.columnCheckMarkOrigin = me.columnNameOrigin + me.columnNameSize + me.realFontSize.x * 2;

	me.checkMarkOrigin = eY + eX * (me.columnCheckMarkOrigin + me.columnCheckMarkSize) - me.checkMarkSize;

	me.typeIconOrigin = vec3(me.columnPreviewSize - me.checkMarkSize.x, me.checkMarkOrigin.y, 0);
	me.typeIconSize = me.checkMarkSize;

	rewrapCampaign(me.columnNameSize, me.rowsPerItem - 3, me.emptyLineHeight, me.realFontSize);
}
void XonoticCampaignList_doubleClickListBoxItem(entity me, float i, vector where)
{
	CampaignList_LoadMap(me, me);
}
void XonoticCampaignList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s;
	vector theColor;
	float theAlpha;
	float j, n;
	vector o;

	if(i < me.campaignIndex)
	{
		theAlpha = SKINALPHA_CAMPAIGN_SELECTABLE;
		theColor = SKINCOLOR_CAMPAIGN_SELECTABLE;
	}
	else if(i == me.campaignIndex)
	{
		theAlpha = SKINALPHA_CAMPAIGN_CURRENT;
		theColor = SKINCOLOR_CAMPAIGN_CURRENT;
	}
	else
	{
		theAlpha = SKINALPHA_CAMPAIGN_FUTURE;
		theColor = SKINCOLOR_CAMPAIGN_FUTURE;
	}

	if(isSelected)
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_SELECTED, SKINALPHA_LISTBOX_SELECTED);
	else if(isFocused)
	{
		me.focusedItemAlpha = getFadedAlpha(me.focusedItemAlpha, SKINALPHA_LISTBOX_FOCUSED, SKINFADEALPHA_LISTBOX_FOCUSED);
		draw_Fill('0 0 0', '1 1 0', SKINCOLOR_LISTBOX_FOCUSED, me.focusedItemAlpha);
	}

	if(draw_PictureSize(strcat("/maps/", campaign_mapname[i])) == '0 0 0')
		draw_Picture(me.columnPreviewOrigin * eX, "nopreview_map", me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);
	else
		draw_Picture(me.columnPreviewOrigin * eX, strcat("/maps/", campaign_mapname[i]), me.columnPreviewSize * eX + eY, '1 1 1', theAlpha);

	s = strcat("gametype_", campaign_gametype[i]);
	if(i <= me.campaignIndex && draw_PictureSize(s) != '0 0 0')
		draw_Picture(me.typeIconOrigin, s, me.typeIconSize, '1 1 1', 1);

	if(i < me.campaignIndex)
		draw_Picture(me.checkMarkOrigin, "checkmark", me.checkMarkSize, '1 1 1', 1);

	if(i <= me.campaignIndex)
		s = campaign_shortdesc[i]; // fteqcc sucks
	else
		s = "???";
	// NOTE the following string should be equal to the one used in the Welcome dialog
	// to avoid adding a slightly different string to translate
	s = draw_TextShortenToWidth(strcat(sprintf(_("Level %d:"), i+1), " ", s), me.columnNameSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin1 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 0, me.realFontSize))) * eX, s, me.realFontSize, theColor, theAlpha, 0);

	if(i <= me.campaignIndex)
	{
		s = campaign_longdesc_wrapped[i];
		n = tokenizebyseparator(s, "\n");
		o = me.realUpperMargin2 * eY + me.columnNameOrigin * eX;
		for(j = 0; j < n; ++j)
			if(argv(j) != "")
			{
				draw_Text(o, argv(j), me.realFontSize, theColor, theAlpha * SKINALPHA_CAMPAIGN_DESCRIPTION, 0);
				o.y += me.realFontSize.y;
			}
			else
				o.y += me.realFontSize.y * me.emptyLineHeight;
	}
}
void CampaignList_LoadMap(entity btn, entity me)
{
	if(me.selectedItem >= me.nItems || me.selectedItem < 0)
		return;
	CampaignSetup(me.selectedItem);
}

void XonoticCampaignList_setSelected(entity me, float i)
{
	// prevent too late items from being played
	SUPER(XonoticCampaignList).setSelected(me, min(i, me.campaignIndex));
}

float XonoticCampaignList_keyDown(entity me, float scan, float ascii, float shift)
{
	if(scan == K_ENTER || scan == K_SPACE || scan == K_KP_ENTER)
		CampaignList_LoadMap(me, me);
	else
		return SUPER(XonoticCampaignList).keyDown(me, scan, ascii, shift);
	return 1;
}
