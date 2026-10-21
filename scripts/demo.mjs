#!/usr/bin/env node
// Demo helper for the DevSecOps session. One script, five commands:
//   preflight   read-only checks before presenting
//   solution    copy the answer key into place (jump to the finished state)
//   reset       return infra/ and the pipeline to the starter state
//   break       simulate a teammate's typo that fails "terraform validate"
//   restore     undo "break"

import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const backupDir = path.join(root, '.demo-backup');
const tracked = ['infra/main.tf', '.github/workflows/infra.yml'];

const read = (rel) => fs.readFileSync(path.join(root, rel), 'utf8');
const run = (cmd, args) =>
  execFileSync(cmd, args, { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });

function preflight() {
  const results = [];
  const check = (name, fn) => {
    try {
      results.push({ ok: true, name, detail: fn() });
    } catch (err) {
      results.push({ ok: false, name, detail: err.message.split('\n')[0] });
    }
  };

  check('Terraform 1.7+ on PATH', () => {
    const version = JSON.parse(run('terraform', ['version', '-json'])).terraform_version;
    const [major, minor] = version.split('.').map(Number);
    if (major < 1 || (major === 1 && minor < 7)) throw new Error(`found ${version}`);
    return version;
  });
  check('Provider cached (run the "Infra: init" task once)', () => {
    if (!fs.existsSync(path.join(root, 'infra/.terraform/providers'))) throw new Error('infra/.terraform is missing');
    return 'cached';
  });
  check('Starter state: main.tf has no web app yet', () => {
    if (read('infra/main.tf').includes('azurerm_linux_web_app')) throw new Error('web app present. Run "Demo: reset"');
    return 'resource group only';
  });
  check('Starter state: pipeline is the stub', () => {
    if (read('.github/workflows/infra.yml').includes('environment: production')) throw new Error('full pipeline present. Run "Demo: reset"');
    return 'checkout and setup only';
  });
  check('Pipeline break is not active', () => {
    if (fs.existsSync(backupDir)) throw new Error('.demo-backup exists. Run "Demo: restore"');
    if (/\bvar\.env\b/.test(read('infra/main.tf'))) throw new Error('main.tf references var.env');
    return 'clean';
  });
  check('Starter validates', () => {
    run('terraform', ['-chdir=infra', 'fmt', '-check']);
    run('terraform', ['-chdir=infra', 'validate']);
    return 'fmt and validate pass';
  });
  check('Answer key hidden from Copilot search', () => {
    const settings = read('.vscode/settings.json');
    for (const needle of ['solutions', 'docs']) if (!settings.includes(`"${needle}/**"`)) throw new Error(`${needle} not in search.exclude`);
    return 'solutions and docs excluded';
  });
  check('Sample plan and CI log present', () => {
    for (const f of ['infra/samples/plan-forced-replacement.txt', 'infra/samples/failed-validate.log']) {
      if (!fs.existsSync(path.join(root, f))) throw new Error(`missing ${f}`);
    }
    return 'both present';
  });
  check('Solution validates', () => {
    const tmp = fs.mkdtempSync(path.join(root, '.preflight-'));
    try {
      fs.copyFileSync(path.join(root, 'solutions/infra/main.tf'), path.join(tmp, 'main.tf'));
      fs.cpSync(path.join(root, 'infra/.terraform'), path.join(tmp, '.terraform'), { recursive: true });
      fs.copyFileSync(path.join(root, 'infra/.terraform.lock.hcl'), path.join(tmp, '.terraform.lock.hcl'));
      run('terraform', [`-chdir=${tmp}`, 'validate']);
    } finally {
      fs.rmSync(tmp, { recursive: true, force: true });
    }
    return 'answer key is valid';
  });

  for (const r of results) console.log(`${r.ok ? 'PASS' : 'FAIL'}  ${r.name}  (${r.detail})`);
  const failed = results.filter((r) => !r.ok).length;
  console.log(failed ? `\n${failed} problem(s). Fix before presenting.` : '\nReady to present.');
  process.exit(failed ? 1 : 0);
}

function solution() {
  fs.copyFileSync(path.join(root, 'solutions/infra/main.tf'), path.join(root, 'infra/main.tf'));
  fs.copyFileSync(path.join(root, 'solutions/infra/.github/workflows/infra.yml'), path.join(root, '.github/workflows/infra.yml'));
  console.log('Answer key copied into infra/main.tf and .github/workflows/infra.yml');
}

function reset() {
  run('git', ['checkout', '--', ...tracked]);
  fs.rmSync(backupDir, { recursive: true, force: true });
  console.log('Reset to the starter state.');
}

function breakPipeline() {
  const file = 'infra/main.tf';
  const find = 'environment = var.environment\n    owner';
  const source = read(file);
  if (!source.includes(find)) {
    console.error(`Nothing to break: expected snippet not found in ${file} (already broken?)`);
    process.exit(1);
  }
  fs.mkdirSync(path.join(backupDir, 'infra'), { recursive: true });
  fs.copyFileSync(path.join(root, file), path.join(backupDir, file));
  fs.writeFileSync(path.join(root, file), source.replace(find, 'environment = var.env\n    owner'));
  console.log('Pipeline broken: a teammate renamed a variable reference in the tags block.');
  console.log('Reproduce the failing CI step:  terraform -chdir=infra validate');
}

function restore() {
  const backup = path.join(backupDir, 'infra/main.tf');
  if (!fs.existsSync(backup)) return console.log('Nothing to restore.');
  fs.copyFileSync(backup, path.join(root, 'infra/main.tf'));
  fs.rmSync(backupDir, { recursive: true, force: true });
  console.log('Restored infra/main.tf');
}

const commands = { preflight, solution, reset, break: breakPipeline, restore };
const cmd = process.argv[2];
if (!commands[cmd]) {
  console.error(`Usage: node scripts/demo.mjs <${Object.keys(commands).join('|')}>`);
  process.exit(1);
}
commands[cmd]();
