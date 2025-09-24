#include "dialog_multiplayer_create_mapinfo.qh"

#include "button.qh"
#include "image.qh"
#include "maplist.qh"
#include "textlabel.qh"
#include <common/mapinfo.qh>

void XonoticMapInfoDialog_loadMapInfo(entity me, int i, entity mlb)
{
	me.currentMapIndex = i;
	me.startButton.onClickEntity = mlb;
	MapInfo_Get_ByID(i);

	strcpy(me.currentMapBSPName, MapInfo_Map_bspname);
	strcpy(me.currentMapTitle, strdecolorize(MapInfo_Map_title));
	strcpy(me.currentMapAuthor, strdecolorize(MapInfo_Map_author));
	strcpy(me.currentMapDescription, MapInfo_Map_description);
	strcpy(me.currentMapPreviewImage, strcat("/maps/", MapInfo_Map_bspname));
	if(!draw_PictureExists(me.currentMapPreviewImage)) // Quake 3 compatibility
		strcpy(me.currentMapPreviewImage, strcat("/levelshots/", MapInfo_Map_bspname));

	me.frame.setText(me.frame, me.currentMapBSPName);
	me.titleLabel.setText(me.titleLabel, me.currentMapTitle);
	me.authorLabel.setText(me.authorLabel, me.currentMapAuthor);
	me.descriptionLabel.setText(me.descriptionLabel, me.currentMapDescription);
	if(!draw_PictureExists(me.currentMapPreviewImage))
		me.previewImage.src = "nopreview_map";
	else
		me.previewImage.src = me.currentMapPreviewImage;

	for(i = 0; i < GameType_GetTotalCount(); ++i)
	{
		entity e;
		e = me.(typeLabels[i]);
		e.disabled = !(MapInfo_Map_supportedGametypes & GameType_GetID(i).gametype_flags);
	}

	MapInfo_ClearTemps();
}
void XonoticMapInfoDialog_fill(entity me)
{
	entity e;
	int i;
	float w, wgt, n;
	me.TR(me);
		me.TDempty(me, 0.2);
		me.TD(me, me.rows - 2, 3, e = makeXonoticImage(string_null, 4.0/3.0));
		me.previewImage = e;
	me.gotoRC(me, 0, 3.5); me.setFirstColumn(me, me.currentColumn);
	w = me.columns - me.currentColumn;
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Title:")));
		me.TD(me, 1, w-1, e = makeXonoticTextLabel(0, ""));
			e.colorL = SKINCOLOR_MAPLIST_TITLE;
			e.allowCut = true;
			me.titleLabel = e;
	me.TR(me);
		me.TD(me, 1, 1, e = makeXonoticTextLabel(0, _("Author:")));
		me.TD(me, 1, w-1, e = makeXonoticTextLabel(0, ""));
			e.colorL = SKINCOLOR_MAPLIST_AUTHOR;
			e.allowCut = true;
			me.authorLabel = e;
	me.TR(me);
		me.TD(me, 1, w, e = makeXonoticTextLabel(0, _("Gametypes:")));

	n = ceil(GameType_GetTotalCount() / (me.rows - 6));
	wgt = (w - 0.2) / n;
	for(i = 0; i < GameType_GetTotalCount(); ++i)
	{
		if(mod(i, n) == 0)
		{
			me.TR(me);
			me.TDempty(me, 0.2);
		}
		me.TD(me, 1, wgt, e = makeXonoticTextLabel(0, MapInfo_Type_ToText(GameType_GetID(i))));
			me.(typeLabels[i]) = e;
	}

	me.gotoRC(me, me.rows - 2, 0);
		me.TD(me, 1, me.columns, e = makeXonoticTextLabel(0.5, ""));
			e.allowCut = true;
			me.descriptionLabel = e;

	me.gotoRC(me, me.rows - 1, 0);
		me.TDempty(me, 0.5);

		me.TD(me, 1, me.columns - 5.5, e = makeXonoticButton(_("Close"), '0 0 0'));
			e.onClick = Dialog_Close;
			e.onClickEntity = me;
		me.TD(me, 1, me.columns - 5.5, me.startButton = e = makeXonoticButton(ZCTX(_("MAP^Play")), '0 0 0'));
			me.startButton.onClick = MapList_LoadMap;
			me.startButton.onClickEntity = NULL; // filled later
			setDependent(e, "g_campaign", 0, 0);
}
