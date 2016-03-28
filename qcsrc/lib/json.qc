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

bool _json_parse_object() {
    JSON_BEGIN();
    if (STRING_ITERATOR_GET(_json) != '{') JSON_FAIL("expected '{'");
    WITH(int, _json_keys, bufstr_add(_json_buffer, "", 0), _json_parse_members());
    if (STRING_ITERATOR_GET(_json) != '}') JSON_FAIL("expected '}'");
    JSON_END();
}

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

bool _json_parse_array() {
    JSON_BEGIN();
    if (STRING_ITERATOR_GET(_json) != '[') JSON_FAIL("expected '['");
    int len = bufstr_add(_json_buffer, "0", 0);
    bufstr_set(_json_buffer, len - 1, strcat(bufstr_get(_json_buffer, len - 1), ".length"));
    int n = -1;
    bool required = false;
    for (;;) {
        bufstr_set(_json_buffer, len, ftos(++n));
        if (!_json_parse_value()) if (required) JSON_FAIL("expected value"); else break;
        bufstr_add(_json_buffer, strcat(_json_ns, ".", ftos(n)), 0);
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

bool _json_parse_number() {
    JSON_BEGIN();
    if (!_json_parse_int()) JSON_FAIL("expected number");
    JSON_END();
}

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

int json_parse(string in) {
    // TODO: remove insignificant whitespace
    STRING_ITERATOR_SET(_json, in, 0);
    _json_buffer = buf_create();
    bool ret = _json_parse_object();
    if (!ret) {
        buf_del(_json_buffer);
        _json_buffer = -1;
    }
    return _json_buffer;
}

#undef JSON_BEGIN
#undef JSON_FAIL
#undef JSON_END

TEST(json, Parse)
{
    string s = "{\"m_string\":\"string\",\"m_int\":123,\"m_bool\":true,\"m_null\":null,\"m_obj\":{},\"m_arr\":[]}";
    print(s, "\n");
    int buf = json_parse(s);
    EXPECT_NE(-1, buf);
    for (int i = 0, n = buf_getsize(buf); i < n; ++i) {
        print(bufstr_get(buf, i), "\n");
    }
	SUCCEED();
}
