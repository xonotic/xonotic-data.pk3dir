#include "playerlist.qh"

.float realUpperMargin2;

const int PLAYERPARM_SCORE = 0;
const int PLAYERPARM_PING = 1;
const int PLAYERPARM_TEAM = 2;
const int PLAYERPARM_NAME = 3;
const int PLAYERPARM_COUNT = 4;

entity makeXonoticPlayerList()
{
	entity me;
	me = NEW(XonoticPlayerList);
	me.configureXonoticListBox(me);
	return me;
}

void XonoticPlayerList_setPlayerList(entity me, string plist)
{
	int buf,i,n;
	string s;

	buf = buf_create();
	me.nItems = tokenizebyseparator(plist, "\n");
	for(i = 0; i < me.nItems; ++i)
	{
		bufstr_set(buf, i * PLAYERPARM_COUNT + PLAYERPARM_NAME, argv(i)); // -666 100 "^4Nex ^2Player"
	}

	for(i = 0; i < me.nItems; ++i)
	{
		s = bufstr_get(buf, i * PLAYERPARM_COUNT + PLAYERPARM_NAME);
		n = tokenize_console(s);

		if(n == PLAYERPARM_COUNT)
		{
			bufstr_set(buf, i * PLAYERPARM_COUNT + PLAYERPARM_SCORE, argv(0)); // -666
			bufstr_set(buf, i * PLAYERPARM_COUNT + PLAYERPARM_PING,  argv(1)); // 100
			bufstr_set(buf, i * PLAYERPARM_COUNT + PLAYERPARM_TEAM,  argv(2)); // 0 for spec, else 1, 2, 3, 4
			bufstr_set(buf, i * PLAYERPARM_COUNT + PLAYERPARM_NAME,  argv(3)); // ^4Nex ^2Player
		}
		else
		{
			bufstr_set(buf, i * PLAYERPARM_COUNT + PLAYERPARM_SCORE, argv(0)); // -666
			bufstr_set(buf, i * PLAYERPARM_COUNT + PLAYERPARM_PING,  argv(1)); // 100
			bufstr_set(buf, i * PLAYERPARM_COUNT + PLAYERPARM_TEAM,  "-1");
			bufstr_set(buf, i * PLAYERPARM_COUNT + PLAYERPARM_NAME,  argv(2)); // ^4Nex ^2Player
		}
	}
	me.playerList = buf;
}

string XonoticPlayerList_getPlayerList(entity me, float i, float key)
{
	return bufstr_get(me.playerList, i * PLAYERPARM_COUNT + key);
}

void XonoticPlayerList_resizeNotify(entity me, vector relOrigin, vector relSize, vector absOrigin, vector absSize)
{
	me.itemAbsSize = '0 0 0';
	SUPER(XonoticPlayerList).resizeNotify(me, relOrigin, relSize, absOrigin, absSize);

	me.itemAbsSize.y = absSize.y * me.itemHeight;
	me.itemAbsSize.x = absSize.x * (1 - me.controlWidth);
	me.realFontSize.y = me.fontSize / me.itemAbsSize.y;
	me.realFontSize.x = me.fontSize / me.itemAbsSize.x;
	me.realUpperMargin = 0.5 * (1 - me.realFontSize.y);

	// this list does 1 char left and right margin
	me.columnScoreSize = 5 * me.realFontSize.x;
	me.columnNameSize = 1 - 3 * me.realFontSize.x - me.columnScoreSize;

	me.columnNameOrigin = me.realFontSize.x;
	me.columnScoreOrigin = me.columnNameOrigin + me.columnNameSize + me.realFontSize.x;
}

void XonoticPlayerList_drawListBoxItem(entity me, int i, vector absSize, bool isSelected, bool isFocused)
{
	string s;
	string score;
	float t;
	vector rgb;

	t = stof(me.getPlayerList(me, i, PLAYERPARM_TEAM));
	if(t == 1)
		rgb = colormapPaletteColor(4, 0);
	else if(t == 2)
		rgb = colormapPaletteColor(13, 0);
	else if(t == 3)
		rgb = colormapPaletteColor(12, 0);
	else if(t == 4)
		rgb = colormapPaletteColor(9, 0);
	else
		rgb = SKINCOLOR_TEXT;

	s = me.getPlayerList(me, i, PLAYERPARM_NAME);
	score = me.getPlayerList(me, i, PLAYERPARM_SCORE);

	if(substring(score, strlen(score) - 10, 10) == ":spectator")
	{
		score = _("spectator");
	}
	else
	{
		if((t = strstrofs(score, ":", 0)) >= 0)
			score = substring(score, 0, t);
		if((t = strstrofs(score, ",", 0)) >= 0)
			score = substring(score, 0, t);

		if(stof(score) == FRAGS_SPECTATOR)
			score = _("spectator");
	}

	s = draw_TextShortenToWidth(s, me.columnNameSize, 1, me.realFontSize);
	draw_Text(me.realUpperMargin2 * eY + (me.columnNameOrigin + 0.00 * (me.columnNameSize - draw_TextWidth(s, 1, me.realFontSize))) * eX, s, me.realFontSize, '1 1 1', 1, 1);

	score = draw_TextShortenToWidth(score, me.columnScoreSize, 0, me.realFontSize);
	draw_Text(me.realUpperMargin2 * eY + (me.columnScoreOrigin + 1.00 * (me.columnScoreSize - draw_TextWidth(score, 1, me.realFontSize))) * eX, score, me.realFontSize, rgb, 1, 0);
}
