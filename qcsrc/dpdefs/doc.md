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

void CSQC_UpdateView(int width, int height);
bool CSQC_ConsoleCommand(string cmd);
bool CSQC_Parse_TempEntity();
bool CSQC_Parse_StuffCmd(string msg);
bool CSQC_Parse_Print(string msg);
bool CSQC_Parse_CenterPrint(string msg);
bool CSQC_Event_Sound(int ent, int channel, string sample, float volume, float attenuation, vector pos, float speed, int flags);

entity CSQC_Ent_Spawn(int entnum);
void CSQC_Ent_Update(bool isnew);
void CSQC_Ent_Remove();

void CSQC_Init();
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

```

# SVQC

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

// input:
//   time
//   self
//   parm1..n
void ClientConnect();

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
