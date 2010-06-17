#ifndef INTERFACE
#define INTERFACE
#endif

#ifdef IMPLEMENTATION
#undef IMPLEMENTATION
#endif

#ifdef CLASS
#undef CLASS
#undef EXTENDS
#undef METHOD
#undef ATTRIB
#undef ATTRIBARRAY
#undef ENDCLASS
#undef SUPER
#endif

#define CLASS(cname)                       entity spawn##cname() { entity me;
#define EXTENDS(base)                      me = spawn##base (); entity basevtbl; basevtbl = base##_vtbl;
#define METHOD(cname,name,prototype)       me.name = cname##_##name;
#define ATTRIB(cname,name,type,val)        me.name = val;
#define ATTRIBARRAY(cname,name,type,cnt)   me.name = me.name;
#define ENDCLASS(cname)                    me.instanceOf##cname = 1; me.classname = #cname; if(!cname##_vtbl) cname##_vtbl = spawnVtbl(me, basevtbl); return me; }
#define SUPER(cname)
