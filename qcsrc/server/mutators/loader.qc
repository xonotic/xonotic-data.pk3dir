#include "loader.qh"

STATIC_INIT_LATE(Gametype) {
    Gametype g = MapInfo_CurrentGametype();
    if (g) {
        for (string _s = g.m_mutators; _s != ""; _s = cdr(_s)) {
            string s = car(_s);
            FOREACH(Mutators, it.m_name == s, LAMBDA(Mutator_Add(it); break));
        }
    }
}
