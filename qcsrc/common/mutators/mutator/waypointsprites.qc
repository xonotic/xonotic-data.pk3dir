REGISTER_MUTATOR(waypointsprites, true);

#ifdef CSQC
void Ent_WaypointSprite();
MUTATOR_HOOKFUNCTION(waypointsprites, CSQC_Ent_Update) {
    if (MUTATOR_RETURNVALUE) return false;
    if (!ReadMutatorEquals(mutator_argv_int_0, waypointsprites)) return false;
    Ent_WaypointSprite();
    return true;
}
#endif
