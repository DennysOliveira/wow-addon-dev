import * as fs from "node:fs";
import * as path from "node:path";
import { getWolfDir, ensureWolfDir, readJSON, writeJSON, readMarkdown, parseAnatomy, readStdin, normalizePath } from "./shared.js";
function getFileMtime(filePath) {
    try {
        return fs.statSync(filePath).mtimeMs;
    }
    catch {
        return undefined;
    }
}
async function main() {
    ensureWolfDir();
    const wolfDir = getWolfDir();
    const hooksDir = path.join(wolfDir, "hooks");
    const sessionFile = path.join(hooksDir, "_session.json");
    const raw = await readStdin();
    let input;
    try {
        input = JSON.parse(raw);
    }
    catch {
        process.exit(0);
        return;
    }
    const filePath = input.tool_input?.file_path ?? input.tool_input?.path ?? "";
    if (!filePath) {
        process.exit(0);
        return;
    }
    const normalizedFile = normalizePath(filePath);
    // Skip tracking for .wolf/ internal files — they're infrastructure, not project files.
    // Counting them inflates anatomy miss rates since .wolf/ is excluded from anatomy scanning.
    const projectDir = normalizePath(process.env.CLAUDE_PROJECT_DIR || process.cwd());
    const relToProject = normalizedFile.startsWith(projectDir)
        ? normalizedFile.slice(projectDir.length).replace(/^\//, "")
        : "";
    if (relToProject.startsWith(".wolf/") || relToProject.startsWith(".wolf\\")) {
        process.exit(0);
        return;
    }
    const session = readJSON(sessionFile, {
        session_id: "", files_read: {}, anatomy_hits: 0, anatomy_misses: 0,
        repeated_reads_warned: 0,
    });
    // Check if already read this session
    if (session.files_read[normalizedFile]) {
        const prev = session.files_read[normalizedFile];
        const currentMtime = getFileMtime(filePath);
        const fileChanged = currentMtime !== undefined && prev.mtime !== undefined && currentMtime !== prev.mtime;
        if (fileChanged) {
            // File was modified since last read (e.g. after an Edit) — allow re-read, update mtime
            process.stderr.write(`⚡ OpenWolf: re-reading ${path.basename(normalizedFile)} (file modified since last read)\n`);
            session.files_read[normalizedFile].mtime = currentMtime;
        }
        else {
            // File unchanged — block the re-read to save tokens
            process.stdout.write(JSON.stringify({
                decision: "block",
                message: `OpenWolf: ${path.basename(normalizedFile)} already read this session (~${prev.tokens} tok). Use existing context instead of re-reading.`,
            }));
            session.files_read[normalizedFile].count++;
            session.repeated_reads_warned++;
            writeJSON(sessionFile, session);
            process.exit(0);
            return;
        }
    }
    // Check anatomy.md for this file
    const anatomyContent = readMarkdown(path.join(wolfDir, "anatomy.md"));
    const sections = parseAnatomy(anatomyContent);
    let found = false;
    for (const [sectionKey, entries] of sections) {
        for (const entry of entries) {
            // Build the full relative path from the section key + filename for accurate matching
            const entryRelPath = normalizePath(path.join(sectionKey, entry.file));
            if (normalizedFile.endsWith(entryRelPath) || normalizedFile.endsWith("/" + entryRelPath)) {
                process.stderr.write(`📋 OpenWolf anatomy: ${entry.file} — ${entry.description} (~${entry.tokens} tok)\n`);
                found = true;
                break;
            }
        }
        if (found)
            break;
    }
    if (found) {
        session.anatomy_hits++;
    }
    else {
        session.anatomy_misses++;
    }
    // Record initial read entry (tokens will be updated in post-read)
    session.files_read[normalizedFile] = {
        count: 1,
        tokens: 0,
        first_read: new Date().toISOString(),
        mtime: getFileMtime(filePath),
    };
    writeJSON(sessionFile, session);
    process.exit(0);
}
main().catch(() => process.exit(0));
//# sourceMappingURL=pre-read.js.map