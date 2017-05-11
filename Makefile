LUA_INCLUDES=/usr/include/

lib/unicode/native.so: lib/unicode/native.o
	$(CXX) -o $@ -shared $^ $(shell pkg-config --libs icu-uc)

lib/unicode/native.o: lib/unicode/native.cc
	$(CXX) -o $@ -fPIC -c $^ -I$(LUA_INCLUDES) $(shell pkg-config --cflags icu-uc)

clean:
	rm -f lib/unicode/*.o lib/unicode/*.so
