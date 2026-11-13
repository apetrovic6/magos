{...}: let
  # Agent Skills (a directory holding a SKILL.md), shared by every coding agent
  # magos sets up. Each value is a skill directory; the name is the directory
  # it is installed as, and should match the `name:` in its frontmatter.
  #
  # To add one: a path to a directory in this repo, or a subdirectory of a
  # package's source, so the skill moves in step with the tool it describes.
  mkSkills = pkgs: {
    # Teaches an agent running in a herdr pane to drive herdr: split panes,
    # start and prompt other agents, wait on them and read their output. From
    # the source of the same herdr build the server runs, so its CLI syntax
    # matches the installed binary. It only triggers when herdr is named.
    herdr = "${pkgs.herdr.src}/skills/herdr";

    # Keeps a Claude Code that an agent starts outside its own process (a
    # herdr pane, a new terminal) on the session's account, via claude-as
    # (modules/features/claude-accounts).
    claude-accounts = ../claude-accounts/skill;
  };
in {
  # Installs the skills for every agent at once:
  #   - ~/.agents/skills/<name>, the shared Agent Skills location, which pi
  #     and omp both discover.
  #   - programs.claude-code.skills, since Claude Code reads only its own
  #     ~/.claude/skills. Skipped when programs.claude-code is not enabled.
  #
  #   imports = [inputs.magos.homeModules.skills];
  #   magos.skills.enable = true;
  flake.homeModules.skills = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.magos.skills;
    skills = mkSkills pkgs // cfg.extra;
  in {
    options.magos.skills = {
      enable = lib.mkEnableOption "the magos Agent Skills for Claude Code, pi and omp";

      extra = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = {};
        example = lib.literalExpression ''{ my-skill = ./skills/my-skill; }'';
        description = ''
          More skill directories, installed alongside the magos ones. Each
          must contain a SKILL.md. A name already in magos replaces it.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      home.file = lib.mapAttrs' (name: path:
        lib.nameValuePair ".agents/skills/${name}" {source = path;})
      skills;

      programs.claude-code.skills =
        lib.mkIf config.programs.claude-code.enable skills;
    };
  };

  # The same set as one directory, one folder per skill, for an agent that
  # takes a skills path instead (`nix build .#agent-skills`).
  perSystem = {pkgs, ...}: {
    packages.agent-skills = pkgs.linkFarm "agent-skills" (mkSkills pkgs);
  };
}
