################################################################################
#
#  Program: 3D Slicer
#
#  Copyright (c) 2010 Kitware Inc.
#
#  See Doc/copyright/copyright.txt
#  or http://www.slicer.org/copyright/copyright.txt for details.
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
#  This file was originally developed by Jean-Christophe Fillion-Robin, Kitware Inc.
#  and was partially funded by NIH grant 3P41RR013218-12S1
#
################################################################################

# Based on VTK/CMake/KitCommonWrapBlock.cmake

MACRO(vtkMacroKitPythonWrap)
  set(options)
  set(oneValueArgs KIT_NAME KIT_INSTALL_BIN_DIR KIT_INSTALL_LIB_DIR)
  set(multiValueArgs KIT_SRCS KIT_PYTHON_EXTRA_SRCS KIT_WRAP_HEADERS KIT_PYTHON_LIBRARIES)
  cmake_parse_arguments(MY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  # Sanity checks
  SET(expected_defined_vars 
    VTK_CMAKE_DIR VTK_WRAP_PYTHON BUILD_SHARED_LIBS VTK_LIBRARIES)
  FOREACH(var ${expected_defined_vars})
    IF(NOT DEFINED ${var})
      MESSAGE(FATAL_ERROR "error: ${var} CMake variable is not defined !")
    ENDIF()
  ENDFOREACH()
  
  SET(expected_nonempty_vars MY_KIT_NAME MY_KIT_INSTALL_BIN_DIR MY_KIT_INSTALL_LIB_DIR)
  FOREACH(var ${expected_nonempty_vars})
    IF("${${var}}" STREQUAL "")
      MESSAGE(FATAL_ERROR "error: ${var} CMake variable is empty !")
    ENDIF()
  ENDFOREACH()

  IF(VTK_WRAP_PYTHON AND BUILD_SHARED_LIBS)

    # Tell vtkWrapPython.cmake to set VTK_PYTHON_LIBRARIES for us.
    SET(VTK_WRAP_PYTHON_FIND_LIBS 1)
    INCLUDE(${VTK_CMAKE_DIR}/vtkWrapPython.cmake)

    SET(TMP_WRAP_FILES ${MY_KIT_SRCS} ${MY_KIT_WRAP_HEADERS})
    VTK_WRAP_PYTHON3(${MY_KIT_NAME}Python KitPython_SRCS "${TMP_WRAP_FILES}")
    
    INCLUDE_DIRECTORIES("${PYTHON_INCLUDE_PATH}")
    
    # Create a python module that can be loaded dynamically.  It links to
    # the shared library containing the wrappers for this kit.
    ADD_LIBRARY(${MY_KIT_NAME}PythonD ${KitPython_SRCS} ${MY_KIT_PYTHON_EXTRA_SRCS})
    
    SET(VTK_KIT_PYTHON_LIBRARIES)
    FOREACH(c ${VTK_LIBRARIES})
      LIST(APPEND VTK_KIT_PYTHON_LIBRARIES ${c}PythonD)
    ENDFOREACH()
    TARGET_LINK_LIBRARIES(${MY_KIT_NAME}PythonD ${MY_KIT_NAME} vtkPythonCore ${VTK_PYTHON_LIBRARIES}  ${VTK_KIT_PYTHON_LIBRARIES} ${MY_KIT_PYTHON_LIBRARIES})
    
    INSTALL(TARGETS ${MY_KIT_NAME}PythonD
      RUNTIME DESTINATION ${MY_KIT_INSTALL_BIN_DIR} COMPONENT RuntimeLibraries
      LIBRARY DESTINATION ${MY_KIT_INSTALL_LIB_DIR} COMPONENT RuntimeLibraries
      ARCHIVE DESTINATION ${MY_KIT_INSTALL_LIB_DIR} COMPONENT Development
      )
    
    # Add a top-level dependency on the main kit library.  This is needed
    # to make sure no python source files are generated until the
    # hierarchy file is built (it is built when the kit library builds)
    ADD_DEPENDENCIES(${MY_KIT_NAME}PythonD ${MY_KIT_NAME})

    # Add dependencies that may have been generated by VTK_WRAP_PYTHON3 to
    # the python wrapper library.  This is needed for the
    # pre-custom-command hack in Visual Studio 6.
    IF(KIT_PYTHON_DEPS)
      ADD_DEPENDENCIES(${MY_KIT_NAME}PythonD ${KIT_PYTHON_DEPS})
    ENDIF()
    
    # Create a python module that can be loaded dynamically.  It links to
    # the shared library containing the wrappers for this kit.
    ADD_LIBRARY(${MY_KIT_NAME}Python MODULE ${MY_KIT_NAME}PythonInit.cxx)
    TARGET_LINK_LIBRARIES(${MY_KIT_NAME}Python ${MY_KIT_NAME}PythonD)

    # Python extension modules on Windows must have the extension ".pyd"
    # instead of ".dll" as of Python 2.5.  Older python versions do support
    # this suffix.
    IF(WIN32 AND NOT CYGWIN)
      SET_TARGET_PROPERTIES(${MY_KIT_NAME}Python PROPERTIES SUFFIX ".pyd")
    ENDIF()
    
    # Make sure that no prefix is set on the library
    SET_TARGET_PROPERTIES(${MY_KIT_NAME}Python PROPERTIES PREFIX "")

    INSTALL(TARGETS ${MY_KIT_NAME}Python
      RUNTIME DESTINATION ${MY_KIT_INSTALL_BIN_DIR} COMPONENT RuntimeLibraries
      LIBRARY DESTINATION ${MY_KIT_INSTALL_LIB_DIR} COMPONENT RuntimeLibraries
      ARCHIVE DESTINATION ${MY_KIT_INSTALL_LIB_DIR} COMPONENT Development
      )
  ENDIF()
  
ENDMACRO()

