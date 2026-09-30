# github.com/nicobailon/pi-mcp-adapter -- MCP client for pi, which has no
# native MCP support.
#
# Unlike pi-web-access this ships no bundle: its `pi.extensions` manifest
# points at ./index.ts and pi compiles it through jiti, so the whole source
# tree is vendored and no build step runs.
{pkgs}:
import ./mk-pi-package.nix {inherit pkgs;} {
  pname = "pi-mcp-adapter";
  version = "2.36.0";
  owner = "nicobailon";
  hash = "sha256-PYRDVF5QcZFLJP9z5aYhzgWbuv9yvc0lt9tZKxhHyho=";
  npmDepsHash = "sha256-dXWD/tQpI2rHLs8I+RV8Zeq6ApIgHEtQih7TpakwxCg=";

  meta.description = "Model Context Protocol adapter for pi";
}
