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
    METHOD(DataSource, getEntry, entity(int i, void(string name, string icon) returns)) { return DataSource_false; }
    /** return the index of the first match for `find`. optional */
    METHOD(DataSource, indexOf, int(string find)) { return -1; }
    /** reload all entries matching `filter` returning how many matches were found */
    METHOD(DataSource, reload, int(string filter)) { return 0; }
    /** cleanup on shutdown. optional */
    METHOD(DataSource, destroy, void(entity)) { }
ENDCLASS(DataSource)
#endif
