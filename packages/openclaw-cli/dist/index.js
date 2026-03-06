"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const commander_1 = require("commander");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const yaml = __importStar(require("yaml"));
const child_process_1 = require("child_process");
const program = new commander_1.Command();
const OPENCLAW_DIR = path.resolve(__dirname, "..", "..", "..");
function output(data, options) {
    if (options.json) {
        console.log(JSON.stringify(data, null, 2));
    }
    else if (data.message) {
        console.log(data.message);
    }
}
function findAo() {
    try {
        (0, child_process_1.execSync)("which ao", { stdio: "pipe" });
        return "ao";
    }
    catch {
        const localAo = path.join(OPENCLAW_DIR, "packages/agent-orchestrator/packages/cli/dist/index.js");
        if (fs.existsSync(localAo))
            return "node " + localAo;
    }
    return null;
}
function findDesloppify() {
    try {
        (0, child_process_1.execSync)("which desloppify", { stdio: "pipe" });
        return "desloppify";
    }
    catch {
        return null;
    }
}
program
    .name("workflow")
    .description("OpenClaw Workflow Unified CLI")
    .version("2.0.0")
    .option("--json", "Output JSON")
    .option("-y, --non-interactive", "No prompts")
    .option("-v, --verbose", "Verbose output")
    .option("-p, --project [name]", "Project name");
program
    .command("init [name]")
    .description("Initialize OpenClaw project")
    .action(async (name, options) => {
    const opts = { ...program.opts(), ...options };
    const projectName = name || opts.project || path.basename(process.cwd());
    if (fs.existsSync(".openclaw/config.yaml")) {
        output({ success: false, error: "Already initialized" }, opts);
        process.exit(1);
    }
    fs.mkdirSync(".openclaw", { recursive: true });
    fs.mkdirSync("docs/prd", { recursive: true });
    fs.mkdirSync("docs/forge", { recursive: true });
    fs.mkdirSync("src", { recursive: true });
    const config = {
        project: { name: projectName, created: new Date().toISOString() },
        workflow: { prd: "bmad", orchestration: "ao", implementation: "forge", quality: "desloppify" },
        paths: { prd: "docs/prd", forge: "docs/forge", src: "src" }
    };
    fs.writeFileSync(".openclaw/config.yaml", yaml.stringify(config));
    fs.writeFileSync(".gitignore", ".openclaw/sessions\n.claude/forge/snapshots\n.desloppify\nnode_modules\n");
    output({ success: true, message: "Initialized: " + projectName, project: projectName }, opts);
});
program
    .command("prd [content...]")
    .description("Create PRD from content or OPENCLAW_PRD_CONTENT env var")
    .action(async (content, options) => {
    const opts = { ...program.opts(), ...options };
    if (!fs.existsSync(".openclaw/config.yaml")) {
        output({ success: false, error: "Run workflow init first" }, opts);
        process.exit(1);
    }
    const prdContent = process.env.OPENCLAW_PRD_CONTENT || content.join(" ");
    const prdTemplate = "---\nproject_name: " + path.basename(process.cwd()) + "\ncreated: " + new Date().toISOString() + "\nworkflow: bmad\n---\n\n# Product Requirements Document\n\n## Executive Summary\n" + (prdContent || "TODO: Add summary") + "\n\n## Functional Requirements\n\n## Non-Functional Requirements\n\n## User Journeys\n\n## Success Metrics\n";
    fs.writeFileSync("docs/prd.md", prdTemplate);
    output({ success: true, message: "PRD created: docs/prd.md", file: "docs/prd.md" }, opts);
});
program
    .command("status")
    .description("Show workflow status")
    .action(async (options) => {
    const opts = { ...program.opts(), ...options };
    const status = {
        initialized: fs.existsSync(".openclaw/config.yaml"),
        prd: fs.existsSync("docs/prd.md"),
        ao: !!findAo(),
        forge: fs.existsSync(".claude/forge"),
        desloppify: !!findDesloppify()
    };
    if (opts.json) {
        output({ success: true, status }, opts);
    }
    else {
        console.log("Status:");
        Object.entries(status).forEach(([k, v]) => console.log("  " + (v ? "✓" : "✗") + " " + k));
    }
});
program
    .command("doctor")
    .description("Health check")
    .action(async (options) => {
    const opts = { ...program.opts(), ...options };
    const checks = { node: false, pnpm: false, python: false, ao: false, forge: false, bmad: false, desloppify: false };
    try {
        (0, child_process_1.execSync)("node --version", { stdio: "pipe" });
        checks.node = true;
    }
    catch { }
    try {
        (0, child_process_1.execSync)("pnpm --version", { stdio: "pipe" });
        checks.pnpm = true;
    }
    catch { }
    try {
        (0, child_process_1.execSync)("python3 --version", { stdio: "pipe" });
        checks.python = true;
    }
    catch { }
    checks.ao = !!findAo();
    checks.forge = fs.existsSync(path.join(OPENCLAW_DIR, "packages/forge-ao/.claude-plugin/plugin.json"));
    checks.bmad = fs.existsSync(path.join(OPENCLAW_DIR, "packages/bmad-openclaw/package.json"));
    checks.desloppify = !!findDesloppify();
    const allGood = Object.values(checks).every(v => v);
    if (opts.json) {
        output({ success: allGood, checks }, opts);
    }
    else {
        console.log("Health Check:");
        Object.entries(checks).forEach(([k, v]) => console.log("  " + (v ? "✓" : "✗") + " " + k));
    }
    process.exit(allGood ? 0 : 1);
});
program.parse();
