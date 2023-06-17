#include "xonogotchi.qh"
REGISTER_MINIGAME(xonogotchi, _("Xonogotchi"));

// minigame flags
const int XONOGOTCHI_DEAD = 0x0001;

const float XONOGOTCHI_PET_SIZE = 0.25;
const vector XONOGOTCHI_PET_MAXS = '1 1 0' * XONOGOTCHI_PET_SIZE / 2;
const vector XONOGOTCHI_PET_MINS = -XONOGOTCHI_PET_MAXS;
const int XONOGOTCHI_PET_MOVE_LEFT = 0x01;
const int XONOGOTCHI_PET_MOVE_RIGHT = 0x02;

const float XONOGOTCHI_NEST_SIZE = 0.25;
const vector XONOGOTCHI_NEST_MAXS = '1 1 0' * XONOGOTCHI_NEST_SIZE / 2;
const vector XONOGOTCHI_NEST_MINS = -XONOGOTCHI_NEST_MAXS;

const float XONOGOTCHI_BOWL_SIZE = 0.125;
const vector XONOGOTCHI_BOWL_MAXS = '1 1 0' * XONOGOTCHI_BOWL_SIZE / 2;
const vector XONOGOTCHI_BOWL_MINS = -XONOGOTCHI_BOWL_MAXS;
const int XONOGOTCHI_BOWL_FOOD_LEVEL_HIGH = 150;
const int XONOGOTCHI_BOWL_FOOD_LEVEL_MEDIUM = 50;

const int XONOGOTCHI_TILES = 128;
const int XONOGOTCHI_STEPS_PER_SECOND = 32;
const int XONOGOTCHI_STEPS_PER_ANIM = 8;

const float XONOGOTCHI_THINK_DURATION_INITIAL = 0.75;
const float XONOGOTCHI_THINK_DURATION_JITTER = 3;
const float XONOGOTCHI_EAT_DURATION = 1;
const float XONOGOTCHI_SLEEP_DURATION = 2;
const float XONOGOTCHI_TILE_LENGTH = 1 / XONOGOTCHI_TILES;
const float XONOGOTCHI_STEP_DURATION = 1 / XONOGOTCHI_STEPS_PER_SECOND;
const float XONOGOTCHI_ANIM_DURATION = XONOGOTCHI_STEP_DURATION * XONOGOTCHI_STEPS_PER_ANIM;

.entity xonogotchi_pet;
.entity xonogotchi_nest;
.entity xonogotchi_bowl;

.int xonogotchi_pet_movedir;
.float xonogotchi_pet_goal;
.float xonogotchi_pet_level;
.float xonogotchi_pet_health;
.float xonogotchi_pet_hunger;
.float xonogotchi_pet_energy;

.int count;

#ifdef SVQC

void xonogotchi_pet_think(entity this);
void xonogotchi_pet_spawn(entity this)
{
	this.origin = '0.5 0 0';
	this.origin.y += XONOGOTCHI_TILE_LENGTH * 2;
	this.xonogotchi_pet_level = 1;
	this.xonogotchi_pet_health = 100;
	this.xonogotchi_pet_hunger = 100;
	this.xonogotchi_pet_energy = 100;
	setthink(this, xonogotchi_pet_think);
	this.nextthink = time + XONOGOTCHI_THINK_DURATION_INITIAL + XONOGOTCHI_THINK_DURATION_JITTER * random();
	this.SendFlags |= MINIG_SF_UPDATE;
}

void xonogotchi_nest_spawn(entity this)
{
	this.origin = '0.85 0 0';
	this.origin.y += XONOGOTCHI_TILE_LENGTH;
	this.SendFlags |= MINIG_SF_UPDATE;
}

void xonogotchi_bowl_spawn(entity this)
{
	this.origin = '0.15 0 0';
	this.origin.y += XONOGOTCHI_TILE_LENGTH * 2;
	this.count = 250;
	this.SendFlags |= MINIG_SF_UPDATE;
}

void xonogotchi_pet_walkthink(entity this);
void xonogotchi_pet_think(entity this)
{
	entity minigame = this.owner;
	entity bowl = minigame.xonogotchi_bowl;
	float energy_goal = minigame.xonogotchi_nest.origin.x;
	float hunger_goal = minigame.xonogotchi_bowl.origin.x;
	bool want_sleep = (this.xonogotchi_pet_energy < 10);
	bool want_food = !want_sleep && (this.xonogotchi_pet_hunger < 10) && bowl.count;

	setthink(this, xonogotchi_pet_walkthink);
	this.nextthink = time;
	if(!want_sleep && !want_food)
		this.xonogotchi_pet_goal = bound(0 - XONOGOTCHI_PET_MINS.x, floor(random() * XONOGOTCHI_TILES) / XONOGOTCHI_TILES, 1 - XONOGOTCHI_PET_MAXS.x);
	else if(want_sleep)
		this.xonogotchi_pet_goal = energy_goal;
	else
		this.xonogotchi_pet_goal = hunger_goal;

	if(this.xonogotchi_pet_goal < this.origin.x)
		this.xonogotchi_pet_movedir = XONOGOTCHI_PET_MOVE_LEFT;
	else
		this.xonogotchi_pet_movedir = XONOGOTCHI_PET_MOVE_RIGHT;
	this.SendFlags |= MINIG_SF_UPDATE;
}

void xonogotchi_pet_sleepthink(entity this);
void xonogotchi_pet_eatthink(entity this);
void xonogotchi_pet_diethink(entity this);
void xonogotchi_pet_walkthink(entity this)
{
	entity minigame = this.owner;
	entity bowl = minigame.xonogotchi_bowl;
	float energy_goal = minigame.xonogotchi_nest.origin.x;
	float hunger_goal = minigame.xonogotchi_bowl.origin.x;
	bool want_sleep = (this.xonogotchi_pet_energy < 10);
	bool want_food = !want_sleep && (this.xonogotchi_pet_hunger < 10) && bowl.count;

	this.xonogotchi_pet_level += 0.001;

	bool goal_reached = false;
	switch(this.xonogotchi_pet_movedir)
	{
		case XONOGOTCHI_PET_MOVE_LEFT:
			if(this.xonogotchi_pet_goal < this.origin.x)
			{
				this.origin.x = bound(0 - XONOGOTCHI_PET_MINS.x, this.origin.x - XONOGOTCHI_TILE_LENGTH, 1 - XONOGOTCHI_PET_MAXS.x);
			}
			else
			{
				goal_reached = true;
			}
			break;
		case XONOGOTCHI_PET_MOVE_RIGHT:
			if(this.xonogotchi_pet_goal > this.origin.x)
			{
				this.origin.x = bound(0 - XONOGOTCHI_PET_MINS.x, this.origin.x + XONOGOTCHI_TILE_LENGTH, 1 - XONOGOTCHI_PET_MAXS.x);
			}
			else
			{
				goal_reached = true;
			}
			break;
	}

	this.xonogotchi_pet_energy = max(0, this.xonogotchi_pet_energy - random() * 0.025);

	if(want_sleep && (this.xonogotchi_pet_goal != energy_goal))
	{
		goal_reached = false;
		setthink(this, xonogotchi_pet_think);
	}

	if(goal_reached)
		this.xonogotchi_pet_hunger = max(0, this.xonogotchi_pet_hunger - floor(random() * 5));

	if(want_food && (this.xonogotchi_pet_goal != hunger_goal))
	{
		goal_reached = false;
		setthink(this, xonogotchi_pet_think);
	}

	if(goal_reached)
	{
		this.xonogotchi_pet_movedir = 0;

		if(!want_sleep && !want_food)
		{
			setthink(this, xonogotchi_pet_think);
			this.nextthink = time + XONOGOTCHI_THINK_DURATION_JITTER * random();
		}
		else if(want_sleep)
		{
			setthink(this, xonogotchi_pet_sleepthink);
			this.nextthink = time;
		}
		else
		{
			setthink(this, xonogotchi_pet_eatthink);
			this.nextthink = time;
		}
	}
	else
	{
		this.nextthink = time + XONOGOTCHI_STEP_DURATION;
	}

	if(!this.xonogotchi_pet_hunger)
		this.xonogotchi_pet_health = max(0, this.xonogotchi_pet_health - random() * 0.25);

	if(!this.xonogotchi_pet_health)
	{
		minigame.minigame_flags |= XONOGOTCHI_DEAD;
		minigame.SendFlags |= MINIG_SF_UPDATE;
		setthink(this, xonogotchi_pet_diethink);
		this.nextthink = time;
	}

	this.SendFlags |= MINIG_SF_UPDATE;
}

void xonogotchi_pet_sleepthink(entity this)
{
	this.xonogotchi_pet_energy = min(100, this.xonogotchi_pet_energy + 1);
	if(this.xonogotchi_pet_hunger)
		this.xonogotchi_pet_health = min(100, this.xonogotchi_pet_health + random() * 5);

	if(this.xonogotchi_pet_energy == 100)
		setthink(this, xonogotchi_pet_think);

	this.nextthink = time + XONOGOTCHI_SLEEP_DURATION;
	this.SendFlags |= MINIG_SF_UPDATE;
}

void xonogotchi_pet_eatthink(entity this)
{
	entity minigame = this.owner;
	entity bowl = minigame.xonogotchi_bowl;

	if(bowl.count)
	{
		this.xonogotchi_pet_hunger = min(100, this.xonogotchi_pet_hunger + 5);
		bowl.count -= 5;

		if(this.xonogotchi_pet_hunger == 100)
			setthink(this, xonogotchi_pet_think);

		bowl.SendFlags |= MINIG_SF_UPDATE;
	}
	else
	{
		setthink(this, xonogotchi_pet_think);
	}

	this.nextthink = time + XONOGOTCHI_EAT_DURATION;
	this.SendFlags |= MINIG_SF_UPDATE;
}

void xonogotchi_pet_diethink(entity this)
{
}

// required function, handle server side events
int xonogotchi_server_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "start":
		{
			entity pet = msle_spawn(minigame,new(xonogotchi_pet));
			xonogotchi_pet_spawn(pet);

			entity nest = msle_spawn(minigame,new(xonogotchi_nest));
			xonogotchi_nest_spawn(nest);

			entity bowl = msle_spawn(minigame,new(xonogotchi_bowl));
			xonogotchi_bowl_spawn(bowl);

			minigame.xonogotchi_pet = pet;
			minigame.xonogotchi_nest = nest;
			minigame.xonogotchi_bowl = bowl;
			return true;
		}
		case "join":
		{
			return 1;
		}
		case "cmd":
		{
			switch(argv(0))
			{
				case "refill":
					entity bowl = minigame.xonogotchi_bowl;

					bowl.count = 250;
					bowl.SendFlags |= MINIG_SF_UPDATE;
					return true;
				//case "shop":
				//	return true;
			}
			return false;
		}
	}

	return false;
}

#elif defined(CSQC)

const int XONOGOTCHI_PET_ANIM_WALK = 0x01;
const int XONOGOTCHI_PET_ANIM_LEFT = 0x02;
const int XONOGOTCHI_PET_ANIM_RIGHT = 0x04;

.float anim_time;
.int anim_state;

// Required function, draw the game board
void xonogotchi_hud_board(vector pos, vector mySize)
{
	minigame_hud_fitsqare(pos, mySize);
	minigame_hud_simpleboard(pos,mySize,minigame_texture("xonogotchi/board"));

	entity e;
	vector org;
	vector obj_pos;
	vector obj_size;
	FOREACH_MINIGAME_ENTITY(e)
	{
		switch(e.classname)
		{
			case "xonogotchi_nest":
			{
				org = e.origin;
				org.y -= XONOGOTCHI_NEST_MINS.y;
				org.y = 1 - org.y;
				obj_size = minigame_hud_denormalize_size('1 1 0'*XONOGOTCHI_NEST_SIZE,pos,mySize);
				obj_pos = minigame_hud_denormalize(org,pos,mySize);

				minigame_drawpic_centered( obj_pos, minigame_texture("xonogotchi/nest2b"),
						obj_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
				break;
			}
			case "xonogotchi_bowl":
			{
				org = e.origin;
				org.y -= XONOGOTCHI_BOWL_MINS.y;
				org.y = 1 - org.y;
				obj_size = minigame_hud_denormalize_size('1 1 0'*XONOGOTCHI_BOWL_SIZE,pos,mySize);
				obj_pos = minigame_hud_denormalize(org,pos,mySize);

				string food_texture = string_null;
				if(e.count >= XONOGOTCHI_BOWL_FOOD_LEVEL_HIGH)
					food_texture = "xonogotchi/food";
				else if(e.count >= XONOGOTCHI_BOWL_FOOD_LEVEL_MEDIUM)
					food_texture = "xonogotchi/food1";
				else if(e.count)
					food_texture = "xonogotchi/food2";

				if(food_texture)
					minigame_drawpic_centered( obj_pos, minigame_texture(food_texture),
							obj_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
				minigame_drawpic_centered( obj_pos, minigame_texture("xonogotchi/bowl"),
						obj_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
				break;
			}
		}
	}

	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "xonogotchi_pet" )
		{
			if(!e.xonogotchi_pet_health)
				break;

			if(!e.anim_time || time > e.anim_time + XONOGOTCHI_ANIM_DURATION)
			{
				switch(e.xonogotchi_pet_movedir)
				{
					case XONOGOTCHI_PET_MOVE_LEFT:
					case XONOGOTCHI_PET_MOVE_RIGHT:
						e.anim_time = time;
						e.anim_state ^= XONOGOTCHI_PET_ANIM_WALK;
						break;
					default:
						e.anim_time = 0;
						e.anim_state &= ~XONOGOTCHI_PET_ANIM_WALK;
				}
			}

			switch(e.xonogotchi_pet_movedir)
			{
				case XONOGOTCHI_PET_MOVE_LEFT:
					e.anim_state |= XONOGOTCHI_PET_ANIM_LEFT;
					e.anim_state &= ~XONOGOTCHI_PET_ANIM_RIGHT;
					break;
				case XONOGOTCHI_PET_MOVE_RIGHT:
					e.anim_state |= XONOGOTCHI_PET_ANIM_RIGHT;
					e.anim_state &= ~XONOGOTCHI_PET_ANIM_LEFT;
					break;
			}

			string anim_texture;
			if(!(e.anim_state & XONOGOTCHI_PET_ANIM_WALK))
				anim_texture = "xonogotchi/pet";
			else
				anim_texture = "xonogotchi/pet2";

			org = e.origin;
			org.y -= XONOGOTCHI_PET_MINS.y;
			org.y = 1 - org.y;
			obj_size = minigame_hud_denormalize_size('1 1 0'*XONOGOTCHI_PET_SIZE,pos,mySize);
			obj_pos = minigame_hud_denormalize(org,pos,mySize);

			if(e.anim_state & XONOGOTCHI_PET_ANIM_RIGHT)
				anim_texture = strcat(anim_texture, "_r");

			minigame_drawpic_centered( obj_pos, minigame_texture(anim_texture),
					obj_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
		}
	}

	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "xonogotchi_nest" )
		{
			org = e.origin;
			org.y -= XONOGOTCHI_NEST_MINS.y;
			org.y = 1 - org.y;
			obj_size = minigame_hud_denormalize_size('1 1 0'*XONOGOTCHI_NEST_SIZE,pos,mySize);
			obj_pos = minigame_hud_denormalize(org,pos,mySize);

			minigame_drawpic_centered( obj_pos, minigame_texture("xonogotchi/nest2f"),
					obj_size, '1 1 1', panel_fg_alpha, DRAWFLAG_NORMAL );
		}
	}
}

// Required function, draw the game status panel
void xonogotchi_hud_status(vector pos, vector mySize)
{
	HUD_Panel_DrawBg();
	vector ts;
	ts = minigame_drawstring_wrapped(mySize.x,pos,active_minigame.descriptor.message,
		hud_fontsize * 2, '0.25 0.47 0.72', panel_fg_alpha, DRAWFLAG_NORMAL,0.5);
	ts.y += hud_fontsize.y;
	pos.y += ts.y;
	mySize.y -= ts.y;

	vector player_fontsize = hud_fontsize * 1.75;
	ts.y = ( mySize.y - PONG_MAX_PLAYERS*player_fontsize.y ) / 1;
	ts.x = mySize.x;
	vector mypos;

	entity e;
	entity pet = NULL;
	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "xonogotchi_pet" )
			pet = e;
	}

	if(!pet)
		return;

	FOREACH_MINIGAME_ENTITY(e)
	{
		if ( e.classname == "minigame_player" )
		{
			mypos = pos;
			minigame_drawcolorcodedstring_trunc(mySize_x,mypos,
				entcs_GetName(e.minigame_playerslot-1),
				player_fontsize, panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y;

			drawstring(mypos,_("Level"),'28 28 0',
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y;

			drawstring(mypos,sprintf(_("%s"), ftos(floor(pet.xonogotchi_pet_level))),'28 28 0',
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y * 2;

			drawstring(mypos,_("Health"),'28 28 0',
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y;

			drawstring(mypos,sprintf(_("%s%%"), ftos(ceil(pet.xonogotchi_pet_health))),'28 28 0',
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y * 2;

			drawstring(mypos,_("Hunger"),'28 28 0',
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y;

			drawstring(mypos,sprintf(_("%s%%"), ftos(pet.xonogotchi_pet_hunger)),'28 28 0',
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y * 2;

			drawstring(mypos,_("Energy"),'28 28 0',
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);

			mypos_y += player_fontsize_y;

			drawstring(mypos,sprintf(_("%s%%"), ftos(ceil(pet.xonogotchi_pet_energy))),'28 28 0',
					   '0.7 0.84 1', panel_fg_alpha, DRAWFLAG_NORMAL);
		}
	}
}

// convert minigame flags to a message
string xonogotchi_message(int mgflags)
{
	string rmessage = "";
	if (mgflags & XONOGOTCHI_DEAD)
		rmessage = _("Your bird died");
	return rmessage;
}

// Required function, handle client events
int xonogotchi_client_event(entity minigame, string event, ...)
{
	switch(event)
	{
		case "activate":
			return false;
		case "deactivate":
		{
			strfree(minigame.message);
			return false;
		}
		case "network_receive":
		{
			entity sent = ...(0,entity);
			int sf = ...(1,int);
			if ( sent.classname == "minigame" )
			{
				if ( sf & MINIG_SF_UPDATE )
				{
					strcpy(sent.message, xonogotchi_message(sent.minigame_flags));
				}
			}
			return false;
		}
		case "menu_show":
			HUD_MinigameMenu_CustomEntry(...(0,entity),_("Refill Food"),"refill");
			//HUD_MinigameMenu_CustomEntry(...(0,entity),_("Shop"),"shop");
			return false;
		case "menu_click":
			switch(...(0,string))
			{
				case "refill":
					minigame_cmd("refill");
					break;
				//case "shop":
				//	break;
			}
			return false;
	}

	return false;
}

#endif
