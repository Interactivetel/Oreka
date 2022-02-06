METASOURCES = AUTO
plugindir= $(prefix)/lib/orkaudio/plugins
plugin_LTLIBRARIES = libg729codec.la
libg729codec_la_SOURCES = G729Codec.cpp
libg729codec_la_LDFLAGS = -module
AM_CPPFLAGS = -D_REENTRANT 
libg729codec_la_LIBADD = -lbcg729 -llog4cxx
INCLUDES = -I@top_srcdir@ -I../../../orkbasecxx -I/usr/include/apr-1 -I/usr/include/apr-1.0

all-local: libg729codec.la
	cp .libs/libg729codec.so.0.0.0 ../../plugins/libg729codec.so
