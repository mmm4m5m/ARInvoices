
## Lazarus: Step debug into FPC source (or 'Use Debug DCUs' for FPC source)

We will use conditional define in FPC config file - FPCFG_DEBUG_UNITS.

When it is defined, the compiler will use (-Fu) FPC units build with debug info.

In Lazarus project we will use this conditional define for Debug build mode.


### 1. Directory tree
```
~/fpc/
~/fpc/fpc-3.2.2/ - normal build
~/fpc/fpc-3.2.2.source/
~/fpc/fpc-3.2.2-debug/ - build with debug info
```


### 2. Install FPC and FPC sources

Follow the installation steps - https://wiki.lazarus.freepascal.org/Installing_the_Free_Pascal_Compiler

Build FPC units with debug info. I am using Linux, Debian 10:
```
$ cd ~/fpc/fpc-3.2.2.source
$ make clean all FPMAKEOPT="-T 2" OPT="-gl -gw -godwarfsets -O-"
## FPMAKEOPT="-T 2" - use 2 CPU cores for faster build
## OPT="-gl -gw -godwarfsets -O-" - debug info, no optimizations. https://wiki.lazarus.freepascal.org/GDB_Debugger_Tips

$ rm -r ~/fpc/fpc-3.2.2-debug
$ make install INSTALL_PREFIX=~/fpc/fpc-3.2.2-debug
$ make clean
```


#### 2.1. Notes if you are building different version, like 3.2.3

If you are using SVN, then get suitable branch - stable release, fixes.

You will need 'normal' build without debug info. The steps are similar, just remove 'OPT' parameter:
```
$ make clean all FPMAKEOPT="-T 2"
$ make install INSTALL_PREFIX=~/fpc/fpc-3.2.3
```

Setup 3.2.3 compiler as default:
```
$ ln -s ~/fpc/fpc-3.2.3/lib/fpc/3.2.3/ppcx64 ~/fpc/fpc-3.2.3/bin/ppcx64
$ export PATH=~/fpc/fpc-3.2.3/bin:$PATH
$ fpc -iV; # verify it works
```

There are few 'fpc.cfg' files:
```
/etc/fpc.cfg - global config
~/.fpc.cfg - user config
~/fpc/fpc-3.2.3/lib/fpc/etc/fpc.cfg - config specific compiler
```

Decide which 'fpc.cfg' file, find the lines pointing to the previous compiler and adjust the paths as you need:
```
# old ex.: -Fu/fpc/fpc-$fpcversion/...
# new ex.: -Fu$HOME$/fpc/fpc-$fpcversion/...
```

Test it works - https://wiki.lazarus.freepascal.org/Installing_the_Free_Pascal_Compiler#Testing_the_FPC_Install


### 3. Setup FPC to use debug units

In 'fpc.cfg' file add '#ifdef FPCFG_DEBUG_UNITS ... #else ... #endif'

After '#else' move the default '-Fu' lines.

Before '#else' copy the default '-Fu' lines and adjusted the paths to debug units:
```
#ifdef FPCFG_DEBUG_UNITS

# Search for $fpctarget/$fpcsubarch-$fpcmemorymodel/ subdirectory first
# for i8086 CPU
#ifdef cpui8086
-Fu$HOME$/fpc/fpc-$fpcversion-debug/lib/fpc/$fpcversion/units/$fpctarget/$fpcsubarch-$fpcmemorymodel
-Fu$HOME$/fpc/fpc-$fpcversion-debug/lib/fpc/$fpcversion/units/$fpctarget/$fpcsubarch-$fpcmemorymodel/*
-Fu$HOME$/fpc/fpc-$fpcversion-debug/lib/fpc/$fpcversion/units/$fpctarget/$fpcsubarch-$fpcmemorymodel/rtl
#endif

# searchpath for units and other system dependent things
-Fu$HOME$/fpc/fpc-$fpcversion-debug/lib/fpc/$fpcversion/units/$fpctarget
-Fu$HOME$/fpc/fpc-$fpcversion-debug/lib/fpc/$fpcversion/units/$fpctarget/*
-Fu$HOME$/fpc/fpc-$fpcversion-debug/lib/fpc/$fpcversion/units/$fpctarget/rtl

#IFDEF FPCAPACHE_1_3
-Fu$HOME$/fpc/fpc-$fpcversion-debug/lib/fpc/$fpcversion/units/$fpctarget/httpd13/
#ELSE
#IFDEF FPCAPACHE_2_0
-Fu$HOME$/fpc/fpc-$fpcversion-debug/lib/fpc/$fpcversion/units/$fpctarget/httpd20
#ELSE
-Fu$HOME$/fpc/fpc-$fpcversion-debug/lib/fpc/$fpcversion/units/$fpctarget/httpd22
#ENDIF
#ENDIF

#else

# HERE the default '-Fu' lines - paths without '-debug'
...
-Fu$HOME$/fpc/fpc-$fpcversion/lib/fpc/$fpcversion/units/$fpctarget
...

#endif
```

( Pity, we can not assign variable in fpc.cfg. It could be more simple. )

( Example: #ifdef FPCFG_DEBUG_UNITS then $DEBUG_SUFFIX:='-debug' )

( And single '-Fu' path like: -Fu/path/fpc-$fpcversion$DEBUG_SUFFIX/... )


### 4. Setup your project to use FPC debug units

If you like, you can add new build mode - 'Debug FPC'.

Add conditional define in 'Project Options, Compiler Options, Custom Options':
```
-dFPCFG_DEBUG_UNITS
```

### Done!


### 5. Notes about Lazarus source

The concept of 'Use Debug DCUs' does NOT apply for Lazarus source.

Lazarus (lazbuild) will rebuild the source and packages as needed.

If you want to disable step debug, then build 'Optimized IDE' and you will have UNITS without debug info.

If you need step debug with mode debug info, then build 'Debug IDE'.

If you already disabled step debug ('Optimized IDE') and now you want to step debug into source of a specific package, then read about 'Additions and Overrides': https://wiki.freepascal.org/IDE_Window:_Compiler_Options#Additions_and_Overrides

If you need command line (release) build, then check 'lazbuild': https://wiki.freepascal.org/lazbuild

