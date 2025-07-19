# CSQC

```

// input:
//   self
.void() predraw;

// input:
//   time
//   self
.void() think;

// 0 = keydown, key, character (EXT_CSQC)
// 1 = keyup, key, character (EXT_CSQC)
// 2 = mousemove relative, x, y (EXT_CSQC)
// 3 = mousemove absolute, x, y (DP_CSQC)
bool CSQC_InputEvent(int eventtype, int x, int y);

void CSQC_UpdateView(int vid_width, int vid_height, bool notmenu);
// catch commands registered with registercommand
bool CSQC_ConsoleCommand(string cmd);
bool CSQC_Parse_TempEntity();
bool CSQC_Parse_StuffCmd(string msg);
bool CSQC_Parse_Print(string msg);
bool CSQC_Parse_CenterPrint(string msg);
bool CSQC_Event_Sound(int ent, int channel, string sample, float volume, float attenuation, vector pos, float speed, int flags);

entity CSQC_Ent_Spawn(int entnum);
void CSQC_Ent_Update(bool isnew);
void CSQC_Ent_Remove();

void CSQC_Init(float apilevel, string enginename, float engineversion);
void CSQC_Shutdown();

// input:
//   time
//   self
//   v_forward: forward
//   v_right: right
//   v_up: up
// output:
//   origin
//   v_forward: forward
//   v_right: right
//   v_up: up
//   trace_endpos: visorigin
.vector camera_transform(vector pos, vector ang);

// control start position of sound()
// calculated as ofs = time - sound_starttime
float sound_starttime;

```

# SVQC

Main loop:
* SV_Physics()
    * StartFrame()
    * if (force_retouch)
        * foreach entity:
            * .touch()
    * foreach client:
        * PlayerPreThink()
        * .think()
        * PlayerPostThink()
    * foreach nonclient:
        * .think()
    * EndFrame()


```

.entity clientcamera;

// input:
//   time
//   self
void ClientDisconnect();

// input:
//   time
void SV_Shutdown();

// input:
//   time
void SV_PausedTic(float elapsed);

// input:
//   time
//   self
void SV_ChangeTeam(int color);

// input:
//   time
//   self
void ClientKill();

// input:
//   time
//   self
void RestoreGame();

// Called when a client connects to the server
// input:
//   time
//   self
//   parm1..n
void ClientConnect();

// Called when a client spawns in the server
// input:
//   time
//   self
//   parm1..n
void PutClientInServer();

// return false to remove
.bool SendEntity(entity to, int sf);

// input:
//   time
//   self
void SV_OnEntityPreSpawnFunction();

// input:
//   time
//   self
void SV_OnEntityNoSpawnFunction();

// input:
//   time
//   self
void SV_OnEntityPostSpawnFunction();

// input:
//   time
// output:
//   parm1..n
void SetNewParms();

// Runs every frame
// input:
//
.bool customizeentityforclient();

// input:
//   time
//   self
// output:
//   parm1..n
void SetChangeParms();

// input:
//   time
//   self
//   other
//   trace_allsolid
//   trace_startsolid
//   trace_fraction
//   trace_inwater
//   trace_inopen
//   trace_endpos: self.origin
//   trace_plane_normal
//   trace_plane_dist
//   trace_ent: other
//   trace_dpstartcontents
//   trace_dphitcontents
//   trace_dphitq3surfaceflags
//   trace_dphittexturename
.void touch();

// when .watertype changes:
.void contentstransition(int prev, int current);

// input:
//   time
//   self
//   other
.void blocked();

// input:
//   time
//   self
.void movetypesteplandevent(vector vel);

// input:
//   time
//   self
void PlayerPreThink();

// input:
//   time
//   self
void PlayerPostThink();

// input:
//   time
//   frametime
void StartFrame();

// input:
//   time
void EndFrame();

// input:
//   time
//   self
void SV_PlayerPhysics();

// input:
//   time
//   self
void SV_ParseClientCommand(string cmd);

// qcstatus server field
string worldstatus;
.string clientstatus;

```

# MENUQC

```

void m_keydown(int key, int ascii);

void m_keyup(int key, int ascii);

void m_draw(int width, int height);

void m_toggle(int mode);

int m_gethostcachecategory(int entry);

void m_shutdown();

void m_init();

```

# All

```

void URI_Get_Callback(int id, int status, string data);

void GameCommand(string cmd);

```

# Misc

## Trace

### tracebox

    void tracebox(vector v1, vector min, vector max, vector v2, int tryents, entity ignoreentity);

attempt to move an object from v1 to v2 of given size

tryents:
 * MOVE_NORMAL (0)
 * MOVE_NOMONSTERS (1): ignore monsters
 * MOVE_MISSILE (2): +15 to every extent
 * MOVE_WORLDONLY (3): ignore everything except bsp
 * MOVE_HITMODEL (4): hit model, not bbox

### traceline

    void traceline(vector v1, vector v2, int tryents, entity ignoreentity);

degenerate case of tracebox when min and max are equal

### result globals

    bool trace_allsolid;

trace never left solid

    bool trace_startsolid;

trace started inside solid

    float trace_fraction;

distance before collision: 0..1, 1 if no collision

    vector trace_endpos;

v1 + (v2 - v1) * trace_fraction

    vector trace_plane_normal;

normalized plane normal, '0 0 0' if no collision.
May be present if edges touch without clipping, use `trace_fraction < 1` as a determinant instead

    float trace_plane_dist;



    entity trace_ent;

entity hit, if any

    bool trace_inopen;



    bool trace_inwater;



    int trace_dpstartcontents;

DPCONTENTS_ value at start position of trace

    int trace_dphitcontents;

DPCONTENTS_ value of impacted surface (not contents at impact point, just contents of the surface that was hit)

    int trace_dphitq3surfaceflags;

Q3SURFACEFLAG_ value of impacted surface

    string trace_dphittexturename;

texture name of impacted surface

    int trace_networkentity;


