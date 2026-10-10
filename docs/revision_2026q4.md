# CoreMark code updates 2026-Q4

This release of CoreMark addresses a range of GitHub issues and pull requests.

- https://github.com/eembc/coremark/issues/4
  - Description : Error checking potentially not computed correctly if CRC and data type fail
  - Link to     : https://github.com/eembc/coremark/pull/61
- https://github.com/eembc/coremark/issues/35
  - Description : ee_u32 accessed with %d format specifier
  - Link to     : https://github.com/eembc/coremark/pull/76
- https://github.com/eembc/coremark/issues/50
  - Description : Question regarding type ee_f32
  - Link to     : https://github.com/eembc/coremark/pull/75
- https://github.com/eembc/coremark/issues/56
  - Description : Library-function test-driver
  - Link to     : https://github.com/eembc/coremark/pull/81
- https://github.com/eembc/coremark/issues/71
  - Description : Incorrect results under Keil C51
  - Link to     : https://github.com/eembc/coremark/pull/79
  - Link to     : https://github.com/eembc/coremark/pull/78
- https://github.com/eembc/coremark/issues/77
  - Description : Makefile requires both PORT_SRCS and PORT_OBJS to be defined, 
    but only the example core_portme.mak files only define one or the other
  - Link to     : https://github.com/eembc/coremark/pull/80
- https://github.com/eembc/coremark/pull/54
  - Description : Ignore coremark.exe and log file
- https://github.com/eembc/coremark/pull/58
  - Description : Add support to add attributes to static_memblk via macro
  - Link to : https://github.com/eembc/coremark/pull/78
- https://github.com/eembc/coremark/pull/66
  - Description : add LDFLAGS in OUTCMD to fix YOCTO QA issues
- https://github.com/eembc/coremark/pull/68
  - Description : Support for running coremark as application on zephyr RTOS
- https://github.com/eembc/coremark/pull/70
  - Description : Update MD5 of coremark.h for check

The pull requests for MCS51 support contains many code changes.
(See https://github.com/eembc/coremark/pull/79 & https://github.com/eembc/coremark/pull/78) 
Here is a breakdown of the code change details.

- coremark.h
  - "size" element in typedef struct core_results is renamed to datasize to workaround a limitation in Keil C51 compiler.
    In this compiler, "size", "data", "pdata" are considered reserved keywords and cannot be used by the program code
    as names for variables.
  -  Update function prototype for crcu8 function from core_util.c due to change in input parameter name.
  - Add HAS_C99 macro, and add inttypes.h if the compiler supports C99 (HAS_C99 set to 1)
- core_main.c:
  - Various code changes in main() due to "size" renamed to "datasize" in core_results structure.
  - Adding STATIC_MEMBLK_ATTR macro for sttribute of the static_memblk[TOTAL_DATA_SIZE]
    - This allows static_memblk[] to be declared as xdata when using MCS51 architecture.
    - This also addressed the request in https://github.com/eembc/coremark/pull/58 
  - Update result report to use the new HAS_C99 macro to select if PRIu32 format specifier can be used.
- core_util.c:
  - crcu8 function: input parameter is renamed from "data" to "newval" to allow the code to be compiled by Keil C51
    - This change also align crcu8 function with other crc functions where the first parameters are named as "newval"
  - check_data_types function: update the comparison between size of pointer and size of integer ee_ptr_int
    - This change remove the error message.
- core_list_join.c
  - Adding __COREMARK_REENTRANT macro
    - This macro is added to support MCS51 architecture. When using MCS51 architecture, by default the C compiler allocate 
      variables in functions with fixed address. This causes problems to functions that can be reentrant.
      This problem can be worked around by adding a reentrant function attribute, and this attribute is compiler specific.
      By declaring the __COREMARK_REENTRANT macro, users can define the compiler specific reentrant attribute easily.
      The __COREMARK_REENTRANT macro is defined for function pointers "*list_cmp" and "*core_list_mergesort".
    - clac_func function: Several variable/parameter names are changed to work around the limitations in Keil C51 compiler.
      The name changes incuded:
      - parameter *pdata changed to *ptr_data
      - variable data changed to curr_data
      - res->size changed to res->datasize
- core_portme.h in barebones, simple and posix
  - Data type : Added stdint.h and changed the following mapping.
    - Maps ee_s32 to int32_t (it was "signed int" but this could maps to 16-bit integer in 8-bit and 16-bit architectures)
    - Maps ee_u32 to uint32_t (it was "unsigned int" but this could maps to 16-bit integer in 8-bit and 16-bit architectures)

Other important notes:

- In https://github.com/eembc/coremark/pull/81/ , a new C macro called MAIN_FUNC_NAME is added. 
  If this is defined, the "main" will be renamed to MAIN_FUNC_NAME.



