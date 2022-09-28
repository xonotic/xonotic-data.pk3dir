#include "promise.qh"

.int _ref_count;
.void(entity this) _ref_finalize;

void ref_init(entity this, int init, void(entity this) finalize)
{
    this._ref_count = init;
    this._ref_finalize = finalize;
}

// todo: rename to `ref`
entity REF(entity this)
{
    this._ref_count += 1;
    return this;
}

entity unref(Promise this)
{
    this._ref_count -= 1;
    if (!this._ref_count) {
        LOG_DEBUGF("Finalize entity %i (from %s)", this, this.sourceLoc);
        this._ref_finalize(this);
        return NULL;
    }
    return this;
}

enum {
    PROMISE_PENDING,
    PROMISE_RESOLVED,
    PROMISE_REJECTED,
};

classfield(Promise) .int _promise_state;
classfield(Promise) .entity _promise_result;
classfield(Promise) .IntrusiveList _promise_handlers;

entityclass(PromiseHandler);
classfield(PromiseHandler) .Promise _promise_handler_ret;
classfield(PromiseHandler) .entity _promise_handler_data;
classfield(PromiseHandler) .Promise(Promise ret, entity result, entity userdata) _promise_handler_resolve;
classfield(PromiseHandler) .Promise(Promise ret, entity err, entity userdata) _promise_handler_reject;

void _Promise_finalize(Promise this)
{
    delete(this);
}

Promise Promise_new_(Promise this)
{
    ref_init(this, 2, _Promise_finalize);
    this._promise_result = this; // promises default to being their own result to save on entities
    return this;
}

void _Promise_handle(Promise this, PromiseHandler h);

void Promise_resolve(Promise this)
{
    if (!this) {
        LOG_SEVERE("Attempted to resolve a null promise");
        return;
    }
    if (this._promise_state != PROMISE_PENDING) {
        LOG_SEVEREF("Resolved non-pending promise %i", this);
        return;
    }
    this._promise_state = PROMISE_RESOLVED;
    if (this._promise_handlers) {
        IL_EACH(this._promise_handlers, true, _Promise_handle(this, it));
        IL_DELETE(this._promise_handlers);
    }
    unref(this);
    return;
}

void Promise_reject(Promise this)
{
    if (!this) {
        LOG_SEVERE("Attempted to reject a null promise");
        return;
    }
    if (this._promise_state != PROMISE_PENDING) {
        LOG_SEVEREF("Rejected non-pending promise %i", this);
        return;
    }
    this._promise_state = PROMISE_REJECTED;
    if (this._promise_handlers) {
        IL_EACH(this._promise_handlers, true, _Promise_handle(this, it));
        IL_DELETE(this._promise_handlers);
    }
    unref(this);
    return;
}

Promise _Promise_then(
        Promise this,
        Promise ret,
        Promise(Promise ret, entity result, entity userdata) onResolve,
        Promise(Promise ret, entity result, entity userdata) onReject,
        entity userdata
);

void _Promise_handle(Promise this, PromiseHandler h)
{
    switch (this._promise_state) {
        case PROMISE_PENDING:
            if (!this._promise_handlers) {
                this._promise_handlers = IL_NEW();
            }
            IL_PUSH(this._promise_handlers, h);
            break;
        case PROMISE_RESOLVED: {
            Promise ret = h._promise_handler_ret;
            Promise p = h._promise_handler_resolve(ret, this._promise_result, h._promise_handler_data);
            if (p != ret) _Promise_then(p, ret, func_null, func_null, NULL); // bind p -> ret
            delete(h);
            break;
        }
        case PROMISE_REJECTED: {
            Promise ret = h._promise_handler_ret;
            Promise p = h._promise_handler_reject(ret, this._promise_result, h._promise_handler_data);
            if (p != ret) _Promise_then(p, ret, func_null, func_null, NULL); // bind p -> ret
            delete(h);
            break;
        }
    }
}

void _Promise_done(
        Promise this,
        Promise(Promise ret, entity result, entity userdata) onResolve,
        Promise(Promise ret, entity err, entity userdata) onReject,
        Promise ret,
        entity userdata
)
{
    PromiseHandler h = new_pure(PromiseHandler);
    h._promise_handler_ret = ret;
    h._promise_handler_data = userdata;
    h._promise_handler_resolve = onResolve;
    h._promise_handler_reject = onReject;
    _Promise_handle(this, h);
}

Promise _Promise_onResolve_default(Promise ret, entity result, entity userdata)
{
    ret._promise_result = result;
    Promise_resolve(ret);
    return ret;
}

Promise _Promise_onReject_default(Promise ret, entity err, entity userdata)
{
    ret._promise_result = err;
    Promise_reject(ret);
    return ret;
}

Promise _Promise_then(
        Promise this,
        Promise ret,
        Promise(Promise ret, entity result, entity userdata) onResolve,
        Promise(Promise ret, entity result, entity userdata) onReject,
        entity userdata
)
{
    _Promise_done(
            this,
            (onResolve ? onResolve : _Promise_onResolve_default),
            (onReject ? onReject : _Promise_onReject_default),
            ret,
            userdata
    );
    return ret;
}

Promise Promise_then_(
        Promise this,
        Promise ret,
        Promise(Promise ret, entity result, entity userdata) onResolve,
        entity userdata
)
{
    unref(ret); // ret is a temporary
    return _Promise_then(this, ret, onResolve, func_null, userdata);
}

Promise Promise_catch_(
        Promise this,
        Promise ret,
        Promise(Promise ret, entity result, entity userdata) onReject,
        entity userdata
)
{
    unref(ret); // ret is a temporary
    return _Promise_then(this, ret, func_null, onReject, userdata);
}

// utils

#ifndef MENUQC

Promise Promise_sleep(float n)
{
    Promise p = unref(Promise_new());
    setthink(p, Promise_resolve);
    p.nextthink = time + n;
    return p;
}

#endif
