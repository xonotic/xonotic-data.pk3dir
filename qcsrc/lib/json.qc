#include "test.qh"

STRING_ITERATOR(_json, string_null, 0);
// Store interleaved keys/values in a string buffer
int _json_buffer;
// Last read string
string _json_temp;

/** parse a json object */
bool _json_parse_object();
    bool _json_parse_members();
        bool _json_parse_pair();
bool _json_parse_array();
bool _json_parse_value();
    bool _json_parse_true();
    bool _json_parse_false();
    bool _json_parse_null();
bool _json_parse_string(bool add);
bool _json_parse_number();
    bool _json_parse_float();
    bool _json_parse_int();

#define JSON_BEGIN() int __i = STRING_ITERATOR_SAVE(_json)
#define JSON_FAIL(reason) goto fail
#define JSON_END() \
   return true; \
:fail \
   STRING_ITERATOR_LOAD(_json, __i); \
   return false;
// Current namespace
string _json_ns;
// Current keys
int _json_keys;

ERASEABLE
bool _json_parse_object() {
    JSON_BEGIN();
    if (STRING_ITERATOR_GET(_json) != '{') JSON_FAIL("expected '{'");
    WITH(int, _json_keys, bufstr_add(_json_buffer, "", 0), _json_parse_members());
    if (STRING_ITERATOR_GET(_json) != '}') JSON_FAIL("expected '}'");
    JSON_END();
}

    ERASEABLE
    bool _json_parse_members() {
        JSON_BEGIN();
        for (;;) {
            if (!_json_parse_pair()) JSON_FAIL("expected pair");
            if (STRING_ITERATOR_PEEK(_json) == ',') {
                STRING_ITERATOR_NEXT(_json);
                continue;
            }
            break;
        }
        JSON_END();
    }

        ERASEABLE
        bool _json_parse_pair() {
            JSON_BEGIN();
            if (!_json_parse_string(false)) JSON_FAIL("expected string");
            string key = _json_temp;
            bufstr_set(_json_buffer, _json_keys, cons(bufstr_get(_json_buffer, _json_keys), key));
            key = _json_ns ? strcat(_json_ns, ".", key) : key;
            bufstr_add(_json_buffer, key, 0);
            if (STRING_ITERATOR_GET(_json) != ':') JSON_FAIL("expected ':'");
            bool ret = false; WITH(string, _json_ns, key, ret = _json_parse_value());
            if (!ret) JSON_FAIL("expected value");
            JSON_END();
        }

ERASEABLE
bool _json_parse_array() {
    JSON_BEGIN();
    if (STRING_ITERATOR_GET(_json) != '[') JSON_FAIL("expected '['");
    int len = bufstr_add(_json_buffer, "0", 0);
    if (len) bufstr_set(_json_buffer, len - 1, strcat(bufstr_get(_json_buffer, len - 1), ".length"));
    bool required = false;
    for (int n = 0; ; ++n) {
        string key = ftos(n);
        key = _json_ns ? strcat(_json_ns, ".", key) : key;
        int it = bufstr_add(_json_buffer, key, 0);
        bool ret = false; WITH(string, _json_ns, key, ret = _json_parse_value());
        if (!ret) {
            bufstr_free(_json_buffer, it);
            if (required) JSON_FAIL("expected value"); else break;
        }
        bufstr_set(_json_buffer, len, ftos(n + 1));
        if (STRING_ITERATOR_PEEK(_json) == ',') {
            STRING_ITERATOR_NEXT(_json);
            required = true;
            continue;
        }
        break;
    }
    if (STRING_ITERATOR_GET(_json) != ']') JSON_FAIL("expected ']'");
    JSON_END();
}

ERASEABLE
bool _json_parse_value() {
    JSON_BEGIN();
    if (!(_json_parse_string(true)
        || _json_parse_number()
        || _json_parse_object()
        || _json_parse_array()
        || _json_parse_true()
        || _json_parse_false()
        || _json_parse_null())) JSON_FAIL("expected value");
    JSON_END();
}

    ERASEABLE
    bool _json_parse_true() {
        JSON_BEGIN();
        if (!(STRING_ITERATOR_GET(_json) == 't'
            && STRING_ITERATOR_GET(_json) == 'r'
            && STRING_ITERATOR_GET(_json) == 'u'
            && STRING_ITERATOR_GET(_json) == 'e'))
            JSON_FAIL("expected 'true'");
        bufstr_add(_json_buffer, "1", 0);
        JSON_END();
    }

    ERASEABLE
    bool _json_parse_false() {
        JSON_BEGIN();
        if (!(STRING_ITERATOR_GET(_json) == 'f'
            && STRING_ITERATOR_GET(_json) == 'a'
            && STRING_ITERATOR_GET(_json) == 'l'
            && STRING_ITERATOR_GET(_json) == 's'
            && STRING_ITERATOR_GET(_json) == 'e'))
            JSON_FAIL("expected 'false'");
        bufstr_add(_json_buffer, "0", 0);
        JSON_END();
    }

    ERASEABLE
    bool _json_parse_null() {
        JSON_BEGIN();
        if (!(STRING_ITERATOR_GET(_json) == 'n'
            && STRING_ITERATOR_GET(_json) == 'u'
            && STRING_ITERATOR_GET(_json) == 'l'
            && STRING_ITERATOR_GET(_json) == 'l'))
            JSON_FAIL("expected 'null'");
        bufstr_add(_json_buffer, "", 0);
        JSON_END();
    }

ERASEABLE
bool _json_parse_string(bool add) {
    JSON_BEGIN();
    if (STRING_ITERATOR_GET(_json) != '"') JSON_FAIL("expected opening '\"'");
    string s = "";
    for (int c; (c = STRING_ITERATOR_GET(_json)); ) {
        if (c == '"') {
            STRING_ITERATOR_UNGET(_json);
            break;
        } else if (c == '\\') {
            string esc;
            switch (STRING_ITERATOR_GET(_json)) {
                default:
                    JSON_FAIL("expected ( '\"' | '\\' | 'n' | 't' )");
                case '"': esc = "\""; break;
                case '\\': esc = "\\"; break;
                case 'n': esc = "\n"; break;
                case 't': esc = "\t"; break;
                case 'u': esc = "\\u"; break; // TODO
                case '/': esc = "/"; break;
            }
            s = strcat(s, esc);
        } else {
            s = strcat(s, chr2str(c));
        }
    }
    if (STRING_ITERATOR_GET(_json) != '"') JSON_FAIL("expected closing '\"'");
    if (add) bufstr_add(_json_buffer, s, 0);
    _json_temp = s;
    JSON_END();
}

ERASEABLE
bool _json_parse_number() {
    JSON_BEGIN();
    if (!(_json_parse_float() || _json_parse_int())) JSON_FAIL("expected number");
    JSON_END();
}

    ERASEABLE
    bool _json_parse_float() {
        JSON_BEGIN();
        string s = "";
        bool needdot = true;
        for (int c; (c = STRING_ITERATOR_GET(_json)); ) {
            if (!(c >= '0' && c <= '9')) {
                if (c == '.' && needdot) {
                    // fine
                    needdot = false;
                } else {
                    STRING_ITERATOR_UNGET(_json);
                    break;
                }
            }
            s = strcat(s, chr2str(c));
        }
        if (s == "") JSON_FAIL("expected float");
        bufstr_add(_json_buffer, s, 0);
        JSON_END();
    }

    ERASEABLE
    bool _json_parse_int() {
        JSON_BEGIN();
        string s = "";
        for (int c; (c = STRING_ITERATOR_GET(_json)); ) {
            if (!(c >= '0' && c <= '9')) {
                STRING_ITERATOR_UNGET(_json);
                break;
            }
            if (s == "" && c == '0') JSON_FAIL("expected [1-9]");
            s = strcat(s, chr2str(c));
        }
        if (s == "") JSON_FAIL("expected int");
        if (ftos(stof(s)) != s) JSON_FAIL("expected int");
        bufstr_add(_json_buffer, s, 0);
        JSON_END();
    }

ERASEABLE
int json_parse(string in, bool() func) {
    string trimmed = "";
    LABEL(trim) {
        int o = strstrofs(in, "\"", 0);
        if (o >= 0) {
            string part = substring(in, 0, o + 1); in = substring(in, o + 1, -1);
            part = strreplace(" ", "", part);
            part = strreplace("\n", "", part);
            trimmed = strcat(trimmed, part);
            goto trim_str;
        } else {
            string part = in;
            part = strreplace(" ", "", part);
            part = strreplace("\n", "", part);
            trimmed = strcat(trimmed, part);
            goto done;
        }
    }
    LABEL(trim_str) {
        int o = strstrofs(in, "\"", 0);
        int esc = strstrofs(in, "\\\"", 0);
        if (o < esc || esc < 0) {
            // simple string
            string part = substring(in, 0, o + 1); in = substring(in, o + 1, -1);
            trimmed = strcat(trimmed, part);
            goto trim;
        } else {
            // has escape
            string part = substring(in, 0, esc + 2); in = substring(in, esc + 2, -1);
            trimmed = strcat(trimmed, part);
            goto trim_str;
        }
    }
    LABEL(done);

    STRING_ITERATOR_SET(_json, trimmed, 0);
    _json_buffer = buf_create();
    bool ret = func();
    if (!ret) {
        buf_del(_json_buffer);
        _json_buffer = -1;
    }
    return _json_buffer;
}

ERASEABLE
string json_get(int buf, string key)
{
    for (int i = 1, n = buf_getsize(buf); i < n; i += 2) {
        if (bufstr_get(buf, i) == key) return bufstr_get(buf, i + 1);
    }
    return string_null;
}

ERASEABLE
void json_del(int buf)
{
    buf_del(buf);
}

ERASEABLE
void json_dump(int buf)
{
    for (int i = 0, n = buf_getsize(buf); i < n; ++i) {
        print(bufstr_get(buf, i), "\n");
    }
}

#undef JSON_BEGIN
#undef JSON_FAIL
#undef JSON_END

TEST(json, Parse)
{
    string s = "{\n\
    \"m_string\": \"\\\"string\\\"\",\n\
    \"m_int\": 123,\n\
    \"m_bool\": true,\n\
    \"m_null\": null,\n\
    \"m_obj\": { },\n\
    \"m_arr\": [ ]\n}"; // "
    print(s, "\n");
    int buf = json_parse(s, _json_parse_object);
    EXPECT_NE(-1, buf);
    json_dump(buf);
    SUCCEED();
}
