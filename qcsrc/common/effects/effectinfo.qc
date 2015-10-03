#define EFFECTINFO_PARSER(on) \
    on(airfriction,                                 MY(airfriction) \
    ,{ ASSERT(n == 1 && "airfriction");             MY(airfriction) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(airfriction)) \
    )) \
    on(alpha,                                       MY(alpha_min) ||                    MY(alpha_max) ||                MY(alpha_fade) \
    ,{ ASSERT(n == 3 && "alpha");                   MY(alpha_min) = stof(argv(1));      MY(alpha_max) = stof(argv(2));  MY(alpha_fade) = stof(argv(3)); \
    }, sprintf(" %s %s %s",                         ftos(MY(alpha_min)),                ftos(MY(alpha_max)),            ftos(MY(alpha_fade)) \
    )) \
    on(blend,                                       MY(blend) \
    ,{ ASSERT(n == 1 && "blend");                   MY(blend) = argv(1); \
    }, sprintf(" %s",                               (MY(blend)) \
    )) \
    on(bounce,                                      MY(bounce) \
    ,{ ASSERT(n == 1 && "bounce");                  MY(bounce) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(bounce)) \
    )) \
    on(color,                                       MY(color_min) ||                    MY(color_max) \
    ,{ ASSERT(n == 2 && "color");                   MY(color_min) = argv(1);            MY(color_max) = argv(2); \
    }, sprintf(" %s %s",                            (MY(color_min)),                    (MY(color_max)) \
    )) \
    on(countabsolute,                               MY(countabsolute) \
    ,{ ASSERT(n == 1 && "countabsolute");           MY(countabsolute) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(countabsolute)) \
    )) \
    on(count,                                       MY(count) \
    ,{ ASSERT(n == 1 && "count");                   MY(count) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(count)) \
    )) \
    on(gravity,                                     MY(gravity) \
    ,{ ASSERT(n == 1 && "gravity");                 MY(gravity) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(gravity)) \
    )) \
    on(lightcolor,                                  MY(lightcolor) \
    ,{ ASSERT(n == 3 && "lightcolor");              MY(lightcolor) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(lightcolor)) \
    )) \
    on(lightradiusfade,                             MY(lightradiusfade) \
    ,{ ASSERT(n == 1 && "lightradiusfade");         MY(lightradiusfade) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(lightradiusfade)) \
    )) \
    on(lightradius,                                 MY(lightradius) \
    ,{ ASSERT(n == 1 && "lightradius");             MY(lightradius) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(lightradius)) \
    )) \
    on(lighttime,                                   MY(lighttime) \
    ,{ ASSERT(n == 1 && "lighttime");               MY(lighttime) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(lighttime)) \
    )) \
    on(liquidfriction,                              MY(liquidfriction) \
    ,{ ASSERT(n == 1 && "liquidfriction");          MY(liquidfriction) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(liquidfriction)) \
    )) \
    on(notunderwater,                               MY(notunderwater) \
    ,{ ASSERT(n == 0 && "notunderwater");           MY(notunderwater) = true; \
    }, "" \
    ) \
    on(orientation,                                 MY(orientation) \
    ,{ ASSERT(n == 1 && "orientation");             MY(orientation) = argv(1); \
    }, sprintf(" %s",                               (MY(orientation)) \
    )) \
    on(originjitter,                                MY(originjitter) \
    ,{ ASSERT(n == 3 && "originjitter");            MY(originjitter) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(originjitter)) \
    )) \
    on(originoffset,                                MY(originoffset) \
    ,{ ASSERT(n == 3 && "originoffset");            MY(originoffset) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(originoffset)) \
    )) \
    on(relativeoriginoffset,                        MY(relativeoriginoffset) \
    ,{ ASSERT(n == 3 && "relativeoriginoffset");    MY(relativeoriginoffset) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(relativeoriginoffset)) \
    )) \
    on(relativevelocityoffset,                      MY(relativevelocityoffset) \
    ,{ ASSERT(n == 3 && "relativevelocityoffset");  MY(relativevelocityoffset) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(relativevelocityoffset)) \
    )) \
    on(rotate,                                      MY(startangle_min) ||               MY(startangle_max) ||               MY(spin_min) ||                 MY(spin_max) \
    ,{ ASSERT(n == 4 && "rotate");                  MY(startangle_min) = stof(argv(1)); MY(startangle_max) = stof(argv(2)); MY(spin_min) = stof(argv(3));   MY(spin_max) = stof(argv(4)); \
    }, sprintf(" %s %s %s %s",                      ftos(MY(startangle_min)),           ftos(MY(startangle_max)),           ftos(MY(spin_min)),             ftos(MY(spin_max)) \
    )) \
    on(sizeincrease,                                MY(sizeincrease) \
    ,{ ASSERT(n == 1 && "sizeincrease");            MY(sizeincrease) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(sizeincrease)) \
    )) \
    on(size,                                        MY(size_min) ||                     MY(size_max) \
    ,{ ASSERT(n == 2 && "size");                    MY(size_min) = stof(argv(1));       MY(size_max) = stof(argv(2)); \
    }, sprintf(" %s %s",                            ftos(MY(size_min)),                 ftos(MY(size_max)) \
    )) \
    on(staincolor,                                  MY(staincolor_min) ||               MY(staincolor_max) \
    ,{ ASSERT(n == 2 && "staincolor");              MY(staincolor_min) = argv(1);       MY(staincolor_max) = argv(2); \
    }, sprintf(" %s %s",                            (MY(staincolor_min)),               (MY(staincolor_max)) \
    )) \
    on(stainsize,                                   MY(stainsize_min) ||                MY(stainsize_max) \
    ,{ ASSERT(n == 2 && "stainsize");               MY(stainsize_min) = stof(argv(1));  MY(stainsize_max) = stof(argv(2)); \
    }, sprintf(" %s %s",                            ftos(MY(stainsize_min)),            ftos(MY(stainsize_max)) \
    )) \
    on(staintex,                                    MY(staintex_min) ||                 MY(staintex_max) \
    ,{ ASSERT(n == 2 && "staintex");                MY(staintex_min) = stof(argv(1));   MY(staintex_max) = stof(argv(2)); \
    }, sprintf(" %s %s",                            ftos(MY(staintex_min)),             ftos(MY(staintex_max)) \
    )) \
    on(stretchfactor,                               MY(stretchfactor) \
    ,{ ASSERT(n == 1 && "stretchfactor");           MY(stretchfactor) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(stretchfactor)) \
    )) \
    on(tex,                                         MY(tex_min) ||                      MY(tex_max) \
    ,{ ASSERT(n == 2 && "tex");                     MY(tex_min) = stof(argv(1));        MY(tex_max) = stof(argv(2)); \
    }, sprintf(" %s %s",                            ftos(MY(tex_min)),                  ftos(MY(tex_max)) \
    )) \
    on(time,                                        MY(time_min) ||                     MY(time_max) \
    ,{ ASSERT(n == 2 && "time");                    MY(time_min) = stof(argv(1));       MY(time_max) = stof(argv(2)); \
    }, sprintf(" %s %s",                            ftos(MY(time_min)),                 ftos(MY(time_max)) \
    )) \
    on(trailspacing,                                MY(trailspacing) \
    ,{ ASSERT(n == 1 && "trailspacing");            MY(trailspacing) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(trailspacing)) \
    )) \
    on(type,                                        MY(type) \
    ,{ ASSERT(n == 1 && "type");                    MY(type) = argv(1); \
    }, sprintf(" %s",                               (MY(type)) \
    )) \
    on(underwater,                                  MY(underwater) \
    ,{ ASSERT(n == 0 && "underwater");              MY(underwater) = true; \
    }, "" \
    ) \
    on(velocityjitter,                              MY(velocityjitter) \
    ,{ ASSERT(n == 3 && "velocityjitter");          MY(velocityjitter) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(velocityjitter)) \
    )) \
    on(velocitymultiplier,                          MY(velocitymultiplier) \
    ,{ ASSERT(n == 1 && "velocitymultiplier");      MY(velocitymultiplier) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(velocitymultiplier)) \
    )) \
    on(velocityoffset,                              MY(velocityoffset) \
    ,{ ASSERT(n == 3 && "velocityoffset");          MY(velocityoffset) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(velocityoffset)) \
    )) \
    /**/

CLASS(EffectInfo, Object)
    ATTRIB(EffectInfo, effectinfo_name, string, string_null)
    CONSTRUCTOR(EffectInfo, string s) {
        CONSTRUCT(EffectInfo);
        this.effectinfo_name = s;
    }

    #define FIELDS(MY) \
    MY(airfriction, float, 0) \
    MY(alpha_min, float, 0) \
    MY(alpha_max, float, 0) \
    MY(alpha_fade, float, 0) \
    MY(blend, string, string_null) \
    MY(bounce, float, 0) \
    MY(color_min, string, string_null) \
    MY(color_max, string, string_null) \
    MY(countabsolute, float, 0) \
    MY(count, float, 0) \
    MY(gravity, float, 0) \
    MY(lightcolor, vector, '0 0 0') \
    MY(lightradiusfade, float, 0) \
    MY(lightradius, float, 0) \
    MY(lighttime, float, 0) \
    MY(liquidfriction, float, 0) \
    MY(notunderwater, bool, false) \
    MY(orientation, string, string_null) \
    MY(originjitter, vector, '0 0 0') \
    MY(originoffset, vector, '0 0 0') \
    MY(relativeoriginoffset, vector, '0 0 0') \
    MY(relativevelocityoffset, vector, '0 0 0') \
    MY(startangle_min, float, 0) \
    MY(startangle_max, float, 0) \
    MY(spin_min, float, 0) \
    MY(spin_max, float, 0) \
    MY(sizeincrease, float, 0) \
    MY(size_min, float, 0) \
    MY(size_max, float, 0) \
    MY(staincolor_min, string, string_null) \
    MY(staincolor_max, string, string_null) \
    MY(stainsize_min, float, 0) \
    MY(stainsize_max, float, 0) \
    MY(staintex_min, float, 0) \
    MY(staintex_max, float, 0) \
    MY(stretchfactor, float, 0) \
    MY(tex_min, float, 0) \
    MY(tex_max, float, 0) \
    MY(time_min, float, 0) \
    MY(time_max, float, 0) \
    MY(trailspacing, float, 0) \
    MY(type, string, string_null) \
    MY(underwater, bool, false) \
    MY(velocityjitter, vector, '0 0 0') \
    MY(velocitymultiplier, float, 0) \
    MY(velocityoffset, vector, '0 0 0') \
    /**/

    #define MY(f, type, val) ATTRIB(EffectInfo, effectinfo_##f, type, val)
    FIELDS(MY)
    #undef MY

    METHOD(EffectInfo, describe, string(EffectInfo this)) {
        string s = sprintf("SUB(%s) {\n", this.effectinfo_name);
        #define str_bool(it) (it ? "true" : "false")
        #define str_float(it) ftos(it)
        #define str_vector(it) vtos(it)
        #define str_string(it) strcat("\"", it, "\"")
        #define p(f, type, default) if (this.effectinfo_##f) { s = strcat(s, "\t", "MY("#f") = ", str_##type(this.effectinfo_##f), ";\n"); }
        FIELDS(p)
        #undef p
        #undef MY
        return strcat(s, "}\n");
    }

    METHOD(EffectInfo, dump, string(EffectInfo this)) {
        string s = sprintf("effect %s\n", this.effectinfo_name);
        #define MY(f) this.effectinfo_##f
        #define p(k, isset, parse, unparse) if (isset) { s = strcat(s, "\t", #k, unparse, "\n"); }
        EFFECTINFO_PARSER(p)
        #undef p
        #undef MY
        return s;
    }

    #undef FIELDS
ENDCLASS(EffectInfo)

CLASS(EffectInfoGroup, Object)
    ATTRIBARRAY(EffectInfoGroup, children, EffectInfo, 16)
    ATTRIB(EffectInfoGroup, children_count, int, 0)
ENDCLASS(EffectInfoGroup)

void effectinfo_read()
{
    int fh = fopen("effectinfo.txt", FILE_READ);
    EffectInfo info = NULL;
    for (string line; (line = fgets(fh)); ) {
        int n = tokenize_console(line);
        if (n == 0) continue;
        n--;
        string k = argv(0);
        if (k == "effect") {
            ASSERT(n == 1);
            info = NEW(EffectInfo, argv(1));
            continue;
        }
        ASSERT(info != NULL);
        switch (k) {
            #define MY(f) info.effectinfo_##f
            #define p(k, isset, parse, unparse) case #k: parse break;
            EFFECTINFO_PARSER(p)
            #undef p
            #undef MY
            default:
                LOG_WARNINGF("Unknown property '%s'\n", k);
                break;
        }
    }
    fclose(fh);
}

void effectinfo_dump(int fh, bool alsoprint)
{
    #define WRITE(s) do { \
        fputs(fh, s); \
        if (alsoprint) LOG_INFO(s); \
    } while (0)
    WRITE("// ********************************************** //\n");
    WRITE("// ** WARNING - DO NOT MANUALLY EDIT THIS FILE ** //\n");
    WRITE("// **                                          ** //\n");
    WRITE("// **  This file is automatically generated by ** //\n");
    WRITE("// **  code with the command 'dumpeffectinfo'. ** //\n");
    WRITE("// **                                          ** //\n");
    WRITE("// **  If you modify an effect, please         ** //\n");
    WRITE("// **  regenerate this file with that command. ** //\n");
    WRITE("// **                                          ** //\n");
    WRITE("// ********************************************** //\n");
    WRITE("\n");

    for (EffectInfo it = NULL; (it = findfloat(it, instanceOfEffectInfo, true)); ) {
        if (it.classname == "vtbl") continue;
        string s = it.dump(it);
        WRITE(s);
    }
    #undef WRITE
}


void RegisterEffectInfo();
const int MAX_EFFECTINFOS = 512;
entity EFFECTINFOS[MAX_EFFECTINFOS], EFFECTINFOS_first, EFFECTINFOS_last;
int EFFECTINFOS_COUNT;

#define EFFECTINFO(name) \
    [[accumulate]] void effectinfo_##name(EffectInfoGroup parent, EffectInfo this) { } \
    REGISTER(RegisterEffectInfo, EFFECTINFO, EFFECTINFOS, EFFECTINFOS_COUNT, name, m_id, NEW(EffectInfoGroup)) { \
        effectinfo_##name(this, NULL); \
    }
REGISTER_REGISTRY(RegisterEffectInfo)


#define REGISTER_EFFECTINFO(id) var void effectinfo_##id(EffectInfoGroup parent)

#define MY(f) this.effectinfo_##f
#define DEF(name) EFFECTINFO(name)
#define SUB(name) \
    [[accumulate]] void effectinfo_##name(EffectInfoGroup parent, EffectInfo this) { parent = EFFECTINFO_##name; parent.children[parent.children_count++] = this = NEW(EffectInfo, #name); } \
    [[accumulate]] void effectinfo_##name(EffectInfoGroup parent, EffectInfo this)
#include "effectinfo.inc"
#undef MY
#undef DEF
#undef SUB
