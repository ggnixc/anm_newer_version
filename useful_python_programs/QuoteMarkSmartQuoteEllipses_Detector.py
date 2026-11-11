import os
import sys

# =========================
# PATH SETUP
# =========================

tno_path = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))

if "the-new-order-git" not in tno_path:
    print("Please run this Script in-the-new-order-git\\useful_python_programs")
    sys.exit()

loc_path = os.path.join(tno_path, "localisation")

output_log = os.path.join(os.path.dirname(os.path.realpath(__file__)), "quote_report.txt")

if os.path.exists(output_log):
    os.remove(output_log)

# =========================
# DETECTION RULES
# =========================

SMART_QUOTES = {"“", "”", "‘", "’"}
ELLIPSIS = "…"


def detect_missing_closing_quote(line):
    """
    Detect ONLY broken localisation strings where a closing quote is missing.
    Ignores all internal quotes.
    """
    first = line.find('"')
    if first == -1:
        return False

    last = line.rfind('"')

    return last == first


def detect_formatting_issues(line):
    """
    Detect non-critical formatting issues:
    - smart quotes
    - ellipsis
    """
    issues = []

    if any(ch in line for ch in SMART_QUOTES):
        issues.append("SMART_QUOTES")

    if ELLIPSIS in line:
        issues.append("ELLIPSIS")

    return issues


# =========================
# MAIN CHECKER
# =========================

with open(output_log, "a", encoding="utf-8") as log:

    for subdir, _, files in os.walk(loc_path):
        for file in files:

            if not file.endswith(".yml"):
                continue

            file_path = os.path.join(subdir, file)

            with open(file_path, "r", encoding="utf-8") as f:
                lines = f.readlines()

            for i, line in enumerate(lines, 1):

                # skip comments / metadata
                if line.strip().startswith("#") or "l_english" in line or ":" not in line:
                    continue

                issues = []

                # 1. Critical issue
                if detect_missing_closing_quote(line):
                    issues.append("MISSING_CLOSING_QUOTE")

                # 2. Formatting issues
                issues.extend(detect_formatting_issues(line))

                # log results
                if issues:
                    log.write(f"[ISSUE] {file} line {i} ({', '.join(issues)})\n")
                    log.write(line + "\n")
                    print(f"Issue in {file} line {i}: {issues}")

print("\nDone.")