platform "windows-2019-x64" do |plat|
  plat.vmpooler_template "win-2019-x86_64"
  plat.servicetype 'windows'

  # You must install Wix Toolset 3.14.1 manually before beginning the build.
  # https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314.exe
  #
  # Install ruby, ruby-devel, gcc-core, make, git, and libyaml-devel in Cygwin on the Windows image.
  # Run setup.bat found in the root of this repo. These are needed in order to successfully
  # do a bundle install. They are included here just in case they get removed somehow.
  # Make sure "setup-x86_64.exe" (Cygwin's installer) is at the root of C:/
  packages = [
    'autoconf',
    'cmake',
    'gcc-core',
    'gcc-g++',
    'gettext',
    'gettext-devel',
    'git',
    'libyaml-devel',
    'make',
    'mingw64-x86_64-gcc-core',
    'mingw64-x86_64-gcc-g++',
    'mingw64-x86_64-gdbm',
    'mingw64-x86_64-libffi',
    'mingw64-x86_64-readline',
    'mingw64-x86_64-zlib',
    'ruby',
    'ruby-devel',
    'patch',
  ]

  plat.provision_with("C:/setup-x86_64.exe -q -P #{packages.join(',')}")
  plat.install_build_dependencies_with "C:/setup-x86_64.exe -q -P"

  plat.make "/usr/bin/make"
  plat.patch "TMP=/var/tmp /usr/bin/patch.exe --binary"

  plat.platform_triple "x86_64-w64-mingw32"

  # Putting these here as a reminder where we use them elsewhere. DO NOT
  # use the full path, just the name of the executable without the extension.
  # Otherwise, autoconf gets confused.
  plat.environment 'CC', "x86_64-w64-mingw32-gcc"
  plat.environment 'CXX', "x86_64-w64-mingw32-g++"

  plat.package_type "msi"
  plat.output_dir "windows"
end
