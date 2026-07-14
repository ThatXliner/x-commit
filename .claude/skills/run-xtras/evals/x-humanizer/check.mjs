#!/usr/bin/env node
// Deterministic grader for x-humanizer output.
// Each check encodes one rule from skills/x-humanizer/SKILL.md.
// Usage: node check.mjs <rewritten-file>
import { readFileSync } from "node:fs";

const file = process.argv[2];
const text = readFileSync(file, "utf8");
const failures = [];

const paragraphs = text
  .split(/\n\s*\n/)
  .map((p) => p.replace(/\s+/g, " ").trim())
  .filter((p) => p && !/^(#|[-*] |\d+\. |>)/.test(p)); // skip headings/lists/quotes

const sentencesOf = (p) =>
  p.split(/(?<=[.!?])\s+/).map((s) => s.trim()).filter(Boolean);

const words = (s) => s.split(/\s+/).filter(Boolean).length;

// Rule 4: no em-dashes as dramatic pauses.
if (text.includes("—") || / -- /.test(text)) {
  failures.push("em-dash (or ' -- ') present");
}

// Rule 3: no one-sentence paragraphs.
for (const p of paragraphs) {
  if (sentencesOf(p).length < 2) {
    failures.push(`one-sentence paragraph: "${p.slice(0, 60)}..."`);
  }
}

for (const p of paragraphs) {
  const sents = sentencesOf(p);

  // Rule 1 (heuristic): fragments are usually very short "sentences".
  for (const s of sents) {
    if (words(s) <= 3) failures.push(`likely fragment: "${s}"`);
  }

  // Rule 2: staccato — two consecutive short sentences.
  for (let i = 0; i + 1 < sents.length; i++) {
    if (words(sents[i]) <= 6 && words(sents[i + 1]) <= 6) {
      failures.push(`staccato pair: "${sents[i]} ${sents[i + 1]}"`);
    }
  }

  // Rule 5: list-style sentences — 3+ consecutive same-opener sentences.
  for (let i = 0; i + 2 < sents.length; i++) {
    const opener = (s) => s.split(/\s+/).slice(0, 2).join(" ").toLowerCase();
    if (opener(sents[i]) === opener(sents[i + 1]) && opener(sents[i]) === opener(sents[i + 2])) {
      failures.push(`list-style run starting: "${sents[i]}"`);
    }
  }
}

// Vocabulary tells (rule 7, added via red-green).
const banned = [
  /\bdelve\b/i,
  /\btapestry\b/i,
  /\bgame.?changer\b/i,
  /\bseamless(ly)?\b/i,
  /\bleverag(e|es|ing)\b/i,
  /\bin today's\b/i,
  /\bit'?s (important|worth) (to note|noting)\b/i,
  /\bat the end of the day\b/i,
  /\bisn'?t just\b/i,
  /\bnot just\b/i,
  /\bmore than just\b/i,
  /\bin conclusion\b/i,
];
for (const re of banned) {
  const m = text.match(re);
  if (m) failures.push(`AI vocabulary tell: "${m[0]}"`);
}

if (failures.length) {
  for (const f of failures) console.log(`  ✗ ${f}`);
  process.exit(1);
}
console.log("  ✓ all humanizer checks passed");
