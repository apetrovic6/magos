# github.com/nicobailon/pi-web-access -- web search, URL fetch, PDF/YouTube
# extraction.
#
# Needs a real node_modules: the published dist/index.js is bundled but still
# imports undici, linkedom, turndown, unpdf, defuddle, @mozilla/readability
# and promise.try at runtime, so mkPiExtension's plain copy is not enough.
# Entered through dist/, per its own `pi.extensions` manifest.
{pkgs}:
import ./mk-pi-package.nix {inherit pkgs;} {
  pname = "pi-web-access";
  version = "0.30.0";
  owner = "nicobailon";
  hash = "sha256-B8Ca1AH0OGM8nOKoWLI8Xukx0NNwU8FN84WzADa0v7c=";
  npmDepsHash = "sha256-QPJe24s+g2WmZn6a+6ZzIuoKNGB2bjTxRTje5H55EmE=";

  # dist/ is a build artifact; upstream only produces it on prepublish.
  npmBuildScript = "build";
  keep = ["dist" "package.json"];

  # The git tree declares pi.extensions = ["./index.ts"] so jiti transpiles
  # live during development; upstream's prepublishOnly flips it to ./dist
  # before packing. We vendor from the tag but ship only the built bundle,
  # so make the same flip -- otherwise pi finds no entry point and silently
  # loads nothing while still listing the package in `pi list`.
  piExtensions = ["./dist"];

  meta.description = "Web search, URL fetching and PDF extraction for pi";
}
