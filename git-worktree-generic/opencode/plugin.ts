/**
 * Git Worktree Manager — OpenCode Plugin
 *
 * Exposes the worktree-manager.sh script as an OpenCode tool.
 * The AI can create, list, migrate and cleanup worktrees on request.
 *
 * Installation:
 *   mkdir -p ~/.config/opencode/plugins/git-worktree
 *   cp plugin.ts ~/.config/opencode/plugins/git-worktree/
 *   cp ../worktree-manager.sh ~/.local/share/git-worktree/worktree-manager.sh
 *   chmod +x ~/.local/share/git-worktree/worktree-manager.sh
 *
 * Then register in ~/.config/opencode/config.json:
 *   { "plugins": ["~/.config/opencode/plugins/git-worktree/plugin.ts"] }
 */

import { tool } from "@opencode-ai/plugin";
import { execSync } from "child_process";
import { homedir } from "os";

const SCRIPT = `${homedir()}/.local/share/git-worktree/worktree-manager.sh`;

function runWorktree(args: string, cwd?: string): string {
  try {
    return execSync(`bash ${SCRIPT} ${args}`, {
      encoding: "utf-8",
      cwd: cwd ?? process.cwd(),
      env: { ...process.env },
    });
  } catch (err: any) {
    return err.stdout ?? err.message ?? String(err);
  }
}

export default async () => ({
  tool: {
    worktree_create: tool({
      description:
        "Create a new git worktree for a feature or fix branch. " +
        "Automatically copies .env files and symlinks vendor/. " +
        "Use this when the user wants to start working on a new branch in isolation.",
      args: {
        branch: tool.schema
          .string()
          .describe(
            "Branch name, e.g. feat/ALM-1234/my-feature or fix/ALM-5678/hotfix"
          ),
        from_branch: tool.schema
          .string()
          .optional()
          .describe("Base branch to branch from. Defaults to main."),
      },
      async execute({ branch, from_branch }) {
        const args = from_branch ? `create ${branch} ${from_branch}` : `create ${branch}`;
        return runWorktree(args);
      },
    }),

    worktree_migrate: tool({
      description:
        "Move uncommitted changes from the current directory into a new worktree. " +
        "Use this when the user has already started coding but hasn't created a branch yet " +
        "(e.g. accidentally working on main). " +
        "Performs: stash → create worktree → stash pop.",
      args: {
        branch: tool.schema
          .string()
          .describe("Target branch name for the new worktree"),
        from_branch: tool.schema
          .string()
          .optional()
          .describe("Base branch. Defaults to main."),
      },
      async execute({ branch, from_branch }, ctx) {
        const args = from_branch
          ? `migrate ${branch} ${from_branch}`
          : `migrate ${branch}`;
        return runWorktree(args, ctx.worktree ?? process.cwd());
      },
    }),

    worktree_list: tool({
      description:
        "List all active git worktrees with their branch names and paths.",
      args: {},
      async execute() {
        return runWorktree("list");
      },
    }),

    worktree_copy_env: tool({
      description:
        "Copy .env files from the main repository to an existing worktree. " +
        "Useful when .env files were updated after the worktree was created.",
      args: {
        branch: tool.schema
          .string()
          .optional()
          .describe(
            "Worktree branch name. If omitted, auto-detected from current directory."
          ),
      },
      async execute({ branch }) {
        return runWorktree(branch ? `copy-env ${branch}` : "copy-env");
      },
    }),

    worktree_cleanup: tool({
      description:
        "List inactive worktrees and remove them. " +
        "Use this when the user wants to clean up finished branches.",
      args: {},
      async execute() {
        // Non-interactive: list what would be removed
        return runWorktree("list") + "\n\nRun: bash " + SCRIPT + " cleanup";
      },
    }),
  },
});
