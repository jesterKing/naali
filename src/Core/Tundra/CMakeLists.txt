# Define target name and output directory
init_target (Tundra OUTPUT ./)

# Define source files
file (GLOB CPP_FILES *.cpp)
file (GLOB H_FILES *.h)
set (SOURCE_FILES ${CPP_FILES} ${H_FILES})

set (FILES_TO_TRANSLATE ${FILES_TO_TRANSLATE} ${H_FILES} ${CPP_FILES} PARENT_SCOPE)

# Never compile server in consoleless mode
set (WINDOWS_APP 0)

# Preprocessor defines on MSVC
if (MSVC)
   set_property (DIRECTORY PROPERTY COMPILE_DEFINITIONS_RELEASE _DMEMDUMP)
   set_property (DIRECTORY PROPERTY COMPILE_DEFINITIONS_RELWITHDEBINFO _DMEMDUMP)

    # Add the DEBUG_CPP_NAME to all other .cpp files but StableHeaders.cpp (would conflict with the #defines in PCH)
    # This define is used to remember the name of the compilation unit for memory leak checking.
    # Also label all files to use a PCH.
    foreach(src_file ${CPP_FILES})
            if (${src_file} MATCHES "StableHeaders.cpp$")
            else()
                get_filename_component(basename ${src_file} NAME)
                set_source_files_properties(${src_file}
                    PROPERTIES COMPILE_FLAGS "-DDEBUG_CPP_NAME=\"\\\"${basename}\"\\\"")
            endif()
    endforeach(src_file ${CPP_FILES})
endif (MSVC)

use_core_modules (Framework Scene Console)

build_executable (${TARGET_NAME} ${SOURCE_FILES})

link_modules (Framework Scene Console)

final_target ()
