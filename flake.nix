{
	description = "Nolawz's configuration using home manager";
	inputs = {
		nixpkgs.url = "nixpkgs/nixos-unstable";
    qylock.url = "github:Darkkal44/qylock";
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
      url = "github:noctalia-dev/noctalia";
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

	outputs = { nixpkgs, home-manager, qylock, sops-nix, self, ... }@inputs:
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
            go
            gcc
            clang-tools
            clang
            cmake
            zlib
            zstd
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
            libcaca
            libcanberra
            libgcrypt
            libvpx
            librsvg
            libXft
            libvdpau

            wayland
            egl-wayland

            capstone
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

            pkgsi686Linux.stdenv.cc.cc.lib
            pkgsi686Linux.zlib
            pkgsi686Linux.glib
            pkgsi686Linux.glibc
            pkgsi686Linux.openssl
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
        
        home-manager.nixosModules.home-manager

        {
          home-manager.users.nolawz = {
            imports = [
              ./home.nix
              inputs.spicetify-nix.homeManagerModules.default
              inputs.sops-nix.homeManagerModule
              inputs.nyaa.homeManagerModule
            ];
          };

          home-manager.extraSpecialArgs = {
            inherit inputs;
          };

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }

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

		# homeConfigurations = {
		# 	nolawz = home-manager.lib.homeManagerConfiguration {
		# 		inherit pkgs;
		# 		extraSpecialArgs = { inherit inputs; };
		# 		modules = [
		#         inputs.spicetify-nix.homeManagerModules.default
		#         ./home.nix
		#         inputs.sops-nix.homeManagerModule
		#         inputs.nyaa.homeManagerModule
		#       ];
		# 	};
		# };
	};
}

