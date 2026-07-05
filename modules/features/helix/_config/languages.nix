{
  language = [
    {
      name = "nix";
      language-servers = ["nixd"];
      formatter = {
        command = "alejandra";
        args = ["."];
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
