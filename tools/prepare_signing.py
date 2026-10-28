#!/usr/bin/env python3
"""Restore fixed Android signing key from GitHub Actions Secrets, never from repo."""
import base64
import os
from pathlib import Path
import re
import subprocess


def main():
    names = ("KEYSTORE_BASE64", "KEYSTORE_PASSWORD", "KEY_ALIAS", "KEY_PASSWORD")
    missing = [name for name in names if not os.environ.get(name)]
    if missing:
        raise SystemExit("Missing required Actions secrets: " + ", ".join(missing))
    out_dir = Path(os.environ["RUNNER_TEMP"])
    src = out_dir / "monsterkart-source.jks"
    dst = out_dir / "monsterkart-release.p12"
    try:
        data = base64.b64decode("".join(os.environ["KEYSTORE_BASE64"].split()), validate=True)
    except (ValueError, Exception) as exc:
        raise SystemExit("Invalid KEYSTORE_BASE64: expected base64 encoded keystore") from exc
    if len(data) < 300:
        raise SystemExit("Signing key is too short")
    src.write_bytes(data)
    src.chmod(0o600)
    try:
        # Godot native export expects store/key password to be identical.
        # Rewrap existing certificate and private key without generating a new signer.
        subprocess.run(
            [
                "keytool", "-importkeystore",
                "-srckeystore", str(src),
                "-srcstorepass:env", "KEYSTORE_PASSWORD",
                "-srcalias", os.environ["KEY_ALIAS"],
                "-srckeypass:env", "KEY_PASSWORD",
                "-destkeystore", str(dst),
                "-deststoretype", "PKCS12",
                "-deststorepass:env", "KEYSTORE_PASSWORD",
                "-destkeypass:env", "KEYSTORE_PASSWORD",
                "-destalias", os.environ["KEY_ALIAS"],
                "-noprompt",
            ],
            check=True,
        )
        dst.chmod(0o600)
    except subprocess.CalledProcessError:
        raise SystemExit("Existing keystore, alias or password is invalid") from None
    finally:
        src.unlink(missing_ok=True)
    preset = Path("export_presets.cfg")
    text = preset.read_text("utf-8")
    run = int(os.environ["GITHUB_RUN_NUMBER"])
    code = 10000 + run
    text, matches = re.subn(r"(?m)^version/code=\d+$", f"version/code={code}", text)
    if matches != 1:
        raise SystemExit("Android preset missing version/code")
    text, matches = re.subn(r'(?m)^version/name="[^"]+"$', f'version/name="0.1.{run}"', text)
    if matches != 1:
        raise SystemExit("Android preset missing version/name")
    preset.write_text(text, encoding="utf-8")
    # The actual in-game menu must show the same version as Android's package manifest.
    project = Path("project.godot")
    project_text = project.read_text("utf-8")
    project_text, matches = re.subn(
        r'(?m)^config/version="[^"]+"


if __name__ == "__main__":
    main()
,
        f'config/version="0.1.{run}"',
        project_text,
    )
    if matches != 1:
        raise SystemExit("Godot project missing application/config/version")
    project.write_text(project_text, encoding="utf-8")
    print(f"Fixed certificate prepared; versionCode={code}; versionName=0.1.{run}; menuVersion=0.1.{run}")


if __name__ == "__main__":
    main()
