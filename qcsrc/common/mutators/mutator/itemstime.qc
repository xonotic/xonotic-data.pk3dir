REGISTER_MUTATOR(itemstime, true);

#ifdef SVQC
void IT_Write(entity e, int i, float f) {
    if (!IS_REAL_CLIENT(e)) return;
    msg_entity = e;
    WriteByte(MSG_ONE, SVC_TEMPENTITY);
    WriteMutator(MSG_ONE, itemstime);
    WriteByte(MSG_ONE, i);
    WriteFloat(MSG_ONE, f);
}
#endif

#ifdef CSQC
MUTATOR_HOOKFUNCTION(itemstime, CSQC_Parse_TempEntity) {
    if (MUTATOR_RETURNVALUE) return false;
    if (!ReadMutatorEquals(mutator_argv_int_0, itemstime)) return false;
    int i = ReadByte();
    float f = ReadFloat();
    ItemsTime_time[i] = f;
    return true;
}
#endif
