#include "cl_minigames.qh"

// Draw a square in the center of the avaliable area
void minigame_hud_simpleboard(vector pos, vector mySize, string board_texture)
{
	if(panel.current_panel_bg != "0" && panel.current_panel_bg != "")
		draw_BorderPicture(pos - '1 1 0' * panel_bg_border,
					panel.current_panel_bg,
					mySize + '1 1 0' * 2 * panel_bg_border,
					panel_bg_color, panel_bg_alpha,
					'1 1 0' * BORDER_MULTIPLIER * panel_bg_border);
	drawpic(pos, board_texture, mySize, '1 1 1', panel_bg_alpha, DRAWFLAG_NORMAL);
}

// De-normalize (2D vector) v from relative coordinate inside pos mySize
vector minigame_hud_denormalize(vector v, vector pos, vector mySize)
{
	v_x = pos_x + v_x * mySize_x;
	v_y = pos_y + v_y * mySize_y;
	return v;
}
// De-normalize (2D vector) v from relative size inside pos mySize
vector minigame_hud_denormalize_size(vector v, vector pos, vector mySize)
{
	v_x = v_x * mySize_x;
	v_y = v_y * mySize_y;
	return v;
}

// Normalize (2D vector) v to relative coordinate inside pos mySize
vector minigame_hud_normalize(vector v, vector pos, vector mySize)
{
	v_x = ( v_x - pos_x ) / mySize_x;
	v_y = ( v_y - pos_y ) / mySize_y;
	return v;
}

// Check if the mouse is inside the given area
bool minigame_hud_mouse_in(vector pos, vector sz)
{
	return mousepos_x >= pos_x && mousepos_x < pos_x + sz_x &&
	       mousepos_y >= pos_y && mousepos_y < pos_y + sz_y ;
}

string minigame_texture_skin(string skinname, string name)
{
	return sprintf("gfx/hud/%s/minigames/%s", skinname, name);
}
string minigame_texture(string name)
{
	string path = minigame_texture_skin(autocvar_menu_skin,name);
	if ( precache_pic(path) == "" )
		path = minigame_texture_skin("default", name);
	return path;
}

#define FIELD(Flags, Type, Name) MSLE_CLEAN_##Type(this.Name)
#define MSLE_CLEAN_String(x) strunzone(x);
#define MSLE_CLEAN_Byte(x)
#define MSLE_CLEAN_Char(x)
#define MSLE_CLEAN_Short(x)
#define MSLE_CLEAN_Long(x)
#define MSLE_CLEAN_Coord(x)
#define MSLE_CLEAN_Angle(x)
#define MSLE_CLEAN_Float(x)
#define MSLE_CLEAN_Vector(x)
#define MSLE_CLEAN_Vector2D(x)

#define MSLE(Name,Fields) \
	void msle_entremove_##Name(entity this) { strunzone(this.netname); Fields }
MINIGAME_SIMPLELINKED_ENTITIES
#undef MSLE
#undef FIELD

void minigame_autoclean_entity(entity e)
{
	LOG_DEBUG("CL Auto-cleaned: ",ftos(etof(e)), " (",e.classname,")");
	delete(e);
}

void HUD_MinigameMenu_CurrentButton();
bool auto_close_minigamemenu;
void deactivate_minigame()
{
	if ( !active_minigame )
		return;

	active_minigame.minigame_event(active_minigame,"deactivate");
	entity e = NULL;
	while( (e = findentity(e, owner, active_minigame)) )
		if ( e.minigame_autoclean )
		{
			minigame_autoclean_entity(e);
		}

	minigame_self = NULL;
	active_minigame = NULL;

	if ( auto_close_minigamemenu )
	{
		HUD_MinigameMenu_Close(NULL, NULL, NULL);
		auto_close_minigamemenu = 0;
	}
	else
		HUD_MinigameMenu_CurrentButton();
}

void minigame_entremove(entity this)
{
	if ( this == active_minigame )
		deactivate_minigame();
}

void activate_minigame(entity minigame)
{
	if ( !minigame )
	{
		deactivate_minigame();
		return;
	}

	if ( !minigame.descriptor || minigame.classname != "minigame" )
	{
		LOG_TRACE("Trying to activate unregistered minigame ",minigame.netname," in client");
		return;
	}

	if ( minigame == active_minigame )
		return;

	if ( active_minigame )
	{
		deactivate_minigame();
	}

	if ( minigame_self.owner != minigame )
		minigame_self = NULL;
	active_minigame = minigame;
	active_minigame.minigame_event(active_minigame,"activate");

	if ( HUD_MinigameMenu_IsOpened() )
		HUD_MinigameMenu_CurrentButton();
	else
	{
		auto_close_minigamemenu = 1;
		HUD_MinigameMenu_Open();
	}
}

void minigame_player_entremove(entity this)
{
	if ( this.owner == active_minigame && this.minigame_playerslot == player_localentnum )
		deactivate_minigame();
}

string() ReadString_Raw = #366;
string ReadString_Zoned() { return strzone(ReadString_Raw()); }
#define ReadString ReadString_Zoned
#define FIELD(Flags, Type,Name) if ( sf & (Flags) ) this.Name = Read##Type();
#define MSLE(Name,Fields) \
	else if ( this.classname == #Name ) { \
		if ( sf & MINIG_SF_CREATE ) { \
			minigame_read_owner(this); \
			this.entremove = msle_entremove_##Name; \
		} \
		minigame_ent = this.owner; \
		Fields \
	}
void minigame_read_owner(entity this)
{
	string owner_name = ReadString_Raw();
	this.owner = NULL;
	do
		this.owner = find(this.owner,netname,owner_name);
	while ( this.owner && this.owner.classname != "minigame" );
	if ( !this.owner )
		LOG_TRACE("Got a minigame entity without a minigame!");
}
NET_HANDLE(ENT_CLIENT_MINIGAME, bool isnew)
{
	float sf = ReadByte();
	if ( sf & MINIG_SF_CREATE )
	{
		this.classname = msle_classname(ReadShort());
		this.netname = ReadString_Zoned();
	}

	entity minigame_ent = NULL;

	if ( this.classname == "minigame" )
	{
		minigame_ent = this;

		if ( sf & MINIG_SF_CREATE )
		{
			this.entremove = minigame_entremove;
			this.descriptor = minigame_get_descriptor(ReadString_Raw());
			if ( !this.descriptor )
				LOG_TRACE("Got a minigame without a client-side descriptor!");
			else
				this.minigame_event = this.descriptor.minigame_event;
		}
		if ( sf & MINIG_SF_UPDATE )
			this.minigame_flags = ReadLong();
	}
	else if ( this.classname == "minigame_player" )
	{
		float activate = 0;
		if ( sf & MINIG_SF_CREATE )
		{
			this.entremove = minigame_player_entremove;
			minigame_read_owner(this);
			float ent = ReadLong();
			this.minigame_playerslot = ent;
			LOG_DEBUG("Player: ",entcs_GetName(ent-1));

			activate = (ent == player_localnum+1 && this.owner && this.owner != active_minigame);

		}
		minigame_ent = this.owner;

		if ( sf & MINIG_SF_UPDATE )
			this.team = ReadByte();

		if ( activate )
		{
			minigame_self = this;
			activate_minigame(this.owner);
			minigame_self = this; // set it again (needed before, but may also be reset)
		}
	}
	MINIGAME_SIMPLELINKED_ENTITIES

	if ( minigame_ent )
		minigame_ent.minigame_event(minigame_ent,"network_receive",this,sf);

	if ( sf & MINIG_SF_CREATE )
	{
		LOG_DEBUG("CL Reading entity: ",ftos(etof(this)),
			" classname:",this.classname," enttype:",ftos(this.enttype) );
		LOG_DEBUG(" sf:",ftos(sf)," netname:",this.netname);
	}
	return true;
}
#undef ReadString
#undef FIELD
#undef MSLE

void minigame_show_allspecs(vector boardpos, vector boardsize)
{
	string allspecs = "";
	float allspecs_width = 0;
	float max_allspecs_width = boardsize.x;
	float max_current_spec_width = hud_fontsize.x * 5;
	int allspecs_lines = 2;

	entity e;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if (allspecs_width >= 0 && e.classname == "minigame_player" && e.team == C4_SPECTATOR_TEAM)
		{
			string current_spec = ColorTranslateRGB(entcs_GetName(e.minigame_playerslot - 1));
			current_spec = textShortenToWidth(current_spec, max_current_spec_width, hud_fontsize, stringwidth_colors);
			if (allspecs != "")
				current_spec = strcat(", ", current_spec);
			else
				current_spec = current_spec;

			allspecs_width = stringwidth(allspecs, true, hud_fontsize);

			float max_width = max_allspecs_width * allspecs_lines - max_current_spec_width;
			if (allspecs_width + stringwidth(current_spec, true, hud_fontsize) < max_width)
				allspecs = strcat(allspecs, current_spec);
			else
			{
				// current_spec doesn't fit in the list
				allspecs = strcat(allspecs, ", ...");
				allspecs_width = -1; // skip remaining spectators
			}
		}
	}

	if (allspecs != "")
	{
		vector pos = boardpos;
		pos.y -= panel_bg_border + hud_fontsize.y * (1.25 + allspecs_lines + 0.5);
		minigame_drawstring_wrapped(max_allspecs_width, pos, _("Spectators:"), hud_fontsize * 1.25, '0.85 0.47 0.42', panel_fg_alpha, DRAWFLAG_NORMAL, 0);

		pos.y += hud_fontsize.y * 1.25;
		minigame_drawcolorcodedstring_wrapped(max_allspecs_width, pos, allspecs, hud_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL, 0);
	}
}

string minigame_getWrappedLine(float w, vector theFontSize, textLengthUpToWidth_widthFunction_t tw)
{
	string s = getWrappedLine_remaining;

	if(w <= 0)
	{
		getWrappedLine_remaining = string_null;
		return s; // the line has no size ANYWAY, nothing would be displayed.
	}

	int take_until = textLengthUpToWidth(s, w, theFontSize, tw);

	if ( take_until > strlen(s) )
		take_until = strlen(s);

	int skip = 0;
	for ( int i = 0; i < take_until; ++i )
		if ( substring(s,i,1) == "\n" )
		{
			take_until = i;
			skip = 1;
			break;
		}

	if ( take_until > 0 || skip > 0 )
	{
		if ( skip == 0 && take_until < strlen(s) )
		{
			int last_word = take_until;
			while(last_word > 0 && substring(s, last_word, 1) != " ")
				--last_word;

			if ( last_word != 0 )
			{
				take_until = last_word;
				skip = 1;
			}
		}

		getWrappedLine_remaining = substring(s, take_until+skip, strlen(s) - (take_until+skip));
		if(getWrappedLine_remaining == "")
			getWrappedLine_remaining = string_null;
		else if (tw("^7", theFontSize) == 0)
			getWrappedLine_remaining = strcat(find_last_color_code(substring(s, 0, take_until)), getWrappedLine_remaining);
		return substring(s, 0, take_until);
	}
	else
	{
		getWrappedLine_remaining = string_null;
		return s;
	}
}

vector minigame_drawstring_wrapped( float maxwidth, vector pos, string text,
	vector fontsize, vector color, float theAlpha, int drawflags, float align )
{
	getWrappedLine_remaining = text;
	vector mypos = pos;
	while ( getWrappedLine_remaining )
	{
		string line = minigame_getWrappedLine(maxwidth,fontsize,stringwidth_nocolors);
		if ( line == "" )
			break;
		mypos_x = pos_x + (maxwidth - stringwidth_nocolors(line, fontsize)) * align;
		drawstring(mypos, line, fontsize, color, theAlpha, drawflags);
		mypos_y += fontsize_y;
	}
	mypos_x = maxwidth;
	mypos_y -= pos_y;
	return mypos;
}

vector minigame_drawcolorcodedstring_wrapped( float maxwidth, vector pos,
	string text, vector fontsize, float theAlpha, int drawflags, float align )
{
	getWrappedLine_remaining = text;
	vector mypos = pos;
	while ( getWrappedLine_remaining )
	{
		string line = minigame_getWrappedLine(maxwidth,fontsize,stringwidth_colors);
		if ( line == "" )
			break;
		mypos_x = pos_x + (maxwidth - stringwidth_colors(line, fontsize)) * align;
		drawcolorcodedstring(mypos, line, fontsize, theAlpha, drawflags);
		mypos_y += fontsize_y;
	}
	mypos_x = maxwidth;
	mypos_y -= pos_y;
	return mypos;
}

void minigame_drawstring_trunc(float maxwidth, vector pos, string text,
	vector fontsize, vector color, float theAlpha, int drawflags )
{
	string line = textShortenToWidth(text,maxwidth,fontsize,stringwidth_nocolors);
	drawstring(pos, line, fontsize, color, theAlpha, drawflags);
}

void minigame_drawcolorcodedstring_trunc(float maxwidth, vector pos, string text,
	vector fontsize, float theAlpha, int drawflags )
{
	string line = textShortenToWidth(text,maxwidth,fontsize,stringwidth_colors);
	drawcolorcodedstring(pos, line, fontsize, theAlpha, drawflags);
}

void minigame_drawpic_centered( vector pos, string texture, vector sz,
	vector color, float thealpha, int drawflags )
{
	drawpic( pos-sz/2, texture, sz, color, thealpha, drawflags );
}

// Workaround because otherwise variadic arguments won't work properly
// It could be a bug in the compiler or in darkplaces
void minigame_cmd_workaround(float dummy, string...cmdargc)
{
	string cmd;
	cmd = "cmd minigame ";
	float i;
	for ( i = 0; i < cmdargc; ++i )
		cmd = strcat(cmd,...(i,string));
	localcmd(strcat(cmd,"\n"));
}

// Prompt the player to play in the current minigame
// (ie: it's their turn and they should get back to the minigame)
void minigame_prompt()
{
	if ( active_minigame && ! HUD_MinigameMenu_IsOpened() )
	{
		HUD_Notify_Push(sprintf("minigames/%s/icon_notif",active_minigame.descriptor.netname),
			_("It's your turn"), "");
	}
}

// handle commands etc.
REGISTER_MUTATOR(minigames, true);

MUTATOR_HOOKFUNCTION(minigames, HUD_Command)
{
	if(MUTATOR_RETURNVALUE) { return false; } // command was already handled

	if(argv(1) == "minigame")
	{
		if (isdemo())
			return true; // minigames can't function properly in demo mode
		if (HUD_MinigameMenu_IsOpened())
			HUD_MinigameMenu_Close(NULL, NULL, NULL);
		else
			HUD_MinigameMenu_Open();
		return true;
	}

	return false;
}
