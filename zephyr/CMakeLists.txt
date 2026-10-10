# Copyright 2025 CISPA Helmholtz Center for Information Security gGmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
# Original Author: Eric Ackermann

cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

project(coremark)

set(ZEPHYR_PORT_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(COREMARK_DIR ${ZEPHYR_PORT_DIR}/../)

target_sources(app PRIVATE
        # core sources
        ${COREMARK_DIR}/core_list_join.c
        ${COREMARK_DIR}/core_main.c
        ${COREMARK_DIR}/core_matrix.c
        ${COREMARK_DIR}/core_state.c
        ${COREMARK_DIR}/core_util.c
        # port-specific sources
        ${ZEPHYR_PORT_DIR}/core_portme.c
)

target_include_directories(app PRIVATE ${ZEPHYR_PORT_DIR})
target_include_directories(app PRIVATE ${COREMARK_DIR})

if($ENV{ITERATIONS})
    target_compile_definitions(app PRIVATE -DITERATIONS=$ENV{ITERATIONS})
else()
    target_compile_definitions(app PRIVATE -DITERATIONS=0)
endif()

if($ENV{XCFLAGS})
    target_compile_options(app $ENV{XCFLAGS})
endif()

if(CMAKE_C_COMPILER_VERSION)
    target_compile_definitions(app PRIVATE -DCOMPILER_VERSION="${CMAKE_C_COMPILER_VERSION}")
endif()
