cmake_minimum_required(VERSION 3.22)

project(system_audio_pulse LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

include(FetchContent)

set(GODOT_CPP_BRANCH "godot-4.5-stable" CACHE STRING "godot-cpp branch or tag")
FetchContent_Declare(
	godot-cpp
	GIT_REPOSITORY https://github.com/godotengine/godot-cpp.git
	GIT_TAG ${GODOT_CPP_BRANCH}
)
FetchContent_MakeAvailable(godot-cpp)

configure_file(
	"${CMAKE_CURRENT_SOURCE_DIR}/system_audio_pulse.gdextension.in"
	"${CMAKE_CURRENT_SOURCE_DIR}/system_audio_pulse.gdextension"
	COPYONLY
)

add_library(system_audio_pulse SHARED
	src/register_types.cpp
	src/windows_system_audio_analyzer.cpp
)

target_include_directories(system_audio_pulse PRIVATE src)
target_link_libraries(system_audio_pulse PRIVATE godot-cpp)

if(WIN32)
	target_compile_definitions(system_audio_pulse PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
	target_link_libraries(system_audio_pulse PRIVATE ole32 uuid avrt)
else()
	message(FATAL_ERROR "system_audio_pulse currently supports Windows builds only.")
endif()

set_target_properties(system_audio_pulse PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	LIBRARY_OUTPUT_DIRECTORY_DEBUG "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	LIBRARY_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${CMAKE_CURRENT_SOURCE_DIR}/bin"
	OUTPUT_NAME_DEBUG "system_audio_pulse.windows.template_debug.x86_64"
	OUTPUT_NAME_RELEASE "system_audio_pulse.windows.template_release.x86_64"
	OUTPUT_NAME_RELWITHDEBINFO "system_audio_pulse.windows.template_release.x86_64"
	OUTPUT_NAME_MINSIZEREL "system_audio_pulse.windows.template_release.x86_64"
)
