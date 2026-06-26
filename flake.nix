{
	description = "Nolawz's configuration using home manager";
	inputs = {
		nixpkgs.url = "nixpkgs/nixos-unstable";
    qylock.url = "github:Darkkal44/qylock";
    nvf.url = "github:notashelf/nvf";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";

    grub-of-tsushima = {
      url = "github:ivanimmanuel-dev/grub-of-tsushima";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    curd = {
        url = "github:Wraient/curd";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    nyaa = {
      url = "github:Beastwick18/nyaa";
      inputs.nixpkgs.follows = "nixpkgs";
    };

		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		zen-browser = {
			url = "github:youwen5/zen-browser-flake";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { nixpkgs, home-manager, qylock, nvf, sops-nix, self, ... }@inputs:
		let 
			system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
        };
      };
		in {
      packages.x86_64-linux.ida-env =
      pkgs.buildFHSEnv {
        name = "ida-env";

        targetPkgs = pkgs: with pkgs; [
            zlib
            zstd
            stdenv.cc.cc
            curl
            openssl
            attr
            libssh
            bzip2
            libxml2
            acl
            libsodium
            util-linux
            xz
            systemd

            xcbutil
            xcbutilwm
            xcbutilimage
            xcbutilkeysyms
            xcbutilrenderutil
            xcbutilcursor

            # My own additions
            libXcomposite
            libXtst
            libXrandr
            libXext
            libX11
            libXfixes
            libGL
            libva
            pipewire
            libxcb
            libXdamage
            libxshmfence
            libXxf86vm
            libelf
            
            # Required
            glib
            gtk2
            
            # Without these it silently fails
            libXinerama
            libXcursor
            libXrender
            libXScrnSaver
            libXi
            libSM
            libICE
            nspr
            nss
            cups
            libcap
            SDL2
            libusb1
            dbus-glib
            ffmpeg
            # Only libraries are needed from those two
            libudev0-shim

            # needed to run unity
            gtk3
            icu
            libnotify
            gsettings-desktop-schemas
            # https://github.com/NixOS/nixpkgs/issues/72282
            # https://github.com/NixOS/nixpkgs/blob/2e87260fafdd3d18aa1719246fd704b35e55b0f2/pkgs/applications/misc/joplin-desktop/default.nix#L16
            # log in /home/leo/.config/unity3d/Editor.log
            # it will segfault when opening files if you don’t do:
            # export XDG_DATA_DIRS=/nix/store/0nfsywbk0qml4faa7sk3sdfmbd85b7ra-gsettings-desktop-schemas-43.0/share/gsettings-schemas/gsettings-desktop-schemas-43.0:/nix/store/rkscn1raa3x850zq7jp9q3j5ghcf6zi2-gtk+3-3.24.35/share/gsettings-schemas/gtk+3-3.24.35/:$XDG_DATA_DIRS
            # other issue: (Unity:377230): GLib-GIO-CRITICAL **: 21:09:04.706: g_dbus_proxy_call_sync_internal: assertion 'G_IS_DBUS_PROXY (proxy)' failed
            
            # Verified games requirements
            libXt
            libXmu
            libogg
            libvorbis
            SDL
            SDL2_image
            glew_1_10
            libidn
            tbb
            
            # Other things from runtime
            flac
            freeglut
            libjpeg
            libpng
            libpng12
            libsamplerate
            libmikmod
            libtheora
            libtiff
            pixman
            speex
            SDL_image
            SDL_ttf
            SDL_mixer
            SDL2_ttf
            SDL2_mixer
            libappindicator-gtk2
            libdbusmenu-gtk2
            libindicator-gtk2
            libcaca
            libcanberra
            libgcrypt
            libvpx
            librsvg
            libXft
            libvdpau
            # ...
            # Some more libraries that I needed to run programs
            cairo
            atk
            gdk-pixbuf
            fontconfig
            freetype
            dbus
            expat
            # Needed for electron
            libdrm
            mesa
            libxkbcommon
            # Needed to run, via virtualenv + pip, matplotlib & tikzplotlib
            stdenv.cc.cc.lib # to provide libstdc++.so.6
            pkgs.gcc-unwrapped.lib
        ];

        runScript = "zsh";
      };

			nixosConfigurations.nolawz-pc = nixpkgs.lib.nixosSystem {
			inherit system;
			specialArgs = {
				inherit inputs;
			};
			modules = [
				./configuration.nix
        qylock.nixosModules.default
        ({ pkgs, ... }: {
          services.displayManager.sddm.enable = true;
          services.displayManager.sddm.wayland.enable = true;

          programs.qylock = {
            enable = true;
            theme = "sword";

            themeOptions = {
              terraria.backgroundMode = "time";              # time | random | static
              Genshin.backgroundMode = "time";
              clockwork.orbital = { themeMode = "dark"; enableWindup = true; };
              osu.gameMode = "menu";                         # menu | game
            };
          };
        })
			];

		};

		homeConfigurations = {
			nolawz = home-manager.lib.homeManagerConfiguration {
				inherit pkgs;
				extraSpecialArgs = { inherit inputs; };
				modules = [
          nvf.homeManagerModules.default #
          inputs.spicetify-nix.homeManagerModules.default
          ./home.nix
          inputs.sops-nix.homeManagerModule
          inputs.nyaa.homeManagerModule
        ];
			};
		};
	};
}

