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
	this.movetype = MOVETYPE_NONE;
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
#define PLAYERDEMO_FIELD(func,t,f) func##t(f,#f);
#define PLAYERDEMO_FIELDS(func) \
	PLAYERDEMO_FIELD(func,originvector,origin) \
	PLAYERDEMO_FIELD(func,vector,angles) \
	PLAYERDEMO_FIELD(func,sizevector,mins) \
	PLAYERDEMO_FIELD(func,sizevector,maxs) \
	PLAYERDEMO_FIELD(func,vector,v_angle) \
	PLAYERDEMO_FIELD(func,modelstring,model) \
	PLAYERDEMO_FIELD(func,string,playermodel) \
	PLAYERDEMO_FIELD(func,float,skin) \
	PLAYERDEMO_FIELD(func,string,playerskin) \
	PLAYERDEMO_FIELD(func,float,frame) \
	PLAYERDEMO_FIELD(func,float,effects) \
	/* PLAYERDEMO_FIELD(func,float,switchweapon) */ \
	PLAYERDEMO_FIELD(func,float,button0) /* TODO: PHYS_INPUT_BUTTON_ATCK */ \
	PLAYERDEMO_FIELD(func,float,button3) /* TODO: PHYS_INPUT_BUTTON_ATCK2 */ \
	PLAYERDEMO_FIELD(func,float,button5) /* TODO: PHYS_INPUT_BUTTON_CROUCH */ \
	PLAYERDEMO_FIELD(func,float,button6) /* TODO: PHYS_INPUT_BUTTON_HOOK */ \
	PLAYERDEMO_FIELD(func,float,buttonuse) /* TODO: PHYS_INPUT_BUTTON_USE */ \
	PLAYERDEMO_FIELD(func,float,flags) \
	// end of list

void playerdemo_write_originvector(.vector f, string name)
{SELFPARAM();
	fputs(self.playerdemo_fh, strcat(vtos(self.(f)), "\n"));
}
void playerdemo_write_sizevector(.vector f, string name)
{SELFPARAM();
	fputs(self.playerdemo_fh, strcat(vtos(self.(f)), "\n"));
}
void playerdemo_write_vector(.vector f, string name)
{SELFPARAM();
	fputs(self.playerdemo_fh, strcat(vtos(self.(f)), "\n"));
}
void playerdemo_write_string(.string f, string name)
{SELFPARAM();
	fputs(self.playerdemo_fh, strcat(self.(f), "\n"));
}
void playerdemo_write_modelstring(.string f, string name)
{SELFPARAM();
	fputs(self.playerdemo_fh, strcat(self.(f), "\n"));
}
void playerdemo_write_float(.float f, string name)
{SELFPARAM();
	fputs(self.playerdemo_fh, strcat(ftos(self.(f)), "\n"));
}
void playerdemo_write()
{SELFPARAM();
	if(this.playerdemo_mode != PLAYERDEMO_MODE_WRITING)
		return;
	fputs(this.playerdemo_fh, strcat(ftos(time - this.playerdemo_starttime), "\n"));
	PLAYERDEMO_FIELDS(playerdemo_write_)
}
void playerdemo_read_originvector(.vector f, string name)
{SELFPARAM();
	setorigin(self, stov(fgets(self.playerdemo_fh)));
}
void playerdemo_read_sizevector(.vector f, string name)
{SELFPARAM();
	self.(f) = stov(fgets(self.playerdemo_fh));
	setsize(self, self.mins, self.maxs);
}
void playerdemo_read_vector(.vector f, string name)
{SELFPARAM();
	self.(f) = stov(fgets(self.playerdemo_fh));
}
void playerdemo_read_string(.string f, string name)
{SELFPARAM();
	string s = fgets(self.playerdemo_fh);
	if (s != self.(f))
	{
		/*
		if(self.f)
			strunzone(self.f);
		*/
		self.(f) = strzone(s);
	}
}
void playerdemo_read_modelstring(.string f, string name)
{SELFPARAM();
	string s = fgets(self.playerdemo_fh);
	if (s != self.(f))
		_setmodel(self, s);
}
void playerdemo_read_float(.float f, string name)
{SELFPARAM();
	self.(f) = stof(fgets(self.playerdemo_fh));
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
		PLAYERDEMO_FIELDS(playerdemo_read_)
		{
			time = this.playerdemo_time;
			WITHSELF(this, PlayerPreThink());
			// not running physics though... this is just so we can run weapon stuff
			WITHSELF(this, PlayerPostThink());
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
