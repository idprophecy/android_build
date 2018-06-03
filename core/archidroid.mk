#     _             _     _ ____            _     _
#    / \   _ __ ___| |__ (_)  _ \ _ __ ___ (_) __| |
#   / _ \ | '__/ __| '_ \| | | | | '__/ _ \| |/ _` |
#  / ___ \| | | (__| | | | | |_| | | | (_) | | (_| |
# /_/   \_\_|  \___|_| |_|_|____/|_|  \___/|_|\__,_|
#
# Copyright 2015 Łukasz "JustArchi" Domeradzki
# Contact: JustArchi@JustArchi.net
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#######################
### GENERAL SECTION ###
#######################

# General optimization level of target ARM compiled with GCC. Default: -O2
ARCHIDROID_GCC_CFLAGS_ARM := -O3

# General optimization level of target THUMB compiled with GCC. Default: -Os
ARCHIDROID_GCC_CFLAGS_THUMB := -O3

# Additional flags passed to all C targets compiled with GCC
ARCHIDROID_GCC_CFLAGS := -O3 -fgcse-las -fgcse-sm -fipa-pta -fivopts -fomit-frame-pointer -frename-registers -fsection-anchors -ftracer -ftree-loop-im -ftree-loop-ivcanon -funsafe-loop-optimizations -funswitch-loops -fweb -Wno-error=array-bounds -Wno-error=clobbered -Wno-error=maybe-uninitialized -Wno-error=strict-overflow

############################
### EXPERIMENTAL SECTION ###
############################

# Flags in this section are highly experimental
# Current setup is based on proposed androideabi toolchain
# Results with other toolchains may vary

# These flags work fine in suggested compiler, but may cause ICEs in other compilers, comment if needed
ARCHIDROID_GCC_CFLAGS += -fgraphite -fgraphite-identity -floop-strip-mine -floop-nest-optimize -floop-parallelize-all

# The following flags (-floop) require that your GCC has been configured with --with-isl
# Additionally, applying any of them will most likely cause ICE in your compiler, so they're disabled
# ARCHIDROID_GCC_CFLAGS += -floop-block -floop-interchange

# These flags have been disabled because of assembler errors
# ARCHIDROID_GCC_CFLAGS += -fmodulo-sched -fmodulo-sched-allow-regmoves

####################
### MISC SECTION ###
####################

# Flags passed to GCC preprocessor for C and C++
ARCHIDROID_GCC_CPPFLAGS := $(ARCHIDROID_GCC_CFLAGS)

# Flags passed to linker (ld) of all C and C++ targets compiled with GCC
# ARCHIDROID_GCC_LDFLAGS := -Wl,--sort-common

#####################
### CLANG SECTION ###
#####################

# Flags passed to all C targets compiled with CLANG
ARCHIDROID_CLANG_CFLAGS := -O3 -Qunused-arguments -Wno-unknown-warning-option

# Flags passed to CLANG preprocessor for C and C++
ARCHIDROID_CLANG_CPPFLAGS := $(ARCHIDROID_CLANG_CFLAGS)

# Flags passed to linker (ld) of all C and C++ targets compiled with CLANG
# ARCHIDROID_CLANG_LDFLAGS := -Wl,--sort-common

# Flags that are used by GCC, but are unknown to CLANG. If you get "argument unused during compilation" error, add the flag here
ARCHIDROID_CLANG_UNKNOWN_FLAGS := \
  -mvectorize-with-neon-double \
  -mvectorize-with-neon-quad \
  -fgcse-after-reload \
  -fgcse-las \
  -fgcse-sm \
  -fgraphite \
  -fgraphite-identity \
  -fipa-pta \
  -floop-block \
  -floop-interchange \
  -floop-nest-optimize \
  -floop-parallelize-all \
  -ftree-parallelize-loops=2 \
  -ftree-parallelize-loops=4 \
  -ftree-parallelize-loops=8 \
  -ftree-parallelize-loops=16 \
  -floop-strip-mine \
  -fmodulo-sched \
  -fmodulo-sched-allow-regmoves \
  -frerun-cse-after-loop \
  -frename-registers \
  -fsection-anchors \
  -ftree-loop-im \
  -ftree-loop-ivcanon \
  -funsafe-loop-optimizations \
  -fweb \
  -fivopts \
  -ftracer \

#####################################
# UBER-ify ArchiDroid Optimizations #
#####################################

CUSTOM_FLAGS := -O3 -g0 -DNDEBUG
ifneq ($(LOCAL_SDCLANG_LTO),true)
  ifeq ($(my_clang),true)
    ifndef LOCAL_IS_HOST_MODULE
      CUSTOM_FLAGS += -fuse-ld=qcld
    else
      CUSTOM_FLAGS += -fuse-ld=gold
    endif
  else
    CUSTOM_FLAGS += -fuse-ld=gold
  endif
else
  CUSTOM_FLAGS := -O3 -g0 -DNDEBUG
endif

O_FLAGS := -O3 -O2 -Os -O1 -O0 -Og -Oz

# Fix "error: predicated instructions must be in IT block"
ifeq ($(my_clang),true)
    CUSTOM_FLAGS += -mimplicit-it=always
endif

# Remove all flags we don't want use high level of optimization
my_cflags := $(filter-out -Wall -Werror -g -Wextra -Weverything $(O_FLAGS),$(my_cflags)) $(CUSTOM_FLAGS)
my_cppflags := $(filter-out -Wall -Werror -g -Wextra -Weverything $(O_FLAGS),$(my_cppflags)) $(CUSTOM_FLAGS)
my_conlyflags := $(filter-out -Wall -Werror -g -Wextra -Weverything $(O_FLAGS),$(my_conlyflags)) $(CUSTOM_FLAGS)

#######
# IPA #
#######

LOCAL_DISABLE_IPA := \
	libbluetooth_jni \
	bluetooth.mapsapi \
	bluetooth.default \

ifndef LOCAL_IS_HOST_MODULE
  ifeq (,$(filter true,$(my_clang)))
    ifneq (1,$(words $(filter $(LOCAL_DISABLE_IPA),$(LOCAL_MODULE))))
      my_cflags += -fipa-pta
    endif
  else
    ifneq (1,$(words $(filter $(LOCAL_DISABLE_IPA),$(LOCAL_MODULE))))
      my_cflags += -analyze -analyzer-purge
    endif
  endif
endif

##########
# OpenMP #
##########

LOCAL_DISABLE_OPENMP := \
	libbluetooth_jni \
	bluetooth.mapsapi \
	bluetooth.default \
	libF77blas \
	libF77blasV8 \
	libjni_latinime \
	libyuv_static \
	mdnsd

ifndef LOCAL_IS_HOST_MODULE
  ifneq (1,$(words $(filter $(LOCAL_DISABLE_OPENMP),$(LOCAL_MODULE))))
    my_cflags += -lgomp -lgcc -fopenmp
    my_ldflags += -fopenmp
  endif
endif

###################
# Strict Aliasing #
###################

LOCAL_DISABLE_STRICT := \
	libbluetooth_jni \
	bluetooth.mapsapi \
	bluetooth.default \
	mdnsd

STRICT_ALIASING_FLAGS := \
	-fstrict-aliasing \
	-Werror=strict-aliasing

STRICT_GCC_LEVEL := \
	-Wstrict-aliasing=3

STRICT_CLANG_LEVEL := \
	-Wstrict-aliasing=2

# Remove the no-strict-aliasing flags
my_cflags := $(filter-out -fno-strict-aliasing,$(my_cflags))
ifneq (1,$(words $(filter $(LOCAL_DISABLE_STRICT),$(LOCAL_MODULE))))
  ifeq (,$(filter true,$(my_clang)))
    my_cflags += $(STRICT_ALIASING_FLAGS) $(STRICT_GCC_LEVEL)
  else
    my_cflags += $(STRICT_ALIASING_FLAGS) $(STRICT_CLANG_LEVEL)
  endif
endif
