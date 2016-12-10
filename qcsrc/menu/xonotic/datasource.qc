#include "datasource.qh"

    CONSTRUCTOR(StringSource, string str, string sep)
    {
        CONSTRUCT(StringSource);
        this.StringSource_str = str;
        this.StringSource_sep = sep;
    }
    METHOD(StringSource, getEntry, entity(entity this, int i, void(string name, string icon) returns))
    {
        int n = tokenizebyseparator(this.StringSource_str, this.StringSource_sep);
        if (i < 0 || i >= n) return DataSource_false;
        string s = argv(i);
        if (returns) returns(s, string_null);
        return DataSource_true;
    }
    METHOD(StringSource, reload, int(entity this, string filter))
    {
        return tokenizebyseparator(this.StringSource_str, this.StringSource_sep);
    }

    CONSTRUCTOR(CvarStringSource, string cv, string sep)
    {
        CONSTRUCT(CvarStringSource);
        this.CvarStringSource_cvar = cv;
        this.StringSource_sep = sep;
    }
    METHOD(CvarStringSource, getEntry, entity(entity this, int i, void(string name, string icon) returns))
    {
        string s = this.CvarStringSource_cvar;
        this.StringSource_str = s ? cvar_string(s) : string_null;
        return SUPER(CvarStringSource).getEntry(this, i, returns);
    }
    METHOD(CvarStringSource, reload, int(entity this, string filter))
    {
        string s = this.CvarStringSource_cvar;
        this.StringSource_str = s ? cvar_string(s) : string_null;
        return SUPER(CvarStringSource).reload(this, filter);
    }
