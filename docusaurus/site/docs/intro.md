# Documentation Hub 📚

Welcome to your internal Synology Documentation site!

This page is a placeholder. Once you populate **`repos.json`** with your real Git repositories, Dockhand's runtime build will pull those documents down dynamically, compile them, and serve your beautiful live documentation here!

---

### 📝 How to configure your repositories:

Open and edit **`repos.json`** inside your `docusaurus` folder to define where your documentation resides:

```json
[
  {
    "name": "synology",
    "url": "https://github.com/epcim/containers-stacks.git",
    "branch": "main",
    "docs_path": "_docs",
    "target": "synology"
  }
]
```

---

### ⚙️ Live Dynamic Update:

Every time the container starts, it reads `repos.json`, fetches any modifications, compiles the new Markdown files dynamically, and serves the static HTML through Nginx!
