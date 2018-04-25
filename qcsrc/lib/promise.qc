#include "promise.qh"

enum {
    PROMISE_PENDING,
    PROMISE_RESOLVED,
    PROMISE_REJECTED,
};

classfield(Promise) .int _promise_state;
classfield(Promise) .entity _promise_result;
classfield(Promise) .IntrusiveList _promise_handlers;
/** non-pending promises with no references may removed. TODO: implement (sv_cmd find Promise) */
classfield(Promise) .int _promise_refcount;

entityclass(PromiseHandler);
classfield(PromiseHandler) .Promise _promise_handler_ret;
classfield(PromiseHandler) .entity _promise_handler_data;
classfield(PromiseHandler) .int(Promise ret, entity result, entity userdata) _promise_handler_resolve;
classfield(PromiseHandler) .int(Promise ret, entity err, entity userdata) _promise_handler_reject;

Promise promise_new()
{
    Promise p = new_pure(Promise);
    p._promise_result = p; // promises default to being their own result to save on entities
    return p;
}

void promise_ref(Promise this)
{
    this._promise_refcount += 1;
}

void promise_unref(Promise this)
{
    this._promise_refcount -= 1;
}

void promise_handle(Promise this, PromiseHandler h);

int promise_resolve(Promise this)
{
    if (!this) {
        LOG_SEVERE("Attempted to resolve a null promise");
        return this._promise_state;
    }
    if (this._promise_state != PROMISE_PENDING) {
        LOG_SEVEREF("Resolved non-pending promise %i", this);
        return this._promise_state;
    }
    this._promise_state = PROMISE_RESOLVED;
    if (this._promise_handlers) {
        IL_EACH(this._promise_handlers, true, promise_handle(this, it));
        IL_DELETE(this._promise_handlers);
    }
    return this._promise_state;
}

int promise_reject(Promise this)
{
    if (!this) {
        LOG_SEVERE("Attempted to reject a null promise");
        return this._promise_state;
    }
    if (this._promise_state != PROMISE_PENDING) {
        LOG_SEVEREF("Rejected non-pending promise %i", this);
        return this._promise_state;
    }
    this._promise_state = PROMISE_REJECTED;
    if (this._promise_handlers) {
        IL_EACH(this._promise_handlers, true, promise_handle(this, it));
        IL_DELETE(this._promise_handlers);
    }
    return this._promise_state;
}

void promise_handle(Promise this, PromiseHandler h)
{
    switch (this._promise_state) {
        case PROMISE_PENDING:
            if (!this._promise_handlers) {
                this._promise_handlers = IL_NEW();
            }
            IL_PUSH(this._promise_handlers, h);
            break;
        case PROMISE_RESOLVED:
            h._promise_handler_resolve(h._promise_handler_ret, this._promise_result, h._promise_handler_data);
            delete(h);
            break;
        case PROMISE_REJECTED:
            h._promise_handler_reject(h._promise_handler_ret, this._promise_result, h._promise_handler_data);
            delete(h);
            break;
    }
}

void promise_done(
        Promise this,
        int(Promise ret, entity result, entity userdata) onResolve,
        int(Promise ret, entity err, entity userdata) onReject,
        Promise ret,
        entity userdata
)
{
    PromiseHandler h = new_pure(PromiseHandler);
    h._promise_handler_ret = ret;
    h._promise_handler_data = userdata;
    h._promise_handler_resolve = onResolve;
    h._promise_handler_reject = onReject;
    promise_handle(this, h);
}

int _promise_onResolve_default(Promise ret, entity result, entity userdata)
{
    ret._promise_result = result;
    return promise_resolve(ret);
}

int _promise_onReject_default(Promise ret, entity err, entity userdata)
{
    ret._promise_result = err;
    return promise_reject(ret);
}

Promise _promise_then(
        Promise this,
        int(Promise ret, entity result, entity userdata) onResolve,
        int(Promise ret, entity result, entity userdata) onReject,
        entity userdata
)
{
    Promise ret = promise_new();
    promise_done(
            this,
            (onResolve ? onResolve : _promise_onResolve_default),
            (onReject ? onReject : _promise_onReject_default),
            ret,
            userdata
    );
    return ret;
}

Promise promise_then(
        Promise this,
        int(Promise ret, entity result, entity userdata) onResolve,
        entity userdata
)
{
    return _promise_then(this, onResolve, func_null, userdata);
}

Promise promise_catch(
        Promise this,
        int(Promise ret, entity result, entity userdata) onReject,
        entity userdata
)
{
    return _promise_then(this, func_null, onReject, userdata);
}

int promise_test_then(Promise ret, entity result, entity userdata);
int promise_test_catch(Promise ret, entity err, entity userdata);
.int pval;

void promise_test()
{
    Promise p0 = promise_new(); p0.pval = 5;
    Promise p = p0;
    p = promise_then(p, promise_test_then, NULL);
    p = promise_then(p, promise_test_then, NULL);
    p = promise_catch(p, promise_test_catch, NULL);
    promise_resolve(p0);
}

int promise_test_then(Promise ret, entity result, entity userdata)
{
    LOG_INFOF("in .then(): %d", result.pval);
    ret.pval = 10;
    return promise_reject(ret);
}

int promise_test_catch(Promise ret, entity err, entity userdata)
{
    LOG_INFOF("in .catch(): %d", err.pval);
    return promise_resolve(ret);
}
