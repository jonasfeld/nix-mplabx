# Wrapper scripts for XC16 compiler tools
# Version can be overridden via XC16_VERSION environment variable
{
  pkgs,
  xc16Version,
}: let
  defaultVersion = xc16Version;

  # Common wrapper for XC16 tools with auto-detection
  makeXc16Wrapper = name:
    pkgs.writeShellScriptBin name ''
      INSTALL_DIR="/opt/microchip/xc16"

      # Use environment variable, or find latest installed, or fall back to default
      if [ -n "$XC16_VERSION" ]; then
        VERSION="$XC16_VERSION"
      elif [ -d "$INSTALL_DIR" ]; then
        # Find latest installed version
        VERSION=$(ls -1 "$INSTALL_DIR" 2>/dev/null | sort -V | tail -1)
      fi
      VERSION="''${VERSION:-${defaultVersion}}"

      XC16_PATH="$INSTALL_DIR/$VERSION"

      if [ ! -d "$XC16_PATH" ]; then
        echo "Error: XC16 not found at $XC16_PATH" >&2
        if [ -d "$INSTALL_DIR" ]; then
          echo "Available versions: $(ls -1 "$INSTALL_DIR" 2>/dev/null | tr '\n' ' ')" >&2
        fi
        echo "Run 'mplab-install' to install the XC16 compiler" >&2
        echo "Or set XC16_VERSION environment variable to select a version" >&2
        exit 1
      fi

      export PATH="$XC16_PATH/bin:$PATH"
      export XC16_TOOLCHAIN_ROOT="$XC16_PATH"

      exec "$XC16_PATH/bin/${name}" "$@"
    '';

  # List of XC16 tools to wrap (mirrors XC32 set; same GNU-style tool names)
  xc16Tools = [
    "xc16-gcc"
    "xc16-g++"
    "xc16-as"
    "xc16-ld"
    "xc16-ar"
    "xc16-objcopy"
    "xc16-objdump"
    "xc16-size"
    "xc16-nm"
    "xc16-strip"
    "xc16-strings"
    "xc16-readelf"
    "xc16-addr2line"
    "xc16-ranlib"
    "xc16-c++filt"
  ];

  wrappers = map makeXc16Wrapper xc16Tools;
in
  pkgs.symlinkJoin {
    name = "xc16-wrappers-${xc16Version}";
    paths = wrappers;
    meta = with pkgs.lib; {
      description = "Wrapper scripts for Microchip XC16 compiler";
      homepage = "https://www.microchip.com/en-us/tools-resources/develop/mplab-xc-compilers/xc16";
      platforms = ["x86_64-linux"];
      license = licenses.mit;
    };
  }
