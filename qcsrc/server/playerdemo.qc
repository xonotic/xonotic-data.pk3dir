#if defined(CSQC)
#elif defined(MENUQC)
#elif defined(SVQC)
	#include "../dpdefs/progsdefs.qh"
    #include "../dpdefs/dpextensions.qh"
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
void playerdemo_init()
{SELFPARAM();
	self.playerdemo_mode = PLAYERDEMO_MODE_OFF;
}
void playerdemo_shutdown()
{SELFPARAM();
	if(self.playerdemo_mode != PLAYERDEMO_MODE_OFF)
	{
		LOG_INFO("playerdemo: ", self.netname, " closed\n");
		fclose(self.playerdemo_fh);
	}
	self.playerdemo_mode = 0;
}
void playerdemo_open_read(string f)
{SELFPARAM();
	playerdemo_shutdown();
	self.playerdemo_mode = PLAYERDEMO_MODE_READING;
	self.playerdemo_fh = fopen(f, FILE_READ);
	self.playerdemo_starttime = time - 1;
	self.playerdemo_time = stof(fgets(self.playerdemo_fh));
	self.playerdemo_time += self.playerdemo_starttime;
	self.movetype = MOVETYPE_NONE;
	LOG_INFO("playerdemo: ", self.netname, " reading from ", f, "\n");
}
void playerdemo_open_write(string f)
{SELFPARAM();
	playerdemo_shutdown();
	self.playerdemo_mode = PLAYERDEMO_MODE_WRITING;
	self.playerdemo_fh = fopen(f, FILE_WRITE);
	self.playerdemo_starttime = time - 1;
	LOG_INFO("playerdemo: ", self.netname, " writing to ", f, "\n");
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
	PLAYERDEMO_FIELD(func,float,switchweapon) \
	PLAYERDEMO_FIELD(func,float,BUTTON_ATCK) \
	PLAYERDEMO_FIELD(func,float,BUTTON_ATCK2) \
	PLAYERDEMO_FIELD(func,float,BUTTON_CROUCH) \
	PLAYERDEMO_FIELD(func,float,BUTTON_HOOK) \
	PLAYERDEMO_FIELD(func,float,BUTTON_USE) \
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
	if(self.playerdemo_mode != PLAYERDEMO_MODE_WRITING)
		return;
	fputs(self.playerdemo_fh, strcat(ftos(time - self.playerdemo_starttime), "\n"));
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
float playerdemo_read()
{SELFPARAM();
	if(self.playerdemo_mode != PLAYERDEMO_MODE_READING)
		return 0;
	if(self.playerdemo_time < 0)
		return 1;
	float t;
	t = time;
	while(time >= self.playerdemo_time)
	{
		PLAYERDEMO_FIELDS(playerdemo_read_)
		{
			time = self.playerdemo_time;
			PlayerPreThink();
			// not running physics though... this is just so we can run weapon stuff
			PlayerPostThink();
		}
		self.playerdemo_time = stof(fgets(self.playerdemo_fh));
		if(self.playerdemo_time == 0)
		{
			self.playerdemo_time = -1;
			return 1;
		}
		self.playerdemo_time += self.playerdemo_starttime;
	}
	self.velocity = '0 0 0';
	time = t;
	return 1;
}
