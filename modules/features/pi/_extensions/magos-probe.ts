// Smoke test for the vendoring path in ../default.nix. Extensions only load
// in a real session, but `pi --help` renders registered flags, so
//   pi --help | grep magos-probe
// confirms the Nix-built extensions directory was discovered -- no model and
// no TUI needed. Delete once real extensions prove the same thing.
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const where = `magos extensions loaded from ${import.meta.dirname}`;

  pi.registerFlag("magos-probe", {
    description: "Confirm the magos-vendored extensions directory loaded",
    handler: async () => {
      console.log(where);
    },
  });

  pi.registerCommand("magos-probe", {
    description: "Confirm the magos-vendored extensions directory loaded",
    handler: async (_args: string, ctx: any) => {
      ctx.ui.notify(where, "info");
    },
  });
}
