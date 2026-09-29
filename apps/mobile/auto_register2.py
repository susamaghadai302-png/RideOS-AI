import subprocess, time, sys
import xml.etree.ElementTree as ET
import re

ADB_SERIAL = "10.9.1.42:43777"

def run(cmd):
    print(f"Running: {cmd}")
    subprocess.run(f"adb -s {ADB_SERIAL} shell {cmd}", shell=True)

def type_text(text):
    run(f"input text '{text}'")
    time.sleep(1)

def safe_hide_keyboard():
    res = subprocess.run(f"adb -s {ADB_SERIAL} shell dumpsys window InputMethod", shell=True, capture_output=True, text=True)
    if "mHasSurface=true" in res.stdout:
        print("Keyboard is open, hiding it...")
        run("input keyevent 4")
        time.sleep(1.5)
    else:
        print("Keyboard is already hidden.")

def get_bounds(hint=None, content_desc=None):
    print(f"DEBUG: get_bounds(hint={hint}, content_desc={content_desc})")
    run("uiautomator dump /sdcard/window_dump.xml")
    subprocess.run(f"adb -s {ADB_SERIAL} pull /sdcard/window_dump.xml /tmp/window_dump.xml", shell=True)
    tree = ET.parse("/tmp/window_dump.xml")
    found_hints = []
    found_descs = []
    for node in tree.getroot().iter('node'):
        h = node.attrib.get('hint')
        c = node.attrib.get('content-desc')
        if h: found_hints.append(h)
        if c: found_descs.append(c)
        if hint and h == hint:
            m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.attrib.get('bounds'))
            if m:
                x1,y1,x2,y2 = map(int, m.groups())
                print(f"DEBUG: Found {hint} at {((x1+x2)//2, (y1+y2)//2)}")
                return ((x1+x2)//2, (y1+y2)//2)
        if content_desc and c == content_desc:
            m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.attrib.get('bounds'))
            if m:
                x1,y1,x2,y2 = map(int, m.groups())
                print(f"DEBUG: Found desc {content_desc} at {((x1+x2)//2, (y1+y2)//2)}")
                return ((x1+x2)//2, (y1+y2)//2)
    print(f"DEBUG: Available hints: {found_hints}")
    print(f"DEBUG: Available descs: {found_descs}")
    return None

def tap_and_type(hint, text):
    bounds = get_bounds(hint=hint)
    if bounds:
        run(f"input tap {bounds[0]} {bounds[1]}")
        time.sleep(1)
        type_text(text)
        safe_hide_keyboard()
    else:
        print(f"Could not find field {hint}")

print("Starting app...")
run("am force-stop ai.rideos.app")
time.sleep(2)
run("am start -n ai.rideos.app/com.example.rideos_mobile.MainActivity")

# Wait for Welcome screen to appear (wait for CREATE ACCOUNT button)
for _ in range(15):
    # The submit button on Welcome screen is lower (Y > 1000)
    # But wait, we can just look for 'Sign In to Cockpit' which is only on Welcome
    if get_bounds(content_desc="Sign In to Cockpit"):
        print(f"Welcome screen loaded!")
        break
    time.sleep(2)
else:
    print("Welcome screen did not load.")
    sys.exit(1)

# Click CREATE ACCOUNT on Welcome Screen (the button below Sign In)
# Center of CREATE ACCOUNT is roughly 540 2049
run("input tap 540 2049")
time.sleep(3)

# Wait for Registration screen to appear (wait for Full Name field)
for _ in range(10):
    if get_bounds(hint="Full Name"):
        print(f"Registration screen loaded!")
        break
    time.sleep(2)
else:
    print("Registration screen did not load.")
    sys.exit(1)

tap_and_type("Full Name", "JaneDoeTest")
email = f"jane_test{int(time.time())}@example.com"
print(f"Using email: {email}")
tap_and_type("Email Address", email)
tap_and_type("Phone Number", "5551234569")

# Scroll down to reveal password fields
run("input swipe 540 1700 540 500")
time.sleep(2)

tap_and_type("Password", "securepass123")
tap_and_type("Confirm Password", "securepass123")

# Scroll down again for terms and submit
run("input swipe 540 1700 540 500")
time.sleep(2)

run("uiautomator dump /sdcard/window_dump.xml")
subprocess.run(f"adb -s {ADB_SERIAL} pull /sdcard/window_dump.xml /tmp/window_dump.xml", shell=True)
tree = ET.parse("/tmp/window_dump.xml")

tb = None
for node in tree.getroot().iter('node'):
    text = node.attrib.get('text', '')
    desc = node.attrib.get('content-desc', '')
    if 'I agree to the' in text or 'I agree to the' in desc:
        m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.attrib.get('bounds'))
        if m:
            tb = tuple(map(int, m.groups()))
            break

if tb:
    x1, y1, x2, y2 = tb
    cy = (y1 + y2) // 2
    cx = 100 # Tap left of text
    run(f"input tap {cx} {cy}")
else:
    print("Could not find terms")
    # Blind tap where it usually is
    run("input tap 105 1929")

# Find the lowest CREATE ACCOUNT button
btns = []
for node in tree.getroot().iter('node'):
    if node.attrib.get('content-desc') == "CREATE ACCOUNT":
        m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.attrib.get('bounds'))
        if m:
            x1,y1,x2,y2 = map(int, m.groups())
            btns.append(((x1+x2)//2, (y1+y2)//2))
if btns:
    s_btn = max(btns, key=lambda b: b[1])
    run(f"input tap {s_btn[0]} {s_btn[1]}")
    time.sleep(8)
else:
    print("Could not find submit button")
    run("input tap 540 2169")
    time.sleep(8)

# Check dashboard
run("uiautomator dump /sdcard/window_dump.xml")
subprocess.run(f"adb -s {ADB_SERIAL} pull /sdcard/window_dump.xml /tmp/window_dump.xml", shell=True)

with open("/tmp/window_dump.xml", "r") as f:
    xml = f.read()
    if 'content-desc="Drive"' in xml or 'content-desc="DASHBOARD"' in xml or 'access this device' in xml or 'While using the app' in xml:
        print("SUCCESS! Reached dashboard or permission prompt.")
        sys.exit(0)
    else:
        print("FAILED to reach dashboard.")
        sys.exit(1)
