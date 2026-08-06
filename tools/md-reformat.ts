#!/usr/bin/env bun
/**
 * md-reformat — wrap every .md file in a semantic XML tag derived from its
 * filename, replacing the leading `# H1` header with the opening tag.
 *
 *   bun run tools/md-reformat.ts [paths...]        # dry-run (default)
 *   bun run tools/md-reformat.ts --apply           # write changes
 *
 * Frontmatter (--- … ---) is preserved above the tag. Already-wrapped files
 * are skipped, so the tool is safe to re-run.
 */

import { basename, relative } from "node:path";

const EXCLUDED = ["node_modules", ".git", "target", "build", ".svelte-kit", "dist"];
const H1 = /^#\s+.*$/m;
const FRONTMATTER = /^---\n[\s\S]*?\n---\n/;

type Result = { rel: string; tag: string; status: "wrap" | "skip" | "no-h1"; output: string };

function deriveTag(filePath: string): string {
  const stem = basename(filePath).replace(/\.md$/i, "");
  return stem.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
}

function splitFrontmatter(text: string): [string, string] {
  const match = text.match(FRONTMATTER);
  if (!match) return ["", text];
  return [match[0], text.slice(match[0].length)];
}

function stripFirstH1(body: string): { found: boolean; rest: string } {
  const match = body.match(H1);
  if (!match || match.index === undefined) return { found: false, rest: body };
  const before = body.slice(0, match.index);
  const after = body.slice(match.index + match[0].length).replace(/^\n+/, "");
  return { found: true, rest: (before + after).replace(/^\n+/, "") };
}

function transform(filePath: string, text: string): Omit<Result, "rel"> {
  const tag = deriveTag(filePath);
  const [front, body] = splitFrontmatter(text);
  if (body.trimStart().startsWith(`<${tag}>`)) return { tag, status: "skip", output: text };
  const { found, rest } = stripFirstH1(body);
  const wrapped = `<${tag}>\n${rest.trim()}\n</${tag}>\n`;
  return { tag, status: found ? "wrap" : "no-h1", output: front + wrapped };
}

async function discover(roots: string[]): Promise<string[]> {
  const glob = new Bun.Glob("**/*.md");
  const found = new Set<string>();
  for (const root of roots) await collect(glob, root, found);
  return [...found].sort();
}

async function collect(glob: Bun.Glob, root: string, into: Set<string>): Promise<void> {
  for await (const file of glob.scan({ cwd: root, absolute: true, dot: true })) {
    if (!EXCLUDED.some((d) => file.includes(`/${d}/`))) into.add(file);
  }
}

async function run(files: string[], apply: boolean): Promise<Result[]> {
  const results: Result[] = [];
  for (const file of files) results.push(await processOne(file, apply));
  return results;
}

async function processOne(file: string, apply: boolean): Promise<Result> {
  const text = await Bun.file(file).text();
  const { tag, status, output } = transform(file, text);
  const rel = relative(process.cwd(), file);
  if (apply && status !== "skip") await Bun.write(file, output);
  return { rel, tag, status, output };
}

function report(results: Result[], apply: boolean): void {
  const icon = { wrap: "✎", skip: "·", "no-h1": "!" } as const;
  for (const r of results) console.log(`  ${icon[r.status]} ${r.rel}  →  <${r.tag}>`);
  const wrapped = results.filter((r) => r.status !== "skip").length;
  const verb = apply ? "rewrote" : "would rewrite";
  console.log(`\n${verb} ${wrapped}/${results.length} file(s). ` + (apply ? "" : "Re-run with --apply to write."));
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);
  const apply = args.includes("--apply");
  const roots = args.filter((a) => !a.startsWith("--"));
  const files = await discover(roots.length ? roots : [process.cwd()]);
  if (!files.length) return console.log("No .md files found.");
  report(await run(files, apply), apply);
}

main();
