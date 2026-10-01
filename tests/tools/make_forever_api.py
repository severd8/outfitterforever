# Rebuilds tests/forever_api.lua: what the WoW: Forever client has, for the
# offline tests. Run from the repo root:
#
#   python3 tests/tools/make_forever_api.py <wow-ui-source> <forever-addon-dev>
#
#   <wow-ui-source>     a checkout of the "forever" branch of
#                       https://github.com/Gethe/wow-ui-source (Blizzard's UI code)
#   <forever-addon-dev> a checkout of https://github.com/imperial64/forever-addon-dev
#                       (the client's API documentation and global list)
#
# Only names the addon's files mention are kept, to keep the file small; run it
# again after using a new API or Blizzard frame.
import json, os, re, sys
import xml.etree.ElementTree as ET
UI_SOURCE = os.path.join(sys.argv[1], "Interface", "AddOns")
REF = os.path.join(sys.argv[2], "reference", "api")
ADDON = os.getcwd()

# --- Which Blizzard UI files load on Forever (game type "camelot") ---
ROOT = UI_SOURCE
MATCH = {"camelot", "mainline"}
def allowed(tokens):
    ok = True
    for kind, vals in tokens:
        vals = {v.strip().lower() for v in vals.split(",")}
        if kind == "AllowLoadGameType" and not (vals & MATCH): ok = False
        if kind == "ExcludeLoadGameType" and (vals & {"camelot"}): ok = False
    return ok
TOK = re.compile(r"\[(AllowLoadGameType|ExcludeLoadGameType)\s+([^\]]+)\]")
files, addons = [], {}
for addon in sorted(os.listdir(ROOT)):
    toc = None
    for cand in (addon + ".toc", addon + "_Mainline.toc"):
        if os.path.exists(os.path.join(ROOT, addon, cand)): toc = cand
    if not toc: continue
    lines = open(os.path.join(ROOT, addon, toc), encoding="utf-8", errors="replace").read().splitlines()
    head = [l for l in lines if l.startswith("##")]
    hdr = []
    lod = False
    for l in head:
        m = re.match(r"##\s*(AllowLoadGameType|ExcludeLoadGameType)\s*:\s*(.*)", l)
        if m: hdr.append((m.group(1), m.group(2)))
        if re.match(r"##\s*LoadOnDemand\s*:\s*1", l): lod = True
    if not allowed(hdr): continue
    addons[addon] = {"lod": lod}
    for l in lines:
        s = l.strip()
        if not s or s.startswith("#"): continue
        toks = TOK.findall(s)
        if not allowed(toks): continue
        path = TOK.sub("", s)
        path = re.sub(r"\[[A-Za-z]+(?:\s[^\]]*)?\]", lambda m: {"[Family]": "Mainline", "[Game]": "Camelot"}.get(m.group(0), m.group(0)), path).strip()
        if "[" in path: continue
        files.append((addon, os.path.join(ROOT, addon, path.replace("\\", "/"))))
seen, order = set(), []
def add(addon, p):
    p = os.path.normpath(p)
    if p in seen: return
    real = p
    if not os.path.exists(real):
        d, b = os.path.split(real)
        if os.path.isdir(d):
            for f in os.listdir(d):
                if f.lower() == b.lower(): real = os.path.join(d, f)
    if not os.path.exists(real): return
    seen.add(p); order.append((addon, real))
    if real.lower().endswith(".xml"):
        txt = open(real, encoding="utf-8", errors="replace").read()
        for inc in re.findall(r'<(?:Include|Script)\s+file="([^"]+)"', txt):
            add(addon, os.path.join(os.path.dirname(real), inc.replace("\\", "/")))
for a, p in files: add(a, p)
frames, templates, funcs, globals_ = {}, {}, {}, {}
for addon, p in order:
    txt = open(p, encoding="utf-8", errors="replace").read()
    rel = os.path.relpath(p, ROOT)
    if p.lower().endswith(".xml"):
        for m in re.finditer(r'<(\w+)\s[^>]*?\bname="([^"$]+)"([^>]*)>', txt):
            tag, name, rest = m.group(1), m.group(2), m.group(0)
            if 'virtual="true"' in rest: templates.setdefault(name, rel)
            else: frames.setdefault(name, rel)
    else:
        for m in re.finditer(r'^function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(', txt, re.M): funcs.setdefault(m.group(1), rel)
        for m in re.finditer(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=', txt, re.M): globals_.setdefault(m.group(1), rel)
idx = {"addons": addons, "files": [os.path.relpath(p, ROOT) for _, p in order], "frames": frames, "templates": templates, "funcs": funcs, "globals": globals_}

# --- The named pieces of each Blizzard template ---
REGION = {"Texture", "FontString", "Line", "MaskTexture", "NormalTexture", "PushedTexture", "HighlightTexture",
          "DisabledTexture", "CheckedTexture", "DisabledCheckedTexture", "ThumbTexture", "ButtonText", "BarTexture"}
SKIP = {"Scripts", "Anchors", "Size", "KeyValues", "Animations", "Attributes"}
parts = {}
def strip_ns(tag): return tag.split("}")[-1]
def walk(node, out, depth):
    for child in node:
        tag = strip_ns(child.tag)
        if tag in SKIP: continue
        name, key = child.get("name"), child.get("parentKey")
        kind = None
        if tag in REGION: kind = "FontString" if tag in ("FontString", "ButtonText") else "Texture"
        elif tag in ("Layers", "Layer", "Frames"): walk(child, out, depth); continue
        elif tag[0].isupper(): kind = "Button" if tag == "ItemButton" else tag
        if kind is None: continue
        if (name and name.startswith("$parent") and "$parent" not in name[7:]) or (key and depth == 0):
            anchor = None
            for a in child.iter():
                if strip_ns(a.tag) == "Anchor":
                    anchor = (a.get("point"), a.get("relativeTo"), a.get("relativePoint"))
                    break
            out.append({"suffix": name[7:] if name and name.startswith("$parent") else None, "type": kind, "key": key if depth == 0 else None,
                        "inherits": child.get("inherits"), "hidden": child.get("hidden") == "true", "anchor": anchor})
        # Only the template's own children get parentKeys on the template; deeper $parent names still resolve to the nearest named ancestor
        if not name: walk(child, out, depth + 1)
for rel in idx["files"]:
    if not rel.lower().endswith(".xml"): continue
    path = os.path.join(ROOT, rel)
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
        text = re.sub(r'xmlns(:\w+)?="[^"]*"', "", text)
        text = re.sub(r'\b\w+:(\w+)=', r'\1=', text)
        tree = ET.fromstring(text)
    except Exception as e:
        continue
    for node in tree.iter():
        if node.get("virtual") == "true" and node.get("name"):
            out = []
            walk(node, out, 0)
            if "Glue" not in rel: parts.setdefault(node.get("name"), {"inherits": node.get("inherits"), "parts": out, "type": strip_ns(node.tag), "hidden": node.get("hidden") == "true"})
template_parts = parts

# --- Write tests/forever_api.lua ---
def names(d): return sorted(f[:-3] for f in os.listdir(d) if f.endswith(".md") and not f.startswith("_"))
glob = []
for L in sorted(os.listdir(os.path.join(REF, "globals"))): glob += names(os.path.join(REF, "globals", L))
ns = {}
for n in sorted(os.listdir(os.path.join(REF, "namespaces"))):
    p = os.path.join(REF, "namespaces", n)
    if os.path.isdir(p): ns[n] = names(p)
ev = []
for L in sorted(os.listdir(os.path.join(REF, "events"))): ev += names(os.path.join(REF, "events", L))
meth = set()
for t in os.listdir(os.path.join(REF, "widgets")):
    p = os.path.join(REF, "widgets", t)
    if os.path.isdir(p): meth |= set(names(p))
tokens = set()
for root, _, files in os.walk(ADDON):
    if "/.git" in root or "/tests" in root: continue
    for f in files:
        if f.endswith((".lua", ".xml", ".toc")):
            tokens |= set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", open(os.path.join(root, f), encoding="utf-8", errors="replace").read()))
def wanted(x): return x in tokens or x.startswith("Character")
glob = [g for g in glob if wanted(g)]
ns = {k: v for k, v in ns.items() if k in tokens}
for key in ("frames", "templates", "funcs", "globals"):
    idx[key] = {k: v for k, v in idx[key].items() if wanted(k)}
def lua_list(xs): return "{" + ",".join('["%s"]=true' % x for x in xs if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", x)) + "}"
out = ["-- Generated by tests/tools/make_forever_api.py from the WoW: Forever 1.60.1 API reference and UI source. Do not edit.", "return {"]
out.append("globals=" + lua_list(glob) + ",")
out.append("namespaces={" + ",".join('%s=%s' % (k, lua_list(v)) for k, v in ns.items() if re.match(r"^[A-Za-z_]\w*$", k)) + "},")
out.append("events=" + lua_list(ev) + ",")
out.append("methods=" + lua_list(sorted(meth)) + ",")
for key in ("frames", "templates", "funcs", "globals"):
    out.append("ui_%s=%s," % (key, lua_list(sorted(idx[key]))))
# Pieces of Blizzard templates the addon uses (and what those inherit)
parts = template_parts
want, todo = set(), [t for t in parts if t in tokens]
while todo:
    t = todo.pop()
    if t in want or t not in parts: continue
    want.add(t)
    for inh in re.split(r"[,\s]+", parts[t]["inherits"] or ""):
        if inh: todo.append(inh)
    for part in parts[t]["parts"]:
        for inh in re.split(r"[,\s]+", part.get("inherits") or ""):
            if inh: todo.append(inh)
def lua_str(v): return "nil" if v is None else '"%s"' % v
rows = []
for t in sorted(want):
    p = parts[t]
    def anchor(a):
        if not a: return "nil"
        return "{%s,%s,%s}" % (lua_str(a[0]), lua_str(a[1]), lua_str(a[2]))
    items = ",".join("{suffix=%s,key=%s,type=%s,inherits=%s,hidden=%s,anchor=%s}" % (lua_str(x["suffix"]), lua_str(x["key"]), lua_str(x["type"]), lua_str(x.get("inherits")), "true" if x.get("hidden") else "false", anchor(x.get("anchor"))) for x in p["parts"])
    rows.append('["%s"]={type=%s,inherits=%s,hidden=%s,parts={%s}}' % (t, lua_str(p["type"]), lua_str(p["inherits"]), "true" if p.get("hidden") else "false", items))
out.append("template_parts={" + ",\n".join(rows) + "},")
out.append("}")
open(os.path.join(ADDON, "tests", "forever_api.lua"), "w").write("\n".join(out) + "\n")
print(len(glob), "globals", sum(len(v) for v in ns.values()), "ns funcs", len(ev), "events", len(meth), "methods")
