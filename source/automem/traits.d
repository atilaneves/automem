module automem.traits;


void checkAllocator(T)() {
    import stdx.allocator: make, dispose;
    import std.traits: hasMember;

    static if(hasMember!(T, "instance"))
        alias allocator = T.instance;
    else
        T allocator;

    int* i = allocator.make!int;
    allocator.dispose(&i);
    void[] bytes = allocator.allocate(size_t.init);
    allocator.deallocate(bytes);
}

enum isAllocator(T) = is(typeof(checkAllocator!T));


@("isAllocator")
@safe @nogc pure unittest {
    import stdx.allocator.mallocator: Mallocator;
    import test_allocator: TestAllocator;

    static assert(isAllocator!Mallocator);
    static assert(isAllocator!TestAllocator);
    static assert(!isAllocator!int);
}


template isGlobal(Allocator) {
    enum isGlobal = isSingleton!Allocator || isTheAllocator!Allocator;
}

template isSingleton(Allocator) {
    import std.traits: hasMember;
    enum isSingleton = hasMember!(Allocator, "instance");
}

template isTheAllocator(Allocator) {
    import stdx.allocator: theAllocator;
    enum isTheAllocator = is(Allocator == typeof(theAllocator));
}

template classHasMonitorPointer(C) if (is(C == class))
{
    static if (__VERSION__ >= 2081) // https://dlang.org/changelog/2.081.0.html#getlinkage_for_classes
    {
        enum classHasMonitorPointer = __traits(getLinkage, C) == "D";
    }
    else
    {
        enum classHasMonitorPointer = is(immutable(C)* : immutable(Object)*);
    }
}

template classHasMemberWithPointer(C) if (is(C == class))
{
    enum classHasMemberWithPointer =
        () {
            foreach (p; __traits(getPointerBitmap, C)[1 .. $])
                if (p != 0) return true;
            return false;
        }();
}
