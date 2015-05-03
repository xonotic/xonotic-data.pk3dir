#include "base.qh"

#ifdef CLASS
#undef CLASS
#undef METHOD
#undef ATTRIB
#undef ATTRIBARRAY
#undef ENDCLASS
#undef SUPER
#endif

#define CLASS(cname, base)                                          \
entity spawn##cname(entity this, entity basevtbl) {                 \
    this = NEW(base); basevtbl = base##_vtbl;                       \
}

#define METHOD(cname, name, prototype)                              \
prototype cname##_##name;                                           \
.prototype name;                                                    \
[[accumulate]] entity spawn##cname(entity this, entity basevtbl) {  \
    this.name = cname##_##name;                                     \
}

#define ATTRIB(cname, name, type, val)                              \
.type name;                                                         \
[[accumulate]] entity spawn##cname(entity this, entity basevtbl) {  \
    this.name = val;                                                \
}

#define ATTRIBARRAY(cname, name, type, cnt)                         \
.type name[cnt];

#define ENDCLASS(cname)                                             \
.bool instanceOf##cname;                                            \
entity cname##_vtbl;                                                \
[[last]] entity spawn##cname(entity this, entity basevtbl) {        \
    this.instanceOf##cname = true;                                  \
    this.classname = #cname;                                        \
    if (!cname##_vtbl) cname##_vtbl = spawnVtbl(this, basevtbl);    \
    return this;                                                    \
}

#define SUPER(cname) (cname##_vtbl.vtblbase)

#ifdef IMPLEMENTATION
#undef IMPLEMENTATION
#endif

#include "../classes.inc"

#ifndef IMPLEMENTATION
#define IMPLEMENTATION
#endif

#include "../classes.inc"
