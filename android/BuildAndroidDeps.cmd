@echo off
echo.

:: Populate path variables
cd ..
set ORIGINAL_PATH=%PATH%
set PATH=%PATH%;"%CD%\tools\utils-windows"
set ANDROID=%CD%\android
set TUNDRA_DIR="%CD%"
set TUNDRA_BIN=%CD%\bin
set DEPS=%CD%\deps-android
cd %ANDROID%

:: Make sure deps folder exists.
IF NOT EXIST "%DEPS%". mkdir "%DEPS%"

:: Bullet
IF NOT EXIST "%DEPS%\bullet\". (
   cecho {0D}Cloning Bullet into "%DEPS%\bullet".{# #}{\n}
   cd "%DEPS%"
   svn checkout http://bullet.googlecode.com/svn/tags/bullet-2.78 bullet
   IF NOT EXIST "%DEPS%\bullet\.svn" GOTO :ERROR
)
IF NOT EXIST "%DEPS%\bullet\libs\armeabi-v7a\libBulletCollision.a". (
   cecho {0D}Building Bullet. Please be patient, this will take a while.{# #}{\n}
   cd "%DEPS%\bullet"
   del CMakeCache.txt
   cmake -G"NMake Makefiles" -DCMAKE_TOOLCHAIN_FILE=%ANDROID%/android.toolchain.cmake
   nmake
   IF NOT %ERRORLEVEL%==0 GOTO :ERROR
) ELSE (
   cecho {0D}Bullet already built. Skipping.{# #}{\n}
)

:: Boost
IF NOT EXIST "%DEPS%\boost". (
   cecho {0D}Downloading Boost into "%DEPS%\boost".{# #}{\n}
   cd "%DEPS%"
   wget http://downloads.sourceforge.net/project/boost/boost/1.49.0/boost_1_49_0.tar.gz
   IF NOT %ERRORLEVEL%==0 GOTO :ERROR
   tar xvf boost_1_49_0.tar.gz
   ren boost_1_49_0 boost
   del boost_1_49_0.tar.gz
   IF NOT EXIST "%DEPS%\boost\boost.css" GOTO :ERROR
)
IF NOT EXIST "%DEPS%\boost\boost-1_49_0.patch". (
   cecho {0D}Patching Boost.{# #}{\n}
   cd "%DEPS%\boost"
   copy "%ANDROID%\boost-1_49_0.patch" .
   :: Make sure the patch has Unix line endings
   sfk crlf-to-lf boost-1_49_0.patch
   patch -l -p1 -i boost-1_49_0.patch
   IF NOT %ERRORLEVEL%==0 GOTO :ERROR
   cecho {0D}Building Boost build engine.{# #}{\n}
   cd "%DEPS%\boost"
   call bootstrap.bat
)
IF NOT EXIST "%DEPS%\boost\lib\libboost_date_time.a". (
    cd "%DEPS%\boost"
    cecho {0D}Building Boost.{# #}{\n}
    copy "%ANDROID%\user-config.jam" tools\build\v2
    copy "%ANDROID%\project-config.jam" .
    b2 --with-date_time --with-filesystem --with-program_options --with-regex --with-signals --with-system --with-thread --with-iostreams toolset=gcc-android4.4.3 link=static runtime-link=static target-os=linux --stagedir=. --layout=system
) ELSE (
   cecho {0D}Boost already built. Skipping.{# #}{\n}
)

:: kNet
IF NOT EXIST "%DEPS%\kNet\". (
   cecho {0D}Cloning kNet from https://github.com/juj/kNet into "%DEPS%\kNet".{# #}{\n}
   cd "%DEPS%"
   call git clone https://github.com/juj/kNet
   IF NOT EXIST "%DEPS%\kNet\.git" GOTO :ERROR
)
IF NOT EXIST "%DEPS%\kNet\lib\libkNet.a". (
    cecho {0D}Building kNet.{# #}{\n}
    cd "%DEPS%\kNet"
    del CMakeCache.txt
    cmake -G"NMake Makefiles" -DCMAKE_TOOLCHAIN_FILE=%ANDROID%/android.toolchain.cmake -DBOOST_ROOT=%DEPS%/boost
    nmake
    IF NOT %ERRORLEVEL%==0 GOTO :ERROR
) ELSE (
   cecho {0D}kNet already built. Skipping.{# #}{\n}
)

echo.
cecho {0A}Tundra dependencies built.{# #}{\n}
set PATH=%ORIGINAL_PATH%
cd %ANDROID%
GOTO :EOF

:ERROR
echo.
cecho {0C}An error occurred! Aborting!{# #}{\n}
set PATH=%ORIGINAL_PATH%
cd %ANDROID%
pause
