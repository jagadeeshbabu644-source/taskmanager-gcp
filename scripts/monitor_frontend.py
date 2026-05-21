"""
Frontend Monitor
- Records page load time
- Verifies all components are loaded
"""

import time
import sys
from playwright.sync_api import sync_playwright

# ── Configuration ──────────────────────────────────────────
APP_URL = "http://34.8.222.242"

# Components that must exist on the page
REQUIRED_COMPONENTS = [
    {"name": "Header",          "selector": "#header"},
    {"name": "App Title",       "selector": "#app-title"},
    {"name": "Stats Bar",       "selector": "#stats-bar"},
    {"name": "Total Tasks",     "selector": "#total-tasks"},
    {"name": "Pending Tasks",   "selector": "#pending-tasks"},
    {"name": "Completed Tasks", "selector": "#completed-tasks"},
    {"name": "Add Task Form",   "selector": "#task-form-section"},
    {"name": "Title Input",     "selector": "#task-title"},
    {"name": "Submit Button",   "selector": "#submit-btn"},
    {"name": "Task List",       "selector": "#task-list-section"},
    {"name": "Filter Bar",      "selector": "#filter-bar"},
    {"name": "Footer",          "selector": "#footer"},
]

# ── Monitor Function ────────────────────────────────────────
def monitor(url):
    print("=" * 50)
    print("  FRONTEND MONITOR REPORT")
    print("=" * 50)
    print(f"  URL: {url}")
    print()

    with sync_playwright() as pw:
        # Launch headless browser
        browser = pw.chromium.launch(headless=True)
        page    = browser.new_page()

        # ── Record load time ──────────────────────────────
        print("Loading page...")
        start_time = time.time()

        # Wait until page DOM is ready
        page.goto(url, wait_until="domcontentloaded")

        # Wait for main content to appear
        page.wait_for_selector("#main-content", timeout=15000)

        # Extra wait for JS to finish (stats API call)
        time.sleep(2)

        end_time  = time.time()
        load_time = (end_time - start_time) * 1000

        print(f"  Page Load Time: {load_time:.0f} ms")
        print()

        # ── Verify components ─────────────────────────────
        print("  COMPONENT CHECKS:")
        print("-" * 50)

        all_passed = True
        for comp in REQUIRED_COMPONENTS:
            element = page.locator(comp["selector"]).first
            found   = element.count() > 0
            visible = element.is_visible() if found else False

            if found and visible:
                status = "PASS ✓"
            elif found:
                status = "WARN (hidden)"
                all_passed = False
            else:
                status = "FAIL ✗"
                all_passed = False

            print(f"  {status:<15} {comp['name']}")

        # ── Take screenshot ───────────────────────────────
        screenshot = "monitor_screenshot.png"
        page.screenshot(path=screenshot, full_page=True)

        browser.close()

    # ── Summary ───────────────────────────────────────────
    print()
    print("=" * 50)
    print(f"  Load Time : {load_time:.0f} ms")
    print(f"  Components: {'ALL PASSED' if all_passed else 'SOME FAILED'}")
    print(f"  Screenshot: {screenshot}")
    print("=" * 50)

    return all_passed, load_time

# ── Main ───────────────────────────────────────────────────
if __name__ == "__main__":
    url = sys.argv[1] if len(sys.argv) > 1 else APP_URL
    passed, load_time = monitor(url)
    sys.exit(0 if passed else 1)
