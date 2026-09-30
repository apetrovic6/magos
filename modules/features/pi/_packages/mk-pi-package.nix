# Shared builder for third-party pi packages vendored from GitHub.
#
# These all trip over the same thing: their package-lock.json pins the
# @earendil-works/pi-* packages without an `integrity` field, and
# prefetch-npm-deps panics on it with
#
#   non-git dependencies should have associated integrity
#
# Those pins are only ever dev/peer dependencies -- pi injects its own runtime
# into extensions and the docs say not to bundle it -- so dropping every
# entry that has no integrity both fixes the panic and avoids shipping a
# second, stale copy of the pi runtime beside the one in the wrapper.
{pkgs}: {
  pname,
  version,
  owner,
  repo ? pname,
  hash,
  npmDepsHash,
  # null runs no build; pi loads TypeScript sources through jiti, so a package
  # whose `pi.extensions` points at .ts needs no compile step.
  npmBuildScript ? null,
  # devDependencies are the build toolchain, so they can only be dropped when
  # nothing is built. Dropping them shrinks the closure a lot -- these locks
  # carry the whole pi runtime (aws-sdk, esbuild, openai) as dev deps.
  omitDev ? npmBuildScript == null,
  # Rewrites .pi.extensions in the installed manifest. Needed when a package
  # publishes a different entry point than its git tree declares -- upstream
  # publish lifecycles commonly flip this between ./dist and ./src.
  piExtensions ? null,
  # Paths copied into $out beside node_modules. null copies the whole tree,
  # which is what a package entered through its .ts sources needs.
  keep ? null,
  meta ? {},
}: let
  omitFlags = ["--omit=peer"] ++ pkgs.lib.optional omitDev "--omit=dev";
  # Keep the root entry ("") -- it never carries an integrity field.
  lockFilter =
    "select(.key == \"\" or (.value.integrity != null"
    + pkgs.lib.optionalString omitDev " and .value.dev != true"
    + "))";
  dropSections =
    "del(.peerDependencies" + pkgs.lib.optionalString omitDev ", .devDependencies" + ")";
in
  pkgs.buildNpmPackage {
    inherit pname version npmDepsHash meta;

    src = pkgs.fetchFromGitHub {
      inherit owner repo hash;
      tag = "v${version}";
    };

    postPatch = ''
      ${pkgs.jq}/bin/jq '.packages |= with_entries(${lockFilter}) | .packages."" |= ${dropSections}' \
        package-lock.json > package-lock.json.tmp
      mv package-lock.json.tmp package-lock.json
      ${pkgs.jq}/bin/jq '${dropSections}' package.json > package.json.tmp
      mv package.json.tmp package.json
    '';

    npmFlags = omitFlags;

    dontNpmBuild = npmBuildScript == null;
    dontNpmInstall = true;
    ${
      if npmBuildScript != null
      then "npmBuildScript"
      else null
    } =
      npmBuildScript;

    installPhase = ''
      runHook preInstall
      npm prune --omit=dev --omit=peer
      mkdir -p $out
      ${
        if keep != null
        then "cp -r ${builtins.concatStringsSep " " keep} node_modules $out/"
        else ''
          shopt -s dotglob
          cp -r ./* $out/
        ''
      }
      ${pkgs.lib.optionalString (piExtensions != null) ''
        ${pkgs.jq}/bin/jq '.pi.extensions = ${builtins.toJSON piExtensions}' \
          $out/package.json > $out/package.json.tmp
        mv $out/package.json.tmp $out/package.json
      ''}
      runHook postInstall
    '';
  }
