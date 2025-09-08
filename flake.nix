{
  description = "A Flake of a small wrapper around Zotero translation server that adds support for fetching attachments and can be run from the command-line. ";
  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      zotraPackage = pkgs.buildNpmPackage {
        pname = "zotra-server";
        version = "1.0.0";

        src = ./.;

        npmDepsHash = "sha256-pr8fkhAwQ5xL3F+El6PIoGI/ZPzWd6Sgujnuyc2wiKk=";
        nodejs = pkgs.nodejs_22;
        makeCacheWritable = true;
        dontNpmBuild = true;

        preFixup = ''
          rm $out/lib/node_modules/zotra/node_modules/translation-server
        '';

        meta = with pkgs.lib; {
          description = "Node.js-based server to run Zotero translators";
          homepage = "https://github.com/ethanmoss1/zotra-server";
          license = licenses.agpl3Only;
          maintainers = [ ];
          mainProgram = "zotra";
        };
      };

      zotraModule = { config, lib, ... }:
        let cfg = config.services.zotra; in
        {
          options.services.zotra = {
            enable = lib.mkEnableOption "A Node.js-based server to run Zotero translators";
          };
          config = lib.mkIf cfg.enable {
            systemd.services.zotra = {
              description = "Systemd service to manage a Node.js-based server that runs Zotero translators";
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "exec";
                ExecStart = "${zotraPackage}/bin/zotra server";
                Restart = "always";
              };
            };
            environment.systemPackages = [ zotraPackage ];
          };
        };
    in
      {
        packages.${system}.default = zotraPackage;
        nixosModules.zotra = zotraModule;
      };
}
