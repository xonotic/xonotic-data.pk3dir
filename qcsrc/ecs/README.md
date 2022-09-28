# Xonotic entity component system

## guidelines

* avoid #if and #ifdef
* avoid string
* avoid declaring entity fields outside of components
* uncrustify relentlessly
* shared code in $file, prog specific code uses prefix: { client: cl_, server: sv_, menu: ui_ }. $file must exist
* component naming =~ com_$component_$name
* system naming =~ sys_$system_$name
* event naming =~ evt_$component_$name
* global naming =~ g_$name
* cvar naming =~ xon_$name

## components

    COMPONENT($component);
    .int com_$component_$property;

## entities

    entity e = new(foo);
    IL_PUSH(g_components, e);
    e.com_$component = true;
    e.com_$component_$property = 42;

## systems

    SYSTEM($system, 30, 10);
    sys_$system_update(entity this, float dt) {
        code;
    }

## events

### declaring

    EVENT($component_$name, (entity this));

### emitting

    emit($event, it);

### listening

    entity listener = new_pure(someListener);
    subscribe(listener, $event, void(entity this) { code; });
