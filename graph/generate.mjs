#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve, sep } from "node:path";

const repo = resolve(process.argv[2] ?? join(import.meta.dirname, ".."));
const output = resolve(process.argv[3] ?? join(import.meta.dirname, "dependency-data.js"));
const errors = [];

function nixEval(attribute, expression) {
  try {
    const stdout = execFileSync(
      "nix",
      ["eval", "--impure", "--json", attribute, "--apply", expression],
      {
        cwd: repo,
        encoding: "utf8",
        env: process.env,
        maxBuffer: 64 * 1024 * 1024,
        stdio: ["ignore", "pipe", "pipe"],
      },
    );
    return JSON.parse(stdout);
  } catch (error) {
    const stderr = error?.stderr?.toString().trim();
    errors.push(`${attribute}: ${stderr || error.message}`);
    return null;
  }
}

function walkNixFiles(directory) {
  const files = [];
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if ([".git", ".direnv", "result", "node_modules"].includes(entry.name)) continue;
    const absolute = join(directory, entry.name);
    if (entry.isSymbolicLink()) continue;
    if (entry.isDirectory()) files.push(...walkNixFiles(absolute));
    else if (entry.isFile() && entry.name.endsWith(".nix")) files.push(absolute);
  }
  return files;
}

function localReferences() {
  const references = [];
  for (const file of walkNixFiles(repo)) {
    const source = readFileSync(file, "utf8");
    const candidates = source.match(/(?:\.\.\/|\.\/)[A-Za-z0-9_@+./-]+/g) ?? [];
    const targets = new Set();

    for (let candidate of candidates) {
      candidate = candidate.replace(/[.;,]+$/, "");
      const absolute = resolve(dirname(file), candidate);
      if (!existsSync(absolute)) continue;
      const target = relative(repo, absolute).split(sep).join("/");
      if (target.startsWith("../")) continue;
      targets.add(target);
    }

    if (targets.size > 0) {
      references.push({
        file: relative(repo, file).split(sep).join("/"),
        targets: [...targets].sort(),
      });
    }
  }
  return references.sort((a, b) => a.file.localeCompare(b.file));
}

function describeLock() {
  const lock = JSON.parse(readFileSync(join(repo, "flake.lock"), "utf8"));
  const root = lock.nodes[lock.root];

  return Object.entries(root.inputs).map(([name, nodeKey]) => {
    const resolvedKey = Array.isArray(nodeKey) ? nodeKey.at(-1) : nodeKey;
    const node = lock.nodes[resolvedKey] ?? {};
    const original = node.original ?? {};
    const locked = node.locked ?? {};
    const source = original.owner && original.repo
      ? `${original.owner}/${original.repo}${original.ref ? `/${original.ref}` : ""}`
      : original.url ?? original.path ?? original.type ?? "unknown";

    const dependencies = Object.entries(node.inputs ?? {}).map(([inputName, target]) => ({
      name: inputName,
      target: Array.isArray(target) ? target.join("/") : target,
      follows: Array.isArray(target),
    }));

    return {
      name,
      node: resolvedKey,
      source,
      revision: locked.rev ?? null,
      shortRevision: locked.rev?.slice(0, 12) ?? null,
      lastModified: locked.lastModified
        ? new Date(locked.lastModified * 1000).toISOString()
        : null,
      narHash: locked.narHash ?? null,
      dependencies,
    };
  });
}

const packageName = `p: p.name or p.pname or "<unnamed>"`;
const nixosExpression = `configs: builtins.mapAttrs (name: value: let
  cfg = value.config;
  packageName = ${packageName};
in {
  system = cfg.nixpkgs.hostPlatform.system;
  stateVersion = cfg.system.stateVersion;
  systemPackages = map packageName cfg.environment.systemPackages;
  userPackages = map packageName (cfg.users.users.razero.packages or []);
  homePackages = map packageName (cfg.home-manager.users.razero.home.packages or []);
  systemdServices = builtins.attrNames cfg.systemd.services;
}) configs`;

const homeExpression = `configs: builtins.mapAttrs (name: value: let
  packageName = ${packageName};
in {
  packages = map packageName value.config.home.packages;
  stateVersion = value.config.home.stateVersion;
}) configs`;

const shellExpression = `systems: builtins.mapAttrs (_: shells:
  builtins.mapAttrs (_: shell: let
    packageName = ${packageName};
    inputs = (shell.nativeBuildInputs or []) ++ (shell.buildInputs or []);
  in { packages = map packageName inputs; }) shells
) systems`;

const data = {
  schemaVersion: 1,
  generatedAt: new Date().toISOString(),
  repository: repo,
  inputs: describeLock(),
  nixosConfigurations: nixEval(".#nixosConfigurations", nixosExpression) ?? {},
  homeConfigurations: nixEval(".#homeConfigurations", homeExpression) ?? {},
  devShells: nixEval(".#devShells", shellExpression) ?? {},
  localReferences: localReferences(),
  errors,
};

const serialized = JSON.stringify(data, null, 2).replaceAll("<", "\\u003c");
writeFileSync(
  output,
  `// Generated by graph/update.sh. Do not edit by hand.\nwindow.NIX_GRAPH_DATA = ${serialized};\n`,
);

const packageCount = Object.values(data.nixosConfigurations)
  .reduce((sum, config) => sum + config.systemPackages.length, 0);
console.log(`Wrote ${relative(repo, output)}`);
console.log(`Inputs: ${data.inputs.length}`);
console.log(`NixOS configurations: ${Object.keys(data.nixosConfigurations).length}`);
console.log(`Evaluated system packages: ${packageCount}`);
console.log(`Local reference edges: ${data.localReferences.reduce((n, item) => n + item.targets.length, 0)}`);
if (errors.length > 0) {
  console.warn(`Completed with ${errors.length} evaluation error(s). See the generated page.`);
}
