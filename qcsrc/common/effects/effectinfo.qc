#if ENABLE_EFFECTINFO

#include "effectinfo.qh"
#define EFFECTINFO_PARSER(on, MY) \
    on(type,                                        MY(type) \
    ,{ demand(n == 1 && "type");                    MY(type) = strzone(argv(1)); \
    }, sprintf(" %s",                               (MY(type)) \
    )) \
    on(airfriction,                                 MY(airfriction) \
    ,{ demand(n == 1 && "airfriction");             MY(airfriction) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(airfriction)) \
    )) \
    on(alpha,                                       MY(alpha_min) ||                    MY(alpha_max) ||                MY(alpha_fade) \
    ,{ demand(n == 3 && "alpha");                   MY(alpha_min) = stof(argv(1));      MY(alpha_max) = stof(argv(2));  MY(alpha_fade) = stof(argv(3)); \
    }, sprintf(" %s %s %s",                         ftos(MY(alpha_min)),                ftos(MY(alpha_max)),            ftos(MY(alpha_fade)) \
    )) \
    on(blend,                                       MY(blend) \
    ,{ demand(n == 1 && "blend");                   MY(blend) = strzone(argv(1)); \
    }, sprintf(" %s",                               (MY(blend)) \
    )) \
    on(bounce,                                      MY(bounce) \
    ,{ demand(n == 1 && "bounce");                  MY(bounce) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(bounce)) \
    )) \
    on(color,                                       MY(color_min) ||                    MY(color_max) \
    ,{ demand(n == 2 && "color");                   MY(color_min) = strzone(argv(1));   MY(color_max) = strzone(argv(2)); \
    }, sprintf(" %s %s",                            (MY(color_min)),                    (MY(color_max)) \
    )) \
    on(countabsolute,                               MY(countabsolute) \
    ,{ demand(n == 1 && "countabsolute");           MY(countabsolute) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(countabsolute)) \
    )) \
    on(count,                                       MY(count) \
    ,{ demand(n == 1 && "count");                   MY(count) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(count)) \
    )) \
    on(gravity,                                     MY(gravity) \
    ,{ demand(n == 1 && "gravity");                 MY(gravity) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(gravity)) \
    )) \
    on(lightcolor,                                  MY(lightcolor) \
    ,{ demand(n == 3 && "lightcolor");              MY(lightcolor) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(lightcolor)) \
    )) \
    on(lightradiusfade,                             MY(lightradiusfade) \
    ,{ demand(n == 1 && "lightradiusfade");         MY(lightradiusfade) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(lightradiusfade)) \
    )) \
    on(lightradius,                                 MY(lightradius) \
    ,{ demand(n == 1 && "lightradius");             MY(lightradius) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(lightradius)) \
    )) \
    on(lighttime,                                   MY(lighttime) \
    ,{ demand(n == 1 && "lighttime");               MY(lighttime) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(lighttime)) \
    )) \
    on(liquidfriction,                              MY(liquidfriction) \
    ,{ demand(n == 1 && "liquidfriction");          MY(liquidfriction) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(liquidfriction)) \
    )) \
    on(notunderwater,                               MY(notunderwater) \
    ,{ demand(n == 0 && "notunderwater");           MY(notunderwater) = true; \
    }, "" \
    ) \
    on(orientation,                                 MY(orientation) \
    ,{ demand(n == 1 && "orientation");             MY(orientation) = strzone(argv(1)); \
    }, sprintf(" %s",                               (MY(orientation)) \
    )) \
    on(originjitter,                                MY(originjitter) \
    ,{ demand(n == 3 && "originjitter");            MY(originjitter) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(originjitter)) \
    )) \
    on(originoffset,                                MY(originoffset) \
    ,{ demand(n == 3 && "originoffset");            MY(originoffset) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(originoffset)) \
    )) \
    on(relativeoriginoffset,                        MY(relativeoriginoffset) \
    ,{ demand(n == 3 && "relativeoriginoffset");    MY(relativeoriginoffset) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(relativeoriginoffset)) \
    )) \
    on(relativevelocityoffset,                      MY(relativevelocityoffset) \
    ,{ demand(n == 3 && "relativevelocityoffset");  MY(relativevelocityoffset) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(relativevelocityoffset)) \
    )) \
    on(rotate,                                      MY(startangle_min) ||               MY(startangle_max) ||               MY(spin_min) ||                 MY(spin_max) \
    ,{ demand(n == 4 && "rotate");                  MY(startangle_min) = stof(argv(1)); MY(startangle_max) = stof(argv(2)); MY(spin_min) = stof(argv(3));   MY(spin_max) = stof(argv(4)); \
    }, sprintf(" %s %s %s %s",                      ftos(MY(startangle_min)),           ftos(MY(startangle_max)),           ftos(MY(spin_min)),             ftos(MY(spin_max)) \
    )) \
    on(sizeincrease,                                MY(sizeincrease) \
    ,{ demand(n == 1 && "sizeincrease");            MY(sizeincrease) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(sizeincrease)) \
    )) \
    on(size,                                        MY(size_min) ||                     MY(size_max) \
    ,{ demand(n == 2 && "size");                    MY(size_min) = stof(argv(1));       MY(size_max) = stof(argv(2)); \
    }, sprintf(" %s %s",                            ftos(MY(size_min)),                 ftos(MY(size_max)) \
    )) \
    on(staincolor,                                  MY(staincolor_min) ||                   MY(staincolor_max) \
    ,{ demand(n == 2 && "staincolor");              MY(staincolor_min) = strzone(argv(1));  MY(staincolor_max) = strzone(argv(2)); \
    }, sprintf(" %s %s",                            (MY(staincolor_min)),                   (MY(staincolor_max)) \
    )) \
    on(stainsize,                                   MY(stainsize_min) ||                MY(stainsize_max) \
    ,{ demand(n == 2 && "stainsize");               MY(stainsize_min) = stof(argv(1));  MY(stainsize_max) = stof(argv(2)); \
    }, sprintf(" %s %s",                            ftos(MY(stainsize_min)),            ftos(MY(stainsize_max)) \
    )) \
    on(staintex,                                    MY(staintex_min) ||                 MY(staintex_max) \
    ,{ demand(n == 2 && "staintex");                MY(staintex_min) = stof(argv(1));   MY(staintex_max) = stof(argv(2)); \
    }, sprintf(" %s %s",                            ftos(MY(staintex_min)),             ftos(MY(staintex_max)) \
    )) \
    on(stretchfactor,                               MY(stretchfactor) \
    ,{ demand(n == 1 && "stretchfactor");           MY(stretchfactor) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(stretchfactor)) \
    )) \
    on(tex,                                         MY(tex_min) ||                      MY(tex_max) \
    ,{ demand(n == 2 && "tex");                     MY(tex_min) = stof(argv(1));        MY(tex_max) = stof(argv(2)); \
    }, sprintf(" %s %s",                            ftos(MY(tex_min)),                  ftos(MY(tex_max)) \
    )) \
    on(time,                                        MY(time_min) ||                     MY(time_max) \
    ,{ demand(n == 2 && "time");                    MY(time_min) = stof(argv(1));       MY(time_max) = stof(argv(2)); \
    }, sprintf(" %s %s",                            ftos(MY(time_min)),                 ftos(MY(time_max)) \
    )) \
    on(trailspacing,                                MY(trailspacing) \
    ,{ demand(n == 1 && "trailspacing");            MY(trailspacing) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(trailspacing)) \
    )) \
    on(underwater,                                  MY(underwater) \
    ,{ demand(n == 0 && "underwater");              MY(underwater) = true; \
    }, "" \
    ) \
    on(velocityjitter,                              MY(velocityjitter) \
    ,{ demand(n == 3 && "velocityjitter");          MY(velocityjitter) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(velocityjitter)) \
    )) \
    on(velocitymultiplier,                          MY(velocitymultiplier) \
    ,{ demand(n == 1 && "velocitymultiplier");      MY(velocitymultiplier) = stof(argv(1)); \
    }, sprintf(" %s",                               ftos(MY(velocitymultiplier)) \
    )) \
    on(velocityoffset,                              MY(velocityoffset) \
    ,{ demand(n == 3 && "velocityoffset");          MY(velocityoffset) = vec3(stof(argv(1)), stof(argv(2)), stof(argv(3))); \
    }, sprintf(" %v",                               (MY(velocityoffset)) \
    )) \
    /**/

CLASS(EffectInfo, Object)
    ATTRIB(EffectInfo, effectinfo_name, string);
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

    #define MY(f, type, val) ATTRIB(EffectInfo, effectinfo_##f, type, val);
    FIELDS(MY)
    #undef MY

    METHOD(EffectInfo, describe, string(EffectInfo this))
    {
        TC(EffectInfo, this);
        string s = sprintf("SUB(%s) {\n", this.effectinfo_name);
        #define str_bool(it) (it ? "true" : "false")
        #define str_float(it) ftos(it)
        #define str_vector(it) vtos(it)
        #define str_string(it) strcat("\"", it, "\"")
        #define p(f, type, default) if (this.effectinfo_##f) { s = strcat(s, "\t", "MY("#f") = ", str_##type(this.effectinfo_##f), ";\n"); }
        FIELDS(p)
        #undef p
        return strcat(s, "}\n");
    }

    METHOD(EffectInfo, dump, string(EffectInfo this))
    {
        TC(EffectInfo, this);
        string s = sprintf("effect %s\n", this.effectinfo_name);
        #define MY(f) this.effectinfo_##f
        #define p(k, isset, parse, unparse) if (isset) { s = strcat(s, "\t", #k, unparse, "\n"); }
        EFFECTINFO_PARSER(p, MY)
        #undef p
        #undef MY
        return s;
    }

    #undef FIELDS
ENDCLASS(EffectInfo)

CLASS(EffectInfoGroup, Object)
    ATTRIBARRAY(EffectInfoGroup, children, EffectInfo, 16);
    ATTRIB(EffectInfoGroup, children_count, int, 0);
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
            demand(n == 1);
            info = NEW(EffectInfo, strzone(argv(1)));
            continue;
        }
        demand(info != NULL);
        switch (k) {
            #define MY(f) info.effectinfo_##f
            #define p(k, isset, parse, unparse) case #k: parse break;
            EFFECTINFO_PARSER(p, MY)
            #undef p
            #undef MY
            default:
                LOG_WARNF("Unknown property '%s'", k);
                break;
        }
    }
    fclose(fh);
}

void effectinfo_dump(int fh, bool alsoprint)
{
	#define WRITE(str) write_String_To_File(fh, str, alsoprint)
	WRITE(
		"// ********************************************** //\n"
		"// ** WARNING - DO NOT MANUALLY EDIT THIS FILE ** //\n"
		"// **                                          ** //\n"
		"// **  This file is automatically generated by ** //\n"
		"// **  code with the command 'dumpeffectinfo'. ** //\n"
		"// **                                          ** //\n"
		"// **  If you modify an effect, please         ** //\n"
		"// **  regenerate this file with that command. ** //\n"
		"// **                                          ** //\n"
		"// ********************************************** //\n"
		"\n");

    for (EffectInfo it = NULL; (it = findfloat(it, instanceOfEffectInfo, true)); ) {
        if (it.classname == "vtbl") continue;
        string s = it.dump(it);
        WRITE(s);
    }
    #undef WRITE
}

#define DEFAULT_FILENAME "effectinfo_dump.txt"
// NOTE: dumpeffectinfo, dumpnotifs, dumpturrets and dumpweapons use similar code
GENERIC_COMMAND(dumpeffectinfo, "Dump all effectinfo into " DEFAULT_FILENAME, false)
{
    switch (request) {
        case CMD_REQUEST_COMMAND: {
            string filename = argv(1);
			bool alsoprint = false;
            if (filename == "") {
                filename = DEFAULT_FILENAME;
                alsoprint = false;
            } else if (filename == "-") {
                filename = DEFAULT_FILENAME;
                alsoprint = true;
            }
            int fh = fopen(filename, FILE_WRITE);
            if (fh >= 0) {
            	effectinfo_dump(fh, alsoprint);
                LOG_INFOF("Dumping effectinfo... File located at ^2data/data/%s^7.", filename);
				LOG_INFOF("Reload with ^2cl_particles_reloadeffects data/%s^7.", filename);
                fclose(fh);
            } else {
                LOG_WARNF("Could not open file '%s'!", filename);
            }
            return;
        }
        default:
        case CMD_REQUEST_USAGE: {
            LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " dumpeffectinfo [<filename>]");
            LOG_HELPF("  Where <filename> is the file to write (default is %s),", DEFAULT_FILENAME);
            LOG_HELP("  if supplied with '-' output to console as well as default,");
            LOG_HELP("  if left blank, it will only write to default.");
            return;
        }
    }
}
#undef DEFAULT_FILENAME


REGISTRY(EffectInfos, BITS(9))
REGISTER_REGISTRY(EffectInfos)

REGISTRY_DEFINE_GET(EffectInfos, NULL)
#define EFFECTINFO(name) \
    ACCUMULATE void effectinfo_##name(EffectInfoGroup parent, EffectInfo this) { } \
    REGISTER(EffectInfos, EFFECTINFO, name, m_id, NEW(EffectInfoGroup)) { \
        effectinfo_##name(this, NULL); \
    }

#define MY(f) this.effectinfo_##f
#define DEF(name) EFFECTINFO(name)
#define SUB(name) \
    ACCUMULATE void effectinfo_##name(EffectInfoGroup parent, EffectInfo this) { parent = EFFECTINFO_##name; parent.children[parent.children_count++] = this = NEW(EffectInfo, #name); } \
    ACCUMULATE void effectinfo_##name(EffectInfoGroup parent, EffectInfo this)
#include "effectinfo.inc"
#undef MY
#undef DEF
#undef SUB

#endif
