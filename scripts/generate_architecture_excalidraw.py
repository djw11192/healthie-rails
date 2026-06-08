#!/usr/bin/env python3
"""
Generate an Excalidraw diagram (JSON) of the Healthie system design.

Produces two diagrams in one canvas:
  1. MVP  — the current interview build (React SPA + Rails API + Postgres)
  2. Target — a HIPAA-ready, high-scale architecture (edge, auth, cache,
     read replicas, async workers, audit logging, encryption, VPC isolation)

Usage:
    python3 generate_architecture_excalidraw.py [output_path]

Default output: docs/healthie-architecture.excalidraw
Import into Excalidraw via: Menu -> Open, or drag the file onto excalidraw.com.
No third-party dependencies.
"""
import json
import random
import sys
import time

random.seed(7)
NOW = int(time.time() * 1000)

_ALPHANUM = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"


def rid():
    return "".join(random.choice(_ALPHANUM) for _ in range(16))


def nonce():
    return random.randint(1, 2**31)


# (background, stroke) pairs from Excalidraw's default palette
PALETTE = {
    "blue":   ("#a5d8ff", "#1971c2"),
    "green":  ("#b2f2bb", "#2f9e44"),
    "yellow": ("#ffec99", "#f08c00"),
    "red":    ("#ffc9c9", "#e03131"),
    "grape":  ("#eebefa", "#9c36b5"),
    "teal":   ("#99e9f2", "#0c8599"),
    "orange": ("#ffd8a8", "#e8590c"),
    "gray":   ("#e9ecef", "#495057"),
}

elements = []
bound = {}        # element id -> [{"id":..,"type":..}]
box_geo = {}      # box id -> (x, y, w, h)


def base(t, x, y, w, h, **kw):
    return {
        "id": kw.get("id") or rid(),
        "type": t, "x": x, "y": y, "width": w, "height": h, "angle": 0,
        "strokeColor": kw.get("strokeColor", "#1e1e1e"),
        "backgroundColor": kw.get("backgroundColor", "transparent"),
        "fillStyle": kw.get("fillStyle", "solid"),
        "strokeWidth": kw.get("strokeWidth", 2),
        "strokeStyle": kw.get("strokeStyle", "solid"),
        "roughness": kw.get("roughness", 1), "opacity": 100,
        "groupIds": [], "frameId": None, "roundness": kw.get("roundness"),
        "seed": nonce(), "version": 1, "versionNonce": nonce(),
        "isDeleted": False, "boundElements": None, "updated": NOW,
        "link": None, "locked": False,
    }


def text_dims(text, fs):
    lines = text.split("\n")
    w = max(len(l) for l in lines) * fs * 0.58
    h = len(lines) * fs * 1.25
    return max(w, 10), h


def add_text(x, y, text, fs=16, color="#1e1e1e", align="left", container=None, w=None, h=None):
    tw, th = text_dims(text, fs)
    el = base("text", x, y, w if w is not None else tw, h if h is not None else th, strokeColor=color)
    el.update({
        "text": text, "fontSize": fs, "fontFamily": 2, "textAlign": align,
        "verticalAlign": "middle" if container else "top", "containerId": container,
        "originalText": text, "lineHeight": 1.25, "autoResize": True,
    })
    elements.append(el)
    return el["id"]


def add_box(x, y, w, h, label, color="blue", fs=15, dashed=False, fill="solid"):
    bg, st = PALETTE[color]
    rect = base("rectangle", x, y, w, h, strokeColor=st, backgroundColor=bg,
                roundness={"type": 3}, fillStyle=fill,
                strokeStyle="dashed" if dashed else "solid")
    elements.append(rect)
    tw, th = text_dims(label, fs)
    tid = add_text(x + (w - min(tw, w - 12)) / 2, y + (h - th) / 2, label, fs=fs,
                   color=st, align="center", container=rect["id"], w=min(tw, w - 12), h=th)
    bound.setdefault(rect["id"], []).append({"id": tid, "type": "text"})
    box_geo[rect["id"]] = (x, y, w, h)
    return rect["id"]


def boundary(geo, tx, ty):
    x, y, w, h = geo
    cx, cy = x + w / 2, y + h / 2
    dx, dy = tx - cx, ty - cy
    if dx == 0 and dy == 0:
        return cx, cy
    sx = (w / 2) / abs(dx) if dx else float("inf")
    sy = (h / 2) / abs(dy) if dy else float("inf")
    s = min(sx, sy)
    return cx + dx * s, cy + dy * s


def add_arrow(src, dst, label=None, color="#495057", dashed=False):
    sg, dg = box_geo[src], box_geo[dst]
    scx, scy = sg[0] + sg[2] / 2, sg[1] + sg[3] / 2
    dcx, dcy = dg[0] + dg[2] / 2, dg[1] + dg[3] / 2
    sx, sy = boundary(sg, dcx, dcy)
    ex, ey = boundary(dg, scx, scy)
    arr = base("arrow", sx, sy, abs(ex - sx), abs(ey - sy), strokeColor=color,
               strokeStyle="dashed" if dashed else "solid")
    arr.update({
        "points": [[0, 0], [ex - sx, ey - sy]], "lastCommittedPoint": None,
        "startBinding": {"elementId": src, "focus": 0, "gap": 4},
        "endBinding": {"elementId": dst, "focus": 0, "gap": 4},
        "startArrowhead": None, "endArrowhead": "arrow", "elbowed": False,
    })
    elements.append(arr)
    bound.setdefault(src, []).append({"id": arr["id"], "type": "arrow"})
    bound.setdefault(dst, []).append({"id": arr["id"], "type": "arrow"})
    if label:
        add_text((sx + ex) / 2 - len(label) * 3.5, (sy + ey) / 2 - 16, label, fs=11, color=color)


def region(x, y, w, h, title, color="gray"):
    _, st = PALETTE[color]
    elements.append(base("rectangle", x, y, w, h, strokeColor=st,
                         backgroundColor="transparent", roundness={"type": 3},
                         strokeStyle="dashed", strokeWidth=1.5))
    add_text(x + 14, y + 10, title, fs=14, color=st)


# ----------------------------------------------------------------------------
# Diagram 1 — MVP (current interview build)
# ----------------------------------------------------------------------------
add_text(40, 30, "MVP — Current Build (Providers / Clients / Journal API)", fs=26, color="#1e1e1e")

m_clients = add_box(60, 120, 210, 80, "API Clients\nPostman / web / mobile", "blue")
m_api = add_box(380, 120, 210, 80, "Rails API\n(Puma, REST / JSON)", "green")
m_pg = add_box(700, 120, 210, 80, "PostgreSQL\n(single instance)", "teal")

add_arrow(m_clients, m_api, "HTTPS / JSON")
add_arrow(m_api, m_pg, "SQL (ActiveRecord)")

add_text(60, 320,
         "One Rails process, one DB, no auth / cache / async. Correct for a take-home; "
         "single points of failure and no PHI controls for production.",
         fs=13, color="#495057")

# ----------------------------------------------------------------------------
# Diagram 2 — Target (HIPAA-ready, high scale)
# ----------------------------------------------------------------------------
add_text(40, 430, "Target — High Scale & HIPAA-Ready", fs=26, color="#1e1e1e")

# VPC boundary (drawn before inner boxes so it sits behind them)
region(500, 495, 760, 580, "VPC  -  private subnets, security groups, least-privilege IAM", "gray")

# Tier labels
for lx, lbl in [(60, "Clients"), (290, "Edge"), (520, "Application"),
                (800, "Cache / Async"), (1050, "Data")]:
    add_text(lx, 500, lbl, fs=13, color="#868e96")

# Clients
t_web = add_box(50, 560, 175, 70, "Web Client", "blue")
t_mob = add_box(50, 650, 175, 70, "Mobile / 3rd-party\nAPI consumers", "blue")

# Edge
e_cdn = add_box(280, 540, 185, 58, "CDN / Edge Cache\ncacheable GETs", "orange")
e_waf = add_box(280, 612, 185, 58, "WAF\nOWASP, rate limiting", "orange")
e_lb = add_box(280, 684, 185, 66, "Load Balancer\nTLS termination", "orange")

# Application (inside VPC)
a_auth = add_box(515, 540, 200, 70, "Auth (AuthN)\nOAuth2 / OIDC, MFA, JWT", "red")
a_api = add_box(515, 622, 200, 70, "Rails API\nautoscaled (N instances)", "green")
a_authz = add_box(515, 704, 200, 62, "AuthZ\nPundit + row-level tenant scope", "red")
a_ws = add_box(515, 778, 200, 62, "ActionCable\nWebSockets (real-time)", "green")

# Cache / async (inside VPC)
c_redis = add_box(795, 560, 185, 78, "Redis\ncache + pub/sub + sessions", "grape")
c_side = add_box(795, 678, 185, 78, "Sidekiq Workers\nasync jobs, exports, emails", "grape")

# Data (inside VPC)
d_bouncer = add_box(1045, 540, 195, 56, "PgBouncer\nconnection pooling", "teal")
d_primary = add_box(1045, 610, 195, 64, "Postgres Primary\nwrites - encrypted at rest", "teal")
d_replica = add_box(1045, 686, 195, 64, "Read Replica(s)\nreads / journal feeds", "teal")
d_search = add_box(1045, 762, 195, 56, "OpenSearch\njournal full-text", "teal")
d_s3 = add_box(1045, 830, 195, 56, "Object Storage (S3)\nencrypted (KMS)", "teal")

# Cross-cutting band (inside VPC)
x_audit = add_box(515, 980, 215, 70, "Audit Log\nappend-only: who / what / when", "yellow")
x_monit = add_box(750, 980, 215, 70, "Monitoring + SIEM\nlogs, metrics, alerting", "yellow")
x_secrets = add_box(985, 980, 215, 70, "Secrets Mgr / KMS\nkeys + encryption", "yellow")

# Flows
add_arrow(t_web, e_cdn, "cacheable GETs")
add_arrow(t_web, e_waf, "API")
add_arrow(t_mob, e_waf)
add_arrow(e_waf, e_lb)
add_arrow(e_lb, a_auth)
add_arrow(e_lb, a_api, "HTTPS")
add_arrow(e_lb, a_ws, "WSS")
add_arrow(a_api, a_authz, "every request")
add_arrow(a_api, c_redis, "cache")
add_arrow(a_api, c_side, "enqueue")
add_arrow(c_side, c_redis, "queue")
add_arrow(a_ws, c_redis, "pub/sub")
add_arrow(a_api, d_bouncer)
add_arrow(d_bouncer, d_primary, "writes")
add_arrow(d_bouncer, d_replica, "reads")
add_arrow(d_primary, d_replica, "replication", dashed=True)
add_arrow(a_api, d_search, "search")
add_arrow(c_side, d_s3, "exports")
add_arrow(a_api, x_audit, "PHI access")
add_arrow(a_api, x_monit, dashed=True)
add_arrow(a_auth, x_secrets, dashed=True)
add_arrow(d_primary, x_secrets, "encryption keys", dashed=True)

# HIPAA notes
add_text(
    1290, 540,
    "HIPAA / security notes\n"
    "- TLS 1.2+ everywhere; PHI encrypted at rest (KMS),\n"
    "  field-level encryption for journal bodies\n"
    "- Signed BAA with cloud provider\n"
    "- Audit every PHI read/write (immutable log)\n"
    "- Least-privilege IAM; network isolation (VPC)\n"
    "- MFA + short-lived tokens; deny-by-default AuthZ\n"
    "- Automated encrypted backups + PITR\n"
    "- Read replicas: route writes/read-after-write to\n"
    "  primary, stale-tolerant reads to replicas",
    fs=13, color="#0c8599",
)

# Apply accumulated bindings
for el in elements:
    if el["id"] in bound:
        el["boundElements"] = bound[el["id"]]

doc = {
    "type": "excalidraw", "version": 2,
    "source": "healthie-systems-design-script",
    "elements": elements,
    "appState": {"gridSize": None, "viewBackgroundColor": "#ffffff"},
    "files": {},
}

out = sys.argv[1] if len(sys.argv) > 1 else "docs/healthie-architecture.excalidraw"
with open(out, "w") as f:
    json.dump(doc, f, indent=2)
print(f"Wrote {len(elements)} elements to {out}")
