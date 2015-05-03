#ifndef INTERFACE
#define INTERFACE
#endif

#ifndef IMPLEMENTATION
#define IMPLEMENTATION
#endif

#ifdef CLASS
#undef CLASS
#undef METHOD
#undef ATTRIB
#undef ATTRIBARRAY
#undef ENDCLASS
#undef SUPER
#endif

#define CLASS(cname, base)
#define METHOD(cname, name, prototype)
#define ATTRIB(cname, name, type, val)
#define ATTRIBARRAY(cname, name, type, cnt)
#define ENDCLASS(cname)
#define SUPER(cname) (cname##_vtbl.vtblbase)

#include "../classes.inc"
