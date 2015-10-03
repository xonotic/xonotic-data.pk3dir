#ifndef DATASOURCE_H
#define DATASOURCE_H
CLASS(DataSource, Object)
    entity DataSource_true;
    entity DataSource_false;
    INIT_STATIC(DataSource) {
        DataSource_true = NEW(Object);
        DataSource_false = NULL;
    }
    /**
     * get entry `i` passing `name` and `icon` through `returns` if it is not null
     * returns `DataSource_false` if out of bounds
     * otherwise returns an entity or `DataSource_true`
     */
    METHOD(DataSource, getEntry, entity(entity this, int i, void(string name, string icon) returns)) { return DataSource_false; }
    /** return the index of the first match for `find`. optional */
    METHOD(DataSource, indexOf, int(entity this, string find)) { return -1; }
    /** reload all entries matching `filter` returning how many matches were found */
    METHOD(DataSource, reload, int(entity this, string filter)) { return 0; }
    /** cleanup on shutdown. optional */
    METHOD(DataSource, destroy, void(entity this)) { }
ENDCLASS(DataSource)


CLASS(StringSource, DataSource)
    ATTRIB(StringSource, StringSource_str, string, string_null)
    ATTRIB(StringSource, StringSource_sep, string, string_null)
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
ENDCLASS(StringSource)

CLASS(CvarStringSource, StringSource)
    ATTRIB(CvarStringSource, CvarStringSource_cvar, string, string_null)
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
        return super.getEntry(this, i, returns);
    }
    METHOD(CvarStringSource, reload, int(entity this, string filter))
    {
        string s = this.CvarStringSource_cvar;
        this.StringSource_str = s ? cvar_string(s) : string_null;
        return super.reload(this, filter);
    }
ENDCLASS(CvarStringSource)
#endif
