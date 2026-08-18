{
  language = [
    {
      name = "nix";
      language-servers = ["nixd"];
      # `-` is load-bearing: it puts alejandra in stdin->stdout mode, which is
      # the contract Helix expects (buffer in, replacement buffer out).
      #
      # An include PATH here instead -- `args = ["."]` -- is a different mode
      # entirely: alejandra ignores stdin, rewrites every .nix file under the cwd
      # in place, and prints a `Formatted: <path>` line per changed file to
      # stdout. Helix then takes that as the new buffer, so saving any .nix file
      # replaces it with the name of some *other* file. It destroyed a 190-line
      # file that way.
      #
      # `-q` silences the informational chatter (it goes to stderr, so stdout is
      # clean either way, but alejandra itself suggests it).
      formatter = {
        command = "alejandra";
        args = ["-q" "-"];
      };
      auto-format = true;
    }
    {
      name = "yaml";
      file-types = ["yaml" "yml"];
      language-servers = ["yaml-language-server"];
    }
    {
      name = "rust";
      file-types = ["rs"];
      language-servers = ["rust-analyzer"];
    }
  ];

  language-server.yaml-language-server = {
    command = "yaml-language-server";
    args = ["--stdio"];
    config.yaml = {
      validate = true;
      hover = true;
      completion = true;
      format.enable = true;
      schemas = {
        kubernetes = [
          "*deployment*.yaml"
          "*service*.yaml"
          "*.y{a,}ml"
          "*configmap*.yaml"
          "*secret*.yaml"
          "*pod*.yaml"
          "*namespace*.yaml"
          "*ingress*.yaml"
        ];
        "https://raw.githubusercontent.com/SchemaStore/schemastore/master/src/schemas/json/kustomization.json" = [
          "*kustomization.yaml"
          "*kustomize.yaml"
        ];
        "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" = [
          "*workflow*.yaml"
          "*template*.yaml"
        ];
      };
    };
  };

  language-server.rust-analyzer = {
    config = {check.command = "clippy";};
  };
}
