#include "rpn.qh"

#include <common/command/command.qh>


// ========================================
//  RPN command code, written by divVerent
//  Last updated: December 28th, 2011
// ========================================

string rpn_pop()
{
	if(rpn_sp > 0) {
		--rpn_sp;
		return rpn_stack[rpn_sp];
	} else {
		LOG_INFO("rpn: stack underflow");
		rpn_error = true;
		return "";
	}
}
void rpn_push(string s)
{
	if(rpn_sp < MAX_RPN_STACK) {
		rpn_stack[rpn_sp] = s;
		++rpn_sp;
	} else {
		LOG_INFO("rpn: stack overflow");
		rpn_error = true;
	}
}
string rpn_get()
{
	if(rpn_sp > 0) {
		return rpn_stack[rpn_sp - 1];
	} else {
		LOG_INFO("rpn: empty stack");
		rpn_error = true;
		return "";
	}
}
void rpn_set(string s)
{
	if(rpn_sp > 0) {
		rpn_stack[rpn_sp - 1] = s;
	} else {
		LOG_INFO("rpn: empty stack");
		rpn_error = true;
	}
}

float rpn_getf() { return stof(rpn_get()); }
float rpn_popf() { return stof(rpn_pop()); }
void rpn_pushf(float f) { return rpn_push(sprintf("%.9g", f)); }
void rpn_setf(float f) { return rpn_set(sprintf("%.9g", f)); }

SHUTDOWN(_rpndb)
{
	if(rpn_db)
		db_close(rpn_db);
}

void GenericCommand_rpn(int request, int argc, string command)
{
	switch(request)
	{
		case CMD_REQUEST_COMMAND:
		{
			float i, j, f, f2, f3, rpnpos;
			//vector rgb;
			string s, s2, rpncmd;

			if(!rpn_db)
			{
				rpn_db = db_create();
				db_put(rpn_db, "stack.pointer", "0");
				db_put(rpn_db, "stack.pos", "-1");
			}

			if(argc >= 2)
			{
				rpn_sp = 0;
				rpn_error = false;
				for(rpnpos = 1; rpnpos < argc; ++rpnpos)
				{
					rpncmd = argv(rpnpos);
					f = strlen(rpncmd);
					if(rpncmd == "") {
					} else if(stof(substring(rpncmd, 0, 1)) > 0) {
						rpn_push(rpncmd);
					} else if(substring(rpncmd, 0, 1) == "0") {
						rpn_push(rpncmd);
					} else if(f >= 2 && substring(rpncmd, 0, 1) == "+") {
						rpn_push(rpncmd);
					} else if(f >= 2 && substring(rpncmd, 0, 1) == "-") {
						rpn_push(rpncmd);
					} else if(f >= 2 && substring(rpncmd, 0, 1) == "/") {
						rpn_push(substring(rpncmd, 1, strlen(rpncmd) - 1));
					} else if(rpncmd == "clear") {
						rpn_sp = 0;
					} else if(rpncmd == "def" || rpncmd == "=") {
						s = rpn_pop();
						s2 = rpn_pop();

						if(s2 != "")
						{
							#ifdef MENUQC
							registercvar(s2, "", 0);
							#else
							registercvar(s2, "");
							#endif
							if(!rpn_error) // don't change cvars if a stack error had happened!
								cvar_set(s2, s);
						}
						else
						{
							LOG_INFO("rpn: empty cvar name for 'def'");
							rpn_error = true;
						}
					} else if(rpncmd == "defs" || rpncmd == "@") {
						s = "";
						i = rpn_popf();
						j = (i == 0);
						while(rpn_sp > 1 && (j || i > 0))
						{
							s = strcat("/", rpn_pop(), " ", s);
							--i;
						}
						s2 = rpn_pop();
						if(s2 != "")
						{
							#ifdef MENUQC
							registercvar(s2, "", 0);
							#else
							registercvar(s2, "");
							#endif
							if(!rpn_error) // don't change cvars if a stack error had happened!
								cvar_set(s2, s);
						}
						else
						{
							LOG_INFO("rpn: empty cvar name for 'defs'");
							rpn_error = true;
						}
					} else if(rpncmd == "load") {
						rpn_set(cvar_string(rpn_get()));
					} else if(rpncmd == "exch") {
						s = rpn_pop();
						s2 = rpn_get();
						rpn_set(s);
						rpn_push(s2);
					} else if(rpncmd == "dup") {
						rpn_push(rpn_get());
					} else if(rpncmd == "pop") {
						rpn_pop();
					} else if(rpncmd == "add" || rpncmd == "+") {
						f = rpn_popf();
						rpn_setf(rpn_getf() + f);
					} else if(rpncmd == "sub" || rpncmd == "-") {
						f = rpn_popf();
						rpn_setf(rpn_getf() - f);
					} else if(rpncmd == "mul" || rpncmd == "*") {
						f = rpn_popf();
						rpn_setf(rpn_getf() * f);
					} else if(rpncmd == "div" || rpncmd == "/") {
						f = rpn_popf();
						rpn_setf(rpn_getf() / f);
					} else if(rpncmd == "mod" || rpncmd == "%") {
						f = rpn_popf();
						f2 = rpn_getf();
						rpn_setf(f2 - f * floor(f2 / f));
					} else if(rpncmd == "pow" || rpncmd == "**") {
						f = rpn_popf();
						rpn_setf(rpn_getf() ** f);
					} else if(rpncmd == "bitand" || rpncmd == "&") {
						f = rpn_popf();
						rpn_setf(rpn_getf() & f);
					} else if(rpncmd == "bitor" || rpncmd == "|") {
						f = rpn_popf();
						rpn_setf(rpn_getf() | f);
					} else if(rpncmd == "bitxor" || rpncmd == "^") {
						f = rpn_popf();
						rpn_setf(rpn_getf() ^ f);
					} else if(rpncmd == "and" || rpncmd == "&&") {
						f = rpn_popf();
						rpn_setf(rpn_getf() && f);
					} else if(rpncmd == "or" || rpncmd == "||") {
						f = rpn_popf();
						rpn_setf(rpn_getf() || f);
					} else if(rpncmd == "xor" || rpncmd == "^^") {
						f = rpn_popf();
						rpn_setf(!rpn_getf() != !f);
					} else if(rpncmd == "bitnot") {
						rpn_setf(~rpn_getf());
					} else if(rpncmd == "not") {
						rpn_setf(!rpn_getf());
					} else if(rpncmd == "abs") {
						rpn_setf(fabs(rpn_getf()));
					} else if(rpncmd == "sgn") {
						f = rpn_getf();
						if(f < 0)
							rpn_set("-1");
						else if(f > 0)
							rpn_set("1");
						else
							rpn_set("0");
					} else if(rpncmd == "neg" || rpncmd == "~") {
						rpn_setf(-rpn_getf());
					} else if(rpncmd == "floor" || rpncmd == "f") {
						rpn_setf(floor(rpn_getf()));
					} else if(rpncmd == "ceil" || rpncmd == "c") {
						rpn_setf(ceil(rpn_getf()));
					} else if(rpncmd == "exp") {
						rpn_setf(exp(rpn_getf()));
					} else if(rpncmd == "log") {
						rpn_setf(log(rpn_getf()));
					} else if(rpncmd == "sin") {
						rpn_setf(sin(rpn_getf()));
					} else if(rpncmd == "cos") {
						rpn_setf(cos(rpn_getf()));
					} else if(rpncmd == "max") {
						f = rpn_popf();
						f2 = rpn_getf();
						rpn_setf(max(f2, f));
					} else if(rpncmd == "min") {
						f = rpn_popf();
						f2 = rpn_getf();
						rpn_setf(min(f2, f));
					} else if(rpncmd == "bound") {
						f = rpn_popf();
						f2 = rpn_popf();
						f3 = rpn_getf();
						rpn_setf(bound(f3, f2, f));
					} else if(rpncmd == "when") {
						f = rpn_popf();
						s = rpn_pop();
						s2 = rpn_get();
						if(f)
							rpn_set(s2);
						else
							rpn_set(s);
					} else if(rpncmd == ">" || rpncmd == "gt") {
						f = rpn_popf();
						rpn_setf(rpn_getf() > f);
					} else if(rpncmd == "<" || rpncmd == "lt") {
						f = rpn_popf();
						rpn_setf(rpn_getf() < f);
					} else if(rpncmd == "==" || rpncmd == "eq") {
						f = rpn_popf();
						rpn_setf(rpn_getf() == f);
					} else if(rpncmd == ">=" || rpncmd == "ge") {
						f = rpn_popf();
						rpn_setf(rpn_getf() >= f);
					} else if(rpncmd == "<=" || rpncmd == "le") {
						f = rpn_popf();
						rpn_setf(rpn_getf() <= f);
					} else if(rpncmd == "!=" || rpncmd == "ne") {
						f = rpn_popf();
						rpn_setf(rpn_getf() != f);
					} else if(rpncmd == "rand") {
						rpn_setf(ceil(random() * rpn_getf()) - 1);
					} else if(rpncmd == "crc16") {
						rpn_setf(crc16(false, rpn_get()));
					} else if(rpncmd == "put") {
						s2 = rpn_pop();
						if (!rpn_error)
						{
							s = rpn_pop();
							if (!rpn_error)
								db_put(rpn_db, s, s2);
						}
					} else if(rpncmd == "get") {
						s = rpn_pop();
						if (!rpn_error)
							rpn_push(db_get(rpn_db, s));
					} else if(rpncmd == "dbpush") {
						s = rpn_pop();
						if(!rpn_error)
						{
							i = stof(db_get(rpn_db, "stack.pointer"));
							db_put(rpn_db, "stack.pointer", ftos(i+1));
							db_put(rpn_db, strcat("stack.", ftos(i)), s);
							if(!i)
								db_put(rpn_db, "stack.pos", "0");
						}
					} else if(rpncmd == "dbpop") {
						i = stof(db_get(rpn_db, "stack.pointer"));
						if(i)
						{
							s = ftos(i-1);
							db_put(rpn_db, "stack.pointer", s);
							rpn_push(db_get(rpn_db, strcat("stack.", s)));
							j = stof(db_get(rpn_db, "stack.pos"));
							if(j >= i)
								db_put(rpn_db, "stack.pos", ftos(i-2));
						} else {
							rpn_error = 1;
							LOG_INFO("rpn: database underflow");
						}
					} else if(rpncmd == "dbget") {

						i = stof(db_get(rpn_db, "stack.pointer"));
						if(i)
						{
							rpn_push(db_get(rpn_db, strcat("stack.", ftos(i-1))));
						} else {
							rpn_error = 1;
							LOG_INFO("rpn: database empty");
						}
					} else if(rpncmd == "dblen") {
						rpn_push(db_get(rpn_db, "stack.pointer"));
					} else if(rpncmd == "dbclr") {
						db_close(rpn_db);
						rpn_db = db_create();
						db_put(rpn_db, "stack.pointer", "0");
						db_put(rpn_db, "stack.pos", "-1");
					} else if(rpncmd == "dbsave") {
						s = rpn_pop();
						if(!rpn_error)
							db_save(rpn_db, s);
					} else if(rpncmd == "dbload") {
						s = rpn_pop();
						if(!rpn_error)
						{
							db_close(rpn_db);
							rpn_db = db_load(s);
						}
					} else if(rpncmd == "dbins") {
						s = rpn_pop();
						if(!rpn_error)
							//if(rpn_sp > 0)
						{
							j = stof(db_get(rpn_db, "stack.pointer"));
							i = stof(db_get(rpn_db, "stack.pos"));

							if(i < 0)
							{
								i = 0;
								db_put(rpn_db, "stack.pos", "0");
							}

							db_put(rpn_db, "stack.pointer", ftos(j+1));
							for(--j; j >= i; --j)
							{
								db_put(rpn_db, strcat("stack.", ftos(j+1)),
											 db_get(rpn_db, (strcat("stack.", ftos(j))))
									);
							}
							db_put(rpn_db, strcat("stack.", ftos(i)), s);
						}
					} else if(rpncmd == "dbext") {
						j = stof(db_get(rpn_db, "stack.pointer"));
						i = stof(db_get(rpn_db, "stack.pos"));
						if(!j)
						{
							rpn_error = true;
							LOG_INFO("rpn: empty database");
						} else {
							--j;
							rpn_push(db_get(rpn_db, strcat("stack.", ftos(i))));
							db_put(rpn_db, "stack.pointer", ftos(j));
							if(i == j)
							{
								db_put(rpn_db, "stack.pos", ftos(j-1));
							} else {
								while(i < j)
								{
									db_put(rpn_db, strcat("stack.", ftos(i)),
												 db_get(rpn_db, (strcat("stack.", ftos(i+1))))
										);
									++i;
								}
							}
						}
					} else if(rpncmd == "dbread") {
						s = db_get(rpn_db, "stack.pos");
						if(stof(s) >= 0)
						{
							rpn_push(db_get(rpn_db, strcat("stack.", s)));
						} else {
							rpn_error = 1;
							LOG_INFO("rpn: empty database");
						}
					} else if(rpncmd == "dbat") {
						rpn_push(db_get(rpn_db, "stack.pos"));
					} else if(rpncmd == "dbmov") {
						j = stof(db_get(rpn_db, "stack.pointer"));
						i = stof(db_get(rpn_db, "stack.pos"));
						i += rpn_popf();
						if(!rpn_error)
						{
							if(i < 0 || i >= j)
							{
								LOG_INFO("rpn: database cursor out of bounds");
								rpn_error = true;
							}
							if(!rpn_error)
							{
								db_put(rpn_db, "stack.pos", ftos(i));
							}
						}
					} else if(rpncmd == "dbgoto") {
						s = rpn_pop();
						j = stof(db_get(rpn_db, "stack.pointer"));
						if(!j)
						{
							rpn_error = true;
							LOG_INFO("rpn: empty database, cannot move cursor");
						}
						if(!rpn_error)
						{
							if(s == "end")
								i = stof(db_get(rpn_db, "stack.pointer"))-1;
							else if(s == "beg")
								i = 0;
							else
								i = stof(s);

							j = stof(db_get(rpn_db, "stack.pointer"));
							if(i < 0 || i >= j)
							{
								LOG_INFO("rpn: database cursor destination out of bounds");
								rpn_error = true;
							}
							if(!rpn_error)
							{
								db_put(rpn_db, "stack.pos", ftos(i));
							}
						}
					} else if(rpncmd == "union") {
						// s s2 union
						s2 = rpn_pop();
						s = rpn_get();
						f = tokenize_console(s);
						f2 = tokenize_console(strcat(s, " ", s2));
						// tokens 0..(f-1) represent s
						// tokens f..f2 represent s2
						// UNION: add all tokens to s that are in s2 but not in s
						s = "";
						for(i = 0; i < f; ++i)
							s = strcat(s, " ", argv(i));
						for(i = f; i < f2; ++i) {
							for(j = 0; j < f; ++j)
								if(argv(i) == argv(j))
									goto skip_union;
							s = strcat(s, " ", argv(i));
LABEL(skip_union)
						}
						if(substring(s, 0, 1) == " ")
							s = substring(s, 1, 99999);
						rpn_set(s);
						tokenize_console(command);
					} else if(rpncmd == "intersection") {
						// s s2 intersection
						s2 = rpn_pop();
						s = rpn_get();
						f = tokenize_console(s);
						f2 = tokenize_console(strcat(s, " ", s2));
						// tokens 0..(f-1) represent s
						// tokens f..f2 represent s2
						// INTERSECTION: keep only the tokens from s that are also in s2
						s = "";
						for(i = 0; i < f; ++i) {
							for(j = f; j < f2; ++j)
								if(argv(i) == argv(j))
								{
									s = strcat(s, " ", argv(i));
									break;
								}
						}
						if(substring(s, 0, 1) == " ")
							s = substring(s, 1, 99999);
						rpn_set(s);
						tokenize_console(command);
					} else if(rpncmd == "difference") {
						// s s2 difference
						s2 = rpn_pop();
						s = rpn_get();
						f = tokenize_console(s);
						f2 = tokenize_console(strcat(s, " ", s2));
						// tokens 0..(f-1) represent s
						// tokens f..f2 represent s2
						// DIFFERENCE: keep only the tokens from s that are not in s2
						s = "";
						for(i = 0; i < f; ++i) {
							for(j = f; j < f2; ++j)
								if(argv(i) == argv(j))
									goto skip_difference;
							s = strcat(s, " ", argv(i));
LABEL(skip_difference)
						}
						if(substring(s, 0, 1) == " ")
							s = substring(s, 1, 99999);
						rpn_set(s);
						tokenize_console(command);
					} else if(rpncmd == "shuffle") {
						// s shuffle
						s = rpn_get();
						f = tokenize_console(s);

						for(i = 0; i < f - 1; ++i) {
							// move a random item from i..f-1 to position i
							s = "";
							f2 = floor(random() * (f - i) + i);
							for(j = 0; j < i; ++j)
								s = strcat(s, " ", argv(j));
							s = strcat(s, " ", argv(f2));
							for(j = i; j < f; ++j)
								if(j != f2)
									s = strcat(s, " ", argv(j));
							f = tokenize_console(s);
						}

						if(substring(s, 0, 1) == " ")
							s = substring(s, 1, 99999);
						rpn_set(s);
						tokenize_console(command);
					} else if(rpncmd == "fexists_assert") {
						s = rpn_pop();
						if(!rpn_error)
						{
							if (!fexists(s))
							{
								LOG_INFO("rpn: ERROR: ", s, " does not exist!");
								rpn_error = true;
							}
						}
					} else if(rpncmd == "fexists") {
						s = rpn_get();
						if(!rpn_error)
						{
							if (fexists(s))
								rpn_setf(1);
							else
								rpn_setf(0);
						}
					} else if(rpncmd == "localtime") {
						rpn_set(strftime(true, rpn_get()));
					} else if(rpncmd == "gmtime") {
						rpn_set(strftime(false, rpn_get()));
					} else if(rpncmd == "time") {
						rpn_pushf(time);
					} else if(rpncmd == "digest") {
						s = rpn_pop();
						rpn_set(digest_hex(s, rpn_get()));
					} else if(rpncmd == "sprintf1s") {
						s = rpn_pop();
						rpn_set(sprintf(s, rpn_get()));
					} else if(rpncmd == "eval") {
						s = rpn_pop();
						command = strcat(s, substring(command, argv_end_index(rpnpos), -1));
						argc = tokenize_console(command);
						rpnpos = -1;
					} else {
						rpn_push(cvar_string(rpncmd));
					}
					if(rpn_error)
						break;
				}
				while(rpn_sp > 0)
				{
					s = rpn_pop();
					LOG_INFO("rpn: still on stack: ", s);
				}
			}

			return;
		}

		default:
		case CMD_REQUEST_USAGE:
		{
			LOG_HELP("Usage:^3 ", GetProgramCommandPrefix(), " rpn <expression>");
			LOG_HELP("  ^2Operations:");
			LOG_HELP("    x pop ----------------------------->     : removes the top");
			LOG_HELP("    x dup -----------------------------> x x : duplicates the top");
			LOG_HELP("    x x exch --------------------------> x x : swap the top two");
			LOG_HELP("    /cvarname load --------------------> x   : loads a cvar");
			LOG_HELP("    /cvarname x def ------------------->     : writes to a cvar");
			LOG_HELP("    f f add|sub|mul|div|mod|pow -------> f   : adds/... two numbers");
			LOG_HELP("    f f and|or|xor|bitand|bitor|bitxor > f   : logical and bitwise operations");
			LOG_HELP("    f f eq|ne|gt|ge|lt|le|max|min -----> f   : compares two numbers");
			LOG_HELP("    f neg|abs|sgn|rand|floor|ceil------> f   : negates/... a number");
			LOG_HELP("    f not|bitnot ----------------------> f   : logical and bitwise negation");
			LOG_HELP("    f exp|log|sin|cos -----------------> f   : exponential function & Co.");
			LOG_HELP("    f f f bound -----------------------> f   : bounds the middle number");
			LOG_HELP("    f1 f2 b when ----------------------> f   : f1 if b, f2 otherwise");
			LOG_HELP("    s s union|intersection|difference -> s   : set operations");
			LOG_HELP("    s shuffle -------------------------> s   : randomly arrange elements");
			LOG_HELP("    /key /value put ------------------->     : set a database key");
			LOG_HELP("    /key get --------------------------> x   : get a database value");
			LOG_HELP("    x dbpush -------------------------->     : pushes the top onto the database");
			LOG_HELP("    dbpop|dbget -----------------------> x   : removes/reads DB's top");
			LOG_HELP("    dblen|dbat ------------------------> f   : gets the DB's size/cursor pos");
			LOG_HELP("    dbclr ----------------------------->     : clear the DB");
			LOG_HELP("    x dbsave|dbload-------------------->     : save/load the DB to/from a file");
			LOG_HELP("    x dbins --------------------------->     : moves the top into the DB");
			LOG_HELP("    dbext|dbread ----------------------> x   : extract/get from the DB's cursor");
			LOG_HELP("    f dbmov|dbgoto -------------------->     : move or set the DB's cursor");
			LOG_HELP("    x localtime -----------------------> x   : formats the current local time");
			LOG_HELP("    x gmtime --------------------------> x   : formats the current UTC time");
			LOG_HELP("    time ------------------------------> f   : seconds since VM start");
			LOG_HELP("    x /MD4 digest ---------------------> x   : MD4 digest");
			LOG_HELP("    x /SHA256 digest ------------------> x   : SHA256 digest");
			LOG_HELP("    x /formatstring sprintf1s ---------> x   : sprintf with 1 string (pad, cut)");
			LOG_HELP("    x fexists -------------------------> f   : checks if a file exists");
			LOG_HELP("    x eval ---------------------------->     : does something eval");
			LOG_HELP("");
			LOG_HELP("  ^2Notes:");
			LOG_HELP("    f: float");
			LOG_HELP("    x: string defined like this: /abc or \"/abc def\"");
			LOG_HELP("    s: string defined like x and containing a set of space-separated strings");
			LOG_HELP("    Unknown tokens insert their cvar value.");
			return;
		}
	}
}
