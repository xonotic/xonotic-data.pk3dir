#include "playerdemo.qh"
#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
    #include "defs.qh"
    #include "playerdemo.qh"
#endif

.float playerdemo_fh;
.float playerdemo_mode;
.float playerdemo_starttime;
.float playerdemo_time;
const float PLAYERDEMO_MODE_OFF = 0;
const float PLAYERDEMO_MODE_READING = 1;
const float PLAYERDEMO_MODE_WRITING = 2;
void playerdemo_init(entity this)
{
	this.playerdemo_mode = PLAYERDEMO_MODE_OFF;
}
void playerdemo_shutdown(entity this)
{
	if(this.playerdemo_mode != PLAYERDEMO_MODE_OFF)
	{
		LOG_INFO("playerdemo: ", this.netname, " closed\n");
		fclose(this.playerdemo_fh);
	}
	this.playerdemo_mode = 0;
}
void playerdemo_open_read(entity this, string f)
{
	playerdemo_shutdown(this);
	this.playerdemo_mode = PLAYERDEMO_MODE_READING;
	this.playerdemo_fh = fopen(f, FILE_READ);
	this.playerdemo_starttime = time - 1;
	this.playerdemo_time = stof(fgets(this.playerdemo_fh));
	this.playerdemo_time += this.playerdemo_starttime;
	set_movetype(this, MOVETYPE_NONE);
	LOG_INFO("playerdemo: ", this.netname, " reading from ", f, "\n");
}
void playerdemo_open_write(entity this, string f)
{
	playerdemo_shutdown(this);
	this.playerdemo_mode = PLAYERDEMO_MODE_WRITING;
	this.playerdemo_fh = fopen(f, FILE_WRITE);
	this.playerdemo_starttime = time - 1;
	LOG_INFO("playerdemo: ", this.netname, " writing to ", f, "\n");
	LOG_INFO("WARNING: playerdemo file format is incomplete and not stable yet. DO NOT RELY ON IT!\n");
}
#define PLAYERDEMO_FIELD(ent,func,t,f) func##t(ent,f,#f);
#define PLAYERDEMO_FIELDS(ent,func) \
	PLAYERDEMO_FIELD(ent,func,originvector,origin) \
	PLAYERDEMO_FIELD(ent,func,vector,angles) \
	PLAYERDEMO_FIELD(ent,func,sizevector,mins) \
	PLAYERDEMO_FIELD(ent,func,sizevector,maxs) \
	PLAYERDEMO_FIELD(ent,func,vector,v_angle) \
	PLAYERDEMO_FIELD(ent,func,modelstring,model) \
	PLAYERDEMO_FIELD(ent,func,string,playermodel) \
	PLAYERDEMO_FIELD(ent,func,float,skin) \
	PLAYERDEMO_FIELD(ent,func,string,playerskin) \
	PLAYERDEMO_FIELD(ent,func,float,frame) \
	PLAYERDEMO_FIELD(ent,func,float,effects) \
	/* PLAYERDEMO_FIELD(ent,func,float,switchweapon) */ \
	PLAYERDEMO_FIELD(ent,func,float,button0) /* TODO: PHYS_INPUT_BUTTON_ATCK */ \
	PLAYERDEMO_FIELD(ent,func,float,button3) /* TODO: PHYS_INPUT_BUTTON_ATCK2 */ \
	PLAYERDEMO_FIELD(ent,func,float,button5) /* TODO: PHYS_INPUT_BUTTON_CROUCH */ \
	PLAYERDEMO_FIELD(ent,func,float,button6) /* TODO: PHYS_INPUT_BUTTON_HOOK */ \
	PLAYERDEMO_FIELD(ent,func,float,buttonuse) /* TODO: PHYS_INPUT_BUTTON_USE */ \
	PLAYERDEMO_FIELD(ent,func,float,flags) \
	// end of list

void playerdemo_write_originvector(entity this, .vector f, string name)
{
	fputs(this.playerdemo_fh, strcat(vtos(this.(f)), "\n"));
}
void playerdemo_write_sizevector(entity this, .vector f, string name)
{
	fputs(this.playerdemo_fh, strcat(vtos(this.(f)), "\n"));
}
void playerdemo_write_vector(entity this, .vector f, string name)
{
	fputs(this.playerdemo_fh, strcat(vtos(this.(f)), "\n"));
}
void playerdemo_write_string(entity this, .string f, string name)
{
	fputs(this.playerdemo_fh, strcat(this.(f), "\n"));
}
void playerdemo_write_modelstring(entity this, .string f, string name)
{
	fputs(this.playerdemo_fh, strcat(this.(f), "\n"));
}
void playerdemo_write_float(entity this, .float f, string name)
{
	fputs(this.playerdemo_fh, strcat(ftos(this.(f)), "\n"));
}
void playerdemo_write(entity this)
{
	if(this.playerdemo_mode != PLAYERDEMO_MODE_WRITING)
		return;
	fputs(this.playerdemo_fh, strcat(ftos(time - this.playerdemo_starttime), "\n"));
	PLAYERDEMO_FIELDS(this, playerdemo_write_)
}
void playerdemo_read_originvector(entity this, .vector f, string name)
{
	setorigin(this, stov(fgets(this.playerdemo_fh)));
}
void playerdemo_read_sizevector(entity this, .vector f, string name)
{
	this.(f) = stov(fgets(this.playerdemo_fh));
	setsize(this, this.mins, this.maxs);
}
void playerdemo_read_vector(entity this, .vector f, string name)
{
	this.(f) = stov(fgets(this.playerdemo_fh));
}
void playerdemo_read_string(entity this, .string f, string name)
{
	string s = fgets(this.playerdemo_fh);
	if (s != this.(f))
	{
		/*
		if(this.f)
			strunzone(this.f);
		*/
		this.(f) = strzone(s);
	}
}
void playerdemo_read_modelstring(entity this, .string f, string name)
{
	string s = fgets(this.playerdemo_fh);
	if (s != this.(f))
		_setmodel(this, s);
}
void playerdemo_read_float(entity this, .float f, string name)
{
	this.(f) = stof(fgets(this.playerdemo_fh));
}
float playerdemo_read(entity this)
{
	if(this.playerdemo_mode != PLAYERDEMO_MODE_READING)
		return 0;
	if(this.playerdemo_time < 0)
		return 1;
	float t;
	t = time;
	while(time >= this.playerdemo_time)
	{
		PLAYERDEMO_FIELDS(this, playerdemo_read_)
		{
			time = this.playerdemo_time;
			PlayerPreThink(this);
			// not running physics though... this is just so we can run weapon stuff
			PlayerPostThink(this);
		}
		this.playerdemo_time = stof(fgets(this.playerdemo_fh));
		if(this.playerdemo_time == 0)
		{
			this.playerdemo_time = -1;
			return 1;
		}
		this.playerdemo_time += this.playerdemo_starttime;
	}
	this.velocity = '0 0 0';
	time = t;
	return 1;
}
