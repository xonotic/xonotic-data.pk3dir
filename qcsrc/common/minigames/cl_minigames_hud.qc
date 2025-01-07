#include "cl_minigames_hud.qh"

#include <client/draw.qh>
#include <client/hud/_mod.qh>
#include <client/hud/hud_config.qh>
#include <client/mapvoting.qh>
#include <common/ent_cs.qh>
#include <common/minigames/minigames.qh>

.vector colormod;

void HUD_MinigameBoard_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

void HUD_MinigameStatus_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

void HUD_MinigameHelp_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

void HUD_MinigameMenu_Export(int fh)
{
	// allow saving cvars that aesthetically change the panel into hud skin files
}

// whether the mouse is over the given panel
bool HUD_mouse_over(entity somepanel)
{
	vector pos = stov(cvar_string(strcat("hud_panel_", somepanel.panel_name, "_pos")));
	vector sz = stov(cvar_string(strcat("hud_panel_", somepanel.panel_name, "_size")));
	return mousepos_x >= pos_x*vid_conwidth  && mousepos_x <= (pos_x+sz_x)*vid_conwidth &&
	       mousepos_y >= pos_y*vid_conheight && mousepos_y <= (pos_y+sz_y)*vid_conheight ;
}

// ====================================================================
// Minigame Board
// ====================================================================

// Draws the minigame game board
void HUD_MinigameBoard ()
{
	if (!HUD_MinigameMenu_IsOpened())
		return;

	entity hud_minigame = NULL;

	if(!autocvar__hud_configure)
	{
		if (!active_minigame)
			return;
		hud_minigame = active_minigame.descriptor;
	}
	else
		hud_minigame = minigame_get_descriptor("nmm");

	if ( !hud_minigame )
		return;

	HUD_Panel_LoadCvars();


	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	hud_minigame.minigame_hud_board(pos,mySize);
}

// ====================================================================
// Minigame Status
// ====================================================================
// Draws the minigame status panel
void HUD_MinigameStatus ()
{
	if (!HUD_MinigameMenu_IsOpened())
		return;

	entity hud_minigame = NULL;

	if(!autocvar__hud_configure)
	{
		if (!active_minigame)
			return;
		hud_minigame = active_minigame.descriptor;
	}
	else
		hud_minigame = minigame_get_descriptor("nmm");

	if ( !hud_minigame )
		return;

	HUD_Panel_LoadCvars();


	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	HUD_Scale_Disable();
	hud_minigame.minigame_hud_status(pos,mySize);
}

// ====================================================================
// Minigame Menu
// ====================================================================

// Minigame menu options: list head
entity HUD_MinigameMenu_entries;
// Minigame menu options: list tail
entity HUD_MinigameMenu_last_entry;

// Minigame menu options: insert entry after the given location
void HUD_MinigameMenu_InsertEntry(entity newentry, entity prev)
{
	if ( !HUD_MinigameMenu_entries )
	{
		HUD_MinigameMenu_entries = newentry;
		HUD_MinigameMenu_last_entry = newentry;
		return;
	}

	newentry.list_prev = prev;
	newentry.list_next = prev.list_next;
	if ( prev.list_next )
		prev.list_next.list_prev = newentry;
	else
		HUD_MinigameMenu_last_entry = newentry;
	prev.list_next = newentry;
}


// minigame menu item uder the mouse
entity HUD_MinigameMenu_activeitem;

// Click the given item
void HUD_MinigameMenu_Click(entity menuitem)
{
	if ( menuitem )
	{
		menuitem.use(menuitem, NULL, NULL);
	}
}

// Minigame menu options: Remove the given entry
// Precondition: the given entry is actually in the list
void HUD_MinigameMenu_EraseEntry ( entity e )
{
	// remove child items (if any)
	if ( e.flags & 2 )
	{
		HUD_MinigameMenu_Click(e);
	}

	if ( e.list_prev )
		e.list_prev.list_next = e.list_next;
	else
		HUD_MinigameMenu_entries = e.list_next;

	if ( e.list_next )
		e.list_next.list_prev = e.list_prev;
	else
		HUD_MinigameMenu_last_entry = e.list_prev;

	if ( HUD_MinigameMenu_activeitem == e )
		HUD_MinigameMenu_activeitem = NULL;

	delete(e);
}

// Minigame menu options: create entry
entity HUD_MinigameMenu_SpawnEntry(entity entry, string s, vector offset, vector fontsize, vector color,void(entity, entity, entity) click)
{
	entry.message = s;
	entry.origin = offset;
	entry.size = fontsize;
	entry.colormod = color;
	entry.flags = 0;
	entry.use = click;
	panel_pos_y += fontsize_y;
	return entry;
}

// Spawn a child entry of a collapsable entry
entity HUD_MinigameMenu_SpawnSubEntry(string s, void(entity, entity, entity) click, entity parent)
{
	vector item_fontsize = hud_fontsize*1.25;
	vector item_offset = '1 0 0' * item_fontsize_x;
	entity item = HUD_MinigameMenu_SpawnEntry(new(hud_minigamemenu_subentry),
				s,item_offset,item_fontsize,'0.8 0.8 0.8', click );
	item.owner = parent;
	return item;
}

// Click action for Create sub-entries
void HUD_MinigameMenu_ClickCreate_Entry(entity this, entity actor, entity trigger)
{
	minigame_cmd("create ", this.netname);
}

// Helper click action for collapsible entries
// returns true when you have to create the sub-entries
bool HUD_MinigameMenu_Click_ExpandCollapse(entity this)
{
	entity e;
	if ( this.flags & 2 )
	{
		if ( HUD_MinigameMenu_activeitem &&
				HUD_MinigameMenu_activeitem.owner == this )
			HUD_MinigameMenu_activeitem = NULL;
		this.flags &= ~2;
		for ( e = this.list_next; e != NULL && e.owner == this; e = this.list_next )
		{
			if ( e.flags & 2 )
				HUD_MinigameMenu_Click(e);
			this.list_next = e.list_next;
			delete(e);
		}
		if ( this.list_next )
			this.list_next.list_prev = this;
		else
			HUD_MinigameMenu_last_entry = this;
	}
	else
	{
		for ( e = HUD_MinigameMenu_entries; e != NULL; e = e.list_next )
		{
			if ( (e.flags & 2) && e.origin_x == this.origin_x)
				HUD_MinigameMenu_Click(e);
		}

		this.flags |= 2;

		return true;
	}
	return false;
}

// Click action for the Create menu
void HUD_MinigameMenu_ClickCreate(entity this, entity actor, entity trigger)
{
	if ( HUD_MinigameMenu_Click_ExpandCollapse(this) )
	{
		entity curr;
		entity prev = this;
		FOREACH(Minigames, true, {
			curr = HUD_MinigameMenu_SpawnSubEntry(it.message, HUD_MinigameMenu_ClickCreate_Entry, this);
			curr.netname = it.netname;
			curr.model = strzone(minigame_texture(strcat(it.netname,"/icon")));
			HUD_MinigameMenu_InsertEntry( curr, prev );
			prev = curr;
		});
	}
}

// Click action for Join sub-entries
void HUD_MinigameMenu_ClickJoin_Entry(entity this, entity actor, entity trigger)
{
	minigame_cmd("join ",this.netname);
	HUD_MinigameMenu_EraseEntry(this);
}

// Click action for the Join menu
void HUD_MinigameMenu_ClickJoin(entity this, entity actor, entity trigger)
{
	if ( HUD_MinigameMenu_Click_ExpandCollapse(this) )
	{
		entity e = NULL;
		entity curr;
		entity prev = this;
		while( (e = find(e,classname,"minigame")) )
		{
			if ( e != active_minigame )
			{
				curr = HUD_MinigameMenu_SpawnSubEntry(
					e.netname, HUD_MinigameMenu_ClickJoin_Entry, this );
				curr.netname = e.netname;
				curr.model = strzone(minigame_texture(strcat(e.descriptor.netname,"/icon")));
				HUD_MinigameMenu_InsertEntry( curr, prev );
				prev = curr;
			}
		}
	}
}

/*// Temporary placeholder for un-implemented Click actions
void HUD_MinigameMenu_ClickNoop()
{
	dprint("Placeholder for ",this.message,"\n");
}*/

// Click action for Quit
void HUD_MinigameMenu_ClickQuit(entity this, entity actor, entity trigger)
{
	deactivate_minigame();
	minigame_cmd("end");
}

// Click action for Invite sub-entries
void HUD_MinigameMenu_ClickInvite_Entry(entity this, entity actor, entity trigger)
{
	minigame_cmd("invite #",this.netname);
}

// Click action for the Invite menu
void HUD_MinigameMenu_ClickInvite(entity this, entity actor, entity trigger)
{
	if ( HUD_MinigameMenu_Click_ExpandCollapse(this) )
	{
		entity e;
		entity prev = this;
		for(int i = 0; i < maxclients; ++i)
		{
			if ( player_localnum != i && playerslots[i] && entcs_GetName(i) != "" &&
				!findfloat(NULL,minigame_playerslot,i+1) && playerslots[i].ping )
			{
				e = HUD_MinigameMenu_SpawnSubEntry(
					strzone(entcs_GetName(i)), HUD_MinigameMenu_ClickInvite_Entry,
					this );
				e.flags |= 1;
				e.netname = strzone(ftos(i+1));
				e.origin_x *= 2;
				HUD_MinigameMenu_InsertEntry(e,prev);
				prev = e;
			}
		}
	}
}

void HUD_MinigameMenu_ClickCustomEntry(entity this, entity actor, entity trigger)
{
	if ( active_minigame )
		active_minigame.minigame_event(active_minigame,"menu_click",this.netname);
}

// Adds a game-specific entry to the menu
void HUD_MinigameMenu_CustomEntry(entity parent, string menumessage, string event_arg)
{
	entity e = HUD_MinigameMenu_SpawnSubEntry(
		menumessage, HUD_MinigameMenu_ClickCustomEntry, parent );
	e.netname = event_arg;
	HUD_MinigameMenu_InsertEntry(e, parent);
	//dprint("CustomEntry ",ftos(num_for_edict(parent))," ",menumessage," ",event_arg,"\n");
}

// Click action for the Current Game menu
void HUD_MinigameMenu_ClickCurrentGame(entity this, entity actor, entity trigger)
{
	if ( HUD_MinigameMenu_Click_ExpandCollapse(this) )
	{
		HUD_MinigameMenu_InsertEntry( HUD_MinigameMenu_SpawnSubEntry(
			_("Quit"), HUD_MinigameMenu_ClickQuit, this ), this);

		active_minigame.minigame_event(active_minigame,"menu_show",this);

		HUD_MinigameMenu_InsertEntry( HUD_MinigameMenu_SpawnSubEntry(
			_("Invite"), HUD_MinigameMenu_ClickInvite, this), this);
	}
}
// Whether the minigame menu panel is open
bool HUD_MinigameMenu_IsOpened()
{
	return HUD_MinigameMenu_entries != NULL;
}

// Close the minigame menu panel
void HUD_MinigameMenu_Close(entity this, entity actor, entity trigger)
{
	if ( HUD_MinigameMenu_IsOpened() )
	{
		entity e, p;
		for ( e = HUD_MinigameMenu_entries; e != NULL; e = p )
		{
			p = e.list_next;
			delete(e);
		}
		HUD_MinigameMenu_entries = NULL;
		HUD_MinigameMenu_last_entry = NULL;
		HUD_MinigameMenu_activeitem = NULL;
	}
}

// toggle a button to manage the current game
void HUD_MinigameMenu_CurrentButton()
{
	entity e;
	if ( active_minigame )
	{
		for ( e = HUD_MinigameMenu_last_entry; e != NULL; e = e.list_prev )
			if ( e.classname == "hud_minigamemenu_exit" )
			{
				HUD_MinigameMenu_EraseEntry(e);
				break;
			}
		entity currb = HUD_MinigameMenu_SpawnEntry(new(hud_minigamemenu_current),
			_("Current Game"), '0 0 0', hud_fontsize*1.5,'0.7 0.84 1', HUD_MinigameMenu_ClickCurrentGame );
		currb.model = strzone(minigame_texture(strcat(active_minigame.descriptor.netname,"/icon")));
		HUD_MinigameMenu_InsertEntry(currb,HUD_MinigameMenu_last_entry);
		HUD_MinigameMenu_Click(currb);
	}
	else
	{
		entity p;
		for ( e = HUD_MinigameMenu_last_entry; e != NULL; e = p.list_prev )
		{
			p = e;
			if ( e.classname == "hud_minigamemenu_current" )
			{
				p = e.list_next;
				if ( !p )
					p = HUD_MinigameMenu_last_entry;
				HUD_MinigameMenu_EraseEntry(e);
				break;
			}
		}
		for ( e = HUD_MinigameMenu_last_entry; e != NULL; e = e.list_prev )
			if ( e.classname == "hud_minigamemenu_exit" )
				return;
		entity exit = HUD_MinigameMenu_SpawnEntry(new(hud_minigamemenu_exit),
			_("Exit Menu"),'0 0 0',hud_fontsize*1.5,'0.7 0.84 1', HUD_MinigameMenu_Close);
		HUD_MinigameMenu_InsertEntry ( exit, HUD_MinigameMenu_last_entry );
	}
}

// Open the minigame menu panel
void HUD_MinigameMenu_Open()
{
	if ( !mv_active && !HUD_MinigameMenu_IsOpened() )
	{
		HUD_MinigameMenu_InsertEntry( HUD_MinigameMenu_SpawnEntry(new(hud_minigamemenu_entry),
			_("Create"), '0 0 0', hud_fontsize*1.5,'0.7 0.84 1', HUD_MinigameMenu_ClickCreate),
			HUD_MinigameMenu_last_entry );
		HUD_MinigameMenu_InsertEntry ( HUD_MinigameMenu_SpawnEntry(new(hud_minigamemenu_entry),
			_("Join"),'0 0 0',hud_fontsize*1.5,'0.7 0.84 1', HUD_MinigameMenu_ClickJoin),
			HUD_MinigameMenu_last_entry );
		HUD_MinigameMenu_CurrentButton();
		HUD_MinigameMenu_activeitem = NULL;
	}
}

// Handles mouse input on to minigame menu panel
void HUD_MinigameMenu_MouseInput()
{
	panel = HUD_PANEL(MINIGAMEMENU);

	HUD_Panel_LoadCvars();

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	entity e;

	panel_pos_y += hud_fontsize_y*2;

	HUD_MinigameMenu_activeitem = NULL;
	vector sz;
	for ( e = HUD_MinigameMenu_entries; e != NULL; e = e.list_next )
	{
		sz = eX*panel_size_x + eY*e.size_y;
		if ( e.model )
			sz_y = 22;
		if ( !HUD_MinigameMenu_activeitem && mousepos_y >= panel_pos_y && mousepos_y <= panel_pos_y + sz_y )
		{
			HUD_MinigameMenu_activeitem = e;
		}
		panel_pos_y += sz_y;
	}
}

// Draw a menu entry
void HUD_MinigameMenu_DrawEntry(vector pos, string s, vector fontsize, vector color)
{
	minigame_drawstring_trunc(panel_size_x-pos_x+panel_pos_x, pos, s,
							  fontsize, color, panel_fg_alpha, DRAWFLAG_NORMAL);
}
// Draw a color-coded menu
void HUD_MinigameMenu_DrawColoredEntry(vector pos, string s, vector fontsize)
{
	minigame_drawcolorcodedstring_trunc(panel_size_x-pos_x+panel_pos_x, pos, s,
							  fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);
}

// Minigame menu panel UI
void HUD_MinigameMenu ()
{
	if (mv_active)
	{
		if (HUD_MinigameMenu_IsOpened())
			HUD_MinigameMenu_Close(NULL, NULL, NULL);
		return;
	}

	if ( !HUD_MinigameMenu_IsOpened() )
		return;

	HUD_Panel_LoadCvars();

	HUD_Scale_Disable();
	HUD_Panel_DrawBg();

	if(panel_bg_padding)
	{
		panel_pos += '1 1 0' * panel_bg_padding;
		panel_size -= '2 2 0' * panel_bg_padding;
	}

	HUD_MinigameMenu_DrawEntry(panel_pos,_("Minigames"),hud_fontsize*2,'0.25 0.47 0.72');
	panel_pos_y += hud_fontsize_y*2;

	vector color;
	vector offset;
	float itemh;
	vector imgsz = '22 22 0'; // NOTE: if changed, edit where HUD_MinigameMenu_activeitem is selected
	for ( entity e = HUD_MinigameMenu_entries; e != NULL; e = e.list_next )
	{
		color = e.colormod;

		offset = e.origin;
		itemh = e.size_y;

		if ( e.model )
			itemh = imgsz_y;

		if ( e.flags & 2 )
		{
			drawfill(panel_pos, eX*panel_size_x + eY*itemh, e.colormod, panel_fg_alpha, DRAWFLAG_NORMAL);
			color = '0 0 0';
		}

		if ( e.model )
		{
			drawpic( panel_pos+offset, e.model, imgsz, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
			offset_x += imgsz_x;
			offset_y = (imgsz_y-e.size_y) / 2;
		}

		if ( e.flags & 1 )
			HUD_MinigameMenu_DrawColoredEntry(panel_pos+offset,e.message,e.size);
		else
			HUD_MinigameMenu_DrawEntry(panel_pos+offset,e.message,e.size,color);

		if ( e == HUD_MinigameMenu_activeitem )
			drawfill(panel_pos, eX*panel_size_x + eY*itemh,'1 1 1', 0.25 * panel_fg_alpha, DRAWFLAG_ADDITIVE);

		panel_pos_y += itemh;
	}
}

// ====================================================================
// Minigame Help Panel
// ====================================================================

void HUD_MinigameHelp()
{
	if (!HUD_MinigameMenu_IsOpened())
		return;

	string help_message;

	if(!autocvar__hud_configure)
	{
		if (!active_minigame)
			return;
		help_message = active_minigame.message;
	}
	else
		help_message = _("Minigame message");

	if ( !help_message )
		return;

	HUD_Panel_LoadCvars();


	vector pos, mySize;
	pos = panel_pos;
	mySize = panel_size;

	if(panel_bg_padding)
	{
		pos += '1 1 0' * panel_bg_padding;
		mySize -= '2 2 0' * panel_bg_padding;
	}

	minigame_drawcolorcodedstring_wrapped( mySize_x, pos, help_message,
		hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL, 0.5 );
}

// ====================================================================
// Minigame Panel Input
// ====================================================================
float HUD_Minigame_InputEvent(float bInputType, float nPrimary, float nSecondary)
{

	if( !HUD_MinigameMenu_IsOpened() || autocvar__hud_configure )
		return false;

	if(bInputType == 3)
	{
		mousepos_x = nPrimary;
		mousepos_y = nSecondary;
		if ( active_minigame && HUD_mouse_over(HUD_PANEL(MINIGAMEBOARD)) )
			active_minigame.minigame_event(active_minigame,"mouse_moved",mousepos);
		return true;
	}

	if(bInputType == 2)
	{
		if ( active_minigame && HUD_mouse_over(HUD_PANEL(MINIGAMEBOARD)) )
			active_minigame.minigame_event(active_minigame,"mouse_moved",mousepos);
		return false;
	}

	// at this point bInputType can only be 0 or 1 (key pressed or released)
	bool key_pressed = (bInputType == 0);

	if(key_pressed) {
		if(nPrimary == K_ALT) hudShiftState |= S_ALT;
		if(nPrimary == K_CTRL) hudShiftState |= S_CTRL;
		if(nPrimary == K_SHIFT) hudShiftState |= S_SHIFT;
		if(nPrimary == K_MOUSE1) mouseClicked |= S_MOUSE1;
		if(nPrimary == K_MOUSE2) mouseClicked |= S_MOUSE2;
	}
	else {
		if(nPrimary == K_ALT) hudShiftState &= ~S_ALT;
		if(nPrimary == K_CTRL) hudShiftState &= ~S_CTRL;
		if(nPrimary == K_SHIFT) hudShiftState &= ~S_SHIFT;
		if(nPrimary == K_MOUSE1) mouseClicked &= ~S_MOUSE1;
		if(nPrimary == K_MOUSE2) mouseClicked &= ~S_MOUSE2;
	}

	// allow some binds
	string con_keys = findkeysforcommand("toggleconsole", 0);
	int keys = tokenize(con_keys); // findkeysforcommand returns data for this
	int i;
	for (i = 0; i < keys; ++i)
	{
		if(nPrimary == stof(argv(i)))
			return false;
	}

	if ( active_minigame )
	{
		string device = "";
		string action = key_pressed ? "pressed" : "released";
		if ( nPrimary >= K_MOUSE1 && nPrimary <= K_MOUSE16 )
		{
			if ( HUD_mouse_over(HUD_PANEL(MINIGAMEBOARD)) )
				device = "mouse";
		}
		else
			device = "key";

		if ( device && active_minigame.minigame_event(
				active_minigame,strcat(device,"_",action),nPrimary) )
			return true;
	}

	if ( nPrimary == K_MOUSE2 )
	{
		return true;
	}
	if ( nPrimary == K_MOUSE1 )
	{
		if (!key_pressed)
			return true;
		if (HUD_MinigameMenu_activeitem && HUD_mouse_over(HUD_PANEL(MINIGAMEMENU)))
			HUD_MinigameMenu_Click(HUD_MinigameMenu_activeitem);
		return true;
	}
	if ( nPrimary == K_UPARROW || nPrimary == K_KP_UPARROW )
	{
		if (!key_pressed)
			return true;
		if ( HUD_MinigameMenu_activeitem && HUD_MinigameMenu_activeitem.list_prev )
			HUD_MinigameMenu_activeitem = HUD_MinigameMenu_activeitem.list_prev;
		else
			HUD_MinigameMenu_activeitem = HUD_MinigameMenu_last_entry;
		return true;
	}
	else if ( nPrimary == K_DOWNARROW || nPrimary == K_KP_DOWNARROW )
	{
		if (!key_pressed)
			return true;
		if ( HUD_MinigameMenu_activeitem && HUD_MinigameMenu_activeitem.list_next )
			HUD_MinigameMenu_activeitem = HUD_MinigameMenu_activeitem.list_next;
		else
			HUD_MinigameMenu_activeitem = HUD_MinigameMenu_entries;
		return true;
	}
	else if ( nPrimary == K_HOME || nPrimary == K_KP_HOME )
	{
		if (!key_pressed)
			return true;
		HUD_MinigameMenu_activeitem = HUD_MinigameMenu_entries;
		return true;
	}
	else if ( nPrimary == K_END || nPrimary == K_KP_END )
	{
		if (!key_pressed)
			return true;
		HUD_MinigameMenu_activeitem = HUD_MinigameMenu_entries;
		return true;
	}
	else if ( nPrimary == K_KP_ENTER || nPrimary == K_ENTER || nPrimary == K_SPACE )
	{
		if (!key_pressed)
			return true;
		HUD_MinigameMenu_Click(HUD_MinigameMenu_activeitem);
		return true;
	}
	else if ( nPrimary == K_ESCAPE )
	{
		if (!key_pressed)
			return true;
		HUD_MinigameMenu_Close(NULL, NULL, NULL);
		return true;
	}

	return false;
}

void HUD_Minigame_Mouse()
{
	if( !HUD_MinigameMenu_IsOpened() || autocvar__hud_configure || mv_active )
		return;

	if ( HUD_MinigameMenu_IsOpened() && HUD_mouse_over(HUD_PANEL(MINIGAMEMENU)) )
		HUD_MinigameMenu_MouseInput();
}
