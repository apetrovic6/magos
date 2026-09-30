# pi.dev/packages/@a5c-ai/babysitter-pi -- workflow orchestration with
# event-sourced state and human-in-the-loop approval.
#
# The easy kind of pi package: its package.json declares no `dependencies` at
# all, and the one peer dependency (@earendil-works/pi-coding-agent) is
# injected by pi. Nothing to resolve, so this skips mk-pi-package.nix and
# buildNpmPackage entirely and just unpacks the published tarball.
#
# Taken from the npm tarball rather than the git tag because that tarball is
# the published artifact -- the same bytes `pi install npm:@a5c-ai/
# babysitter-pi` would fetch -- and needs no build step.
#
# Its manifest declares both `extensions` and `skills`, which is why this
# belongs in settings.packages: entered as a bare extensions dir, the skills
# would be dropped.
{pkgs}: let
  pname = "pi-babysitter";
  version = "6.0.3";
in
  pkgs.runCommand "${pname}-${version}" {
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@a5c-ai/babysitter-pi/-/babysitter-pi-${version}.tgz";
      hash = "sha256-TfDxPoZXE0hjjKouasd5wM01W/87y3pKk0K1CAcqT1I=";
    };
    meta.description = "Workflow orchestration for pi";
  } ''
    mkdir -p $out
    tar -xzf $src --strip-components=1 -C $out
  ''
