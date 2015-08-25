#ifndef DATASOURCE_H
#define DATASOURCE_H
CLASS(DataSource, Object)
    /**
     * get entry `i` passing `name` and `icon` through `returns` if it is not null
     * returns `DataSource_false` if out of bounds
     * otherwise returns an entity or `DataSource_true`
     */
    METHOD(DataSource, getEntry, entity(int i, void(string name, string icon) returns));
    /** return the index of the first match for `find`. optional */
    METHOD(DataSource, indexOf, int(string find));
    /** reload all entries matching `filter` returning how many matches were found */
    METHOD(DataSource, reload, int(string filter));
    /** cleanup on shutdown. optional */
    METHOD(DataSource, destroy, void(entity));
    entity DataSource_true;
    entity DataSource_false;
    INIT_STATIC(DataSource) {
        DataSource_true = NEW(Object);
        DataSource_false = NULL;
    }
ENDCLASS(DataSource)
#endif
