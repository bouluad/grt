# 📘 Artifactory DR Sanity Check

This repository provides automation to verify the health and functionality of a **JFrog Artifactory HA + Xray** setup during a **Disaster Recovery (DR) Exercise**.

It includes:

- 🔁 GitHub Actions workflow to trigger sanity checks
- 🖥️ Bash script to run system and repository checks
- 🧪 Validates package installations via remote repositories
- 📄 Generates a summary report at the end

---

## 📁 Files

| File                      | Description                                      |
|---------------------------|--------------------------------------------------|
| `.github/workflows/dr-check.yml` | GitHub workflow to run sanity check        |
| `dr_sanity_check.sh`      | Bash script for health and functional checks     |
| `dr_report.log`           | Auto-generated report of each run                |

---

## ✅ What the Bash Script Checks

### 🔹 System Health

- Artifactory API status: `/api/system/ping`
- Xray health status: `/api/v1/system/health`

### 🔹 Repository (Generic) Test

- Check if generic repo exists, else create it
- Upload dummy artifact
- List artifacts in repo
- Download artifact and verify
- Delete artifact
- Delete test repo

### 🔹 Package Installation Tests

- Test `npm install` via Node remote repo
- Test `mvn dependency:resolve` via Maven remote repo
- Test `pip install` via Python remote repo

### 🔹 Report Generation

- Results stored in `dr_report.log`
- Contains timestamps, test results, and API responses

---

## ▶️ Running Manually

```bash
chmod +x dr_sanity_check.sh
./dr_sanity_check.sh
