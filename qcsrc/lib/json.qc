#include "test.qh"

STRING_ITERATOR(_json, string_null, 0);

/** parse a json object */
bool _json_parse_object();
    bool _json_parse_members();
        bool _json_parse_pair();
bool _json_parse_array();
    bool _json_parse_elements();
bool _json_parse_value();
    bool _json_parse_true();
    bool _json_parse_false();
    bool _json_parse_null();
bool _json_parse_string();
bool _json_parse_number();
    bool _json_parse_int();

#define JSON_BEGIN() int __i = STRING_ITERATOR_SAVE(_json)
#define JSON_FAIL(reason) goto fail
#define JSON_END() \
   return true; \
:fail \
   STRING_ITERATOR_LOAD(_json, __i); \
   return false;

bool _json_parse_object() {
    JSON_BEGIN();
    if (STRING_ITERATOR_GET(_json) != '{') JSON_FAIL("expected '{'");
    LOG_INFO(">> object\n");
    _json_parse_members();
    if (STRING_ITERATOR_GET(_json) != '}') JSON_FAIL("expected '}'");
    LOG_INFO("<< object\n");
    JSON_END();
}

    bool _json_parse_members() {
        JSON_BEGIN();
        if (!_json_parse_pair()) JSON_FAIL("expected pair");
        if (STRING_ITERATOR_PEEK(_json) == ',') {
            STRING_ITERATOR_NEXT(_json);
            if (!_json_parse_members()) JSON_FAIL("expected pair");
        }
        JSON_END();
    }

        bool _json_parse_pair() {
            JSON_BEGIN();
            if (!_json_parse_string()) JSON_FAIL("expected string");
            if (STRING_ITERATOR_GET(_json) != ':') JSON_FAIL("expected ':'");
            if (!_json_parse_value()) JSON_FAIL("expected value");
            JSON_END();
        }

bool _json_parse_array() {
    JSON_BEGIN();
    if (STRING_ITERATOR_GET(_json) != '[') JSON_FAIL("expected '['");
    LOG_INFO(">> array\n");
    _json_parse_elements();
    if (STRING_ITERATOR_GET(_json) != ']') JSON_FAIL("expected ']'");
    LOG_INFO("<< array\n");
    JSON_END();
}

    bool _json_parse_elements() {
        JSON_BEGIN();
        if (!_json_parse_value()) JSON_FAIL("expected value");
        if (STRING_ITERATOR_PEEK(_json) == ',') {
            STRING_ITERATOR_NEXT(_json);
            if (!_json_parse_elements()) JSON_FAIL("expected value");
        }
        JSON_END();
    }

bool _json_parse_value() {
    JSON_BEGIN();
    if (!(_json_parse_string()
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
        LOG_INFO(">> bool (true)\n");
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
        LOG_INFO(">> bool (false)\n");
        JSON_END();
    }

    bool _json_parse_null() {
        JSON_BEGIN();
        if (!(STRING_ITERATOR_GET(_json) == 'n'
            && STRING_ITERATOR_GET(_json) == 'u'
            && STRING_ITERATOR_GET(_json) == 'l'
            && STRING_ITERATOR_GET(_json) == 'l'))
            JSON_FAIL("expected 'null'");
        LOG_INFO(">> null\n");
        JSON_END();
    }

bool _json_parse_string() {
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
    LOG_INFOF(">> string ('%s')\n", s);
    JSON_END();
}

bool _json_parse_number() {
    JSON_BEGIN();
    if (!_json_parse_int()) JSON_FAIL("expected int");
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
        int i = stof(s);
        LOG_INFOF(">> int (%d)\n", i);
        JSON_END();
    }

bool json_parse(string in) {
    // TODO: remove insignificant whitespace
    STRING_ITERATOR_SET(_json, in, 0);
    return _json_parse_object();
}

#undef JSON_BEGIN
#undef JSON_FAIL
#undef JSON_END

TEST(json, Parse)
{
    EXPECT_EQ(true, json_parse("{\"string\":\"string\",\"int\":123,\"bool\":true,\"null\":null,\"obj\":{\"arr\":[1,2,3]}}"));
	SUCCEED();
}
