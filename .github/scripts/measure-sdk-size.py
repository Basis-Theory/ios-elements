import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile


BUILD_SETTINGS = [
    "ARCHS=arm64",
    "ONLY_ACTIVE_ARCH=YES",
    "IPHONEOS_DEPLOYMENT_TARGET=15.0",
    "SWIFT_VERSION=5",
    "SWIFT_OPTIMIZATION_LEVEL=-O",
    "SWIFT_COMPILATION_MODE=wholemodule",
    "ENABLE_TESTABILITY=NO",
    "DEBUG_INFORMATION_FORMAT=dwarf",
    "CODE_SIGNING_ALLOWED=NO",
]


def run(args, cwd=None, env=None):
    command = shlex.join(map(str, args))
    print(f"Running: {command}", flush=True)
    with (report_dir / "commands.log").open("a") as log:
        log.write(f"\n$ cd {cwd or Path.cwd()}\n$ {command}\n")
        log.flush()
        result = subprocess.run(args, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT)
    if result.returncode:
        print((report_dir / "commands.log").read_text()[-12000:], flush=True)
        raise subprocess.CalledProcessError(result.returncode, args)


def output(args, cwd=None):
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def measure(label, products):
    binaries = {}
    destination = report_dir / label
    destination.mkdir()
    for framework in sorted(products.rglob("*.framework")):
        name = framework.stem
        binary = framework / name
        if not binary.is_file():
            continue
        if name in binaries:
            raise ValueError(f"Duplicate framework: {framework}")
        measured = destination / name
        shutil.copy2(binary, measured)
        run(["xcrun", "strip", "-S", "-x", measured])
        architecture = output(["xcrun", "lipo", "-archs", measured])
        if architecture != "arm64":
            raise ValueError(f"Unexpected architecture for {framework}: {architecture}")
        description = output(["file", "-b", measured])
        if "dynamically linked shared library" not in description:
            raise ValueError(f"Expected a dynamic library: {framework}: {description}")
        binaries[name] = {
            "bytes": measured.stat().st_size,
            "sha256": hashlib.sha256(measured.read_bytes()).hexdigest(),
            "file": description,
            "linked_libraries": output(["xcrun", "otool", "-L", measured]),
        }
    if not {"BasisTheoryElements", "AnyCodable"} <= binaries.keys():
        raise ValueError(f"Missing SDK frameworks for {label}: {binaries.keys()}")
    return binaries


def cocoapods(label, source):
    validation = work_dir / label
    run([
        "pod", "lib", "lint", "--allow-warnings", "--no-clean",
        f"--validation-dir={validation}",
    ], cwd=source, env={**os.environ, "COCOAPODS_VALIDATOR_SKIP_XCODEBUILD": "1"})
    shutil.copy2(validation / "Podfile.lock", report_dir / f"{label}.lock")
    lock = json.loads(output([
        "ruby", "-ryaml", "-rjson", "-e",
        "puts JSON.generate(YAML.load_file(ARGV.fetch(0)))", str(validation / "Podfile.lock"),
    ]))
    products = work_dir / f"{label}-products"
    run([
        "xcodebuild", "-project", validation / "Pods/Pods.xcodeproj", "-alltargets",
        "-configuration", "Release", "-sdk", "iphoneos", "build",
        f"SYMROOT={products}", f"OBJROOT={work_dir / (label + '-objects')}",
        *BUILD_SETTINGS,
    ])
    return {"pods": lock["PODS"], "binaries": measure(label, products / "Release-iphoneos")}


def replace_once(path, old, new):
    text = path.read_text()
    if text.count(old) != 1:
        raise ValueError(f"Expected one occurrence of {old!r} in {path}")
    path.write_text(text.replace(old, new, 1))


def spm(source):
    reference = work_dir / "spm-source"
    shutil.copytree(source, reference, ignore=shutil.ignore_patterns(".git", ".build"))
    resolved = source / "IntegrationTester/IntegrationTester.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    shutil.copy2(resolved, report_dir / "Package.resolved")
    pin, = json.loads(resolved.read_text())["pins"]
    if pin["identity"] != "anycodable":
        raise ValueError("Update the size fixture for the current SPM dependency graph")
    dependency = work_dir / "AnyCodable"
    run(["git", "clone", "--quiet", "--depth", "1", "--branch", pin["state"]["version"], pin["location"], dependency])
    revision = output(["git", "rev-parse", "HEAD"], cwd=dependency)
    if revision != pin["state"]["revision"]:
        raise ValueError("AnyCodable checkout does not match Package.resolved")
    for name, path in [("BasisTheoryElements", reference), ("AnyCodable", dependency)]:
        manifest = path / "Package.swift"
        shutil.copy2(manifest, report_dir / f"{name}.original.swift")
        replace_once(manifest, f'name: "{name}",\n            targets:', f'name: "{name}",\n            type: .dynamic,\n            targets:')
    replace_once(
        reference / "Package.swift",
        '.package(url: "https://github.com/Flight-School/AnyCodable", from: "0.6.0")',
        '.package(path: "../AnyCodable")',
    )
    for name, path in [("BasisTheoryElements", reference), ("AnyCodable", dependency)]:
        shutil.copy2(path / "Package.swift", report_dir / f"{name}.fixture.swift")
    derived = work_dir / "spm-derived"
    run([
        "xcodebuild", "-scheme", "BasisTheoryElements", "-configuration", "Release",
        "-sdk", "iphoneos", "-destination", "generic/platform=iOS",
        "-derivedDataPath", derived, "build", *BUILD_SETTINGS,
    ], cwd=reference)
    return {"pin": pin, "binaries": measure("spm", derived / "Build/Products/Release-iphoneos")}


def source_hash(source):
    digest = hashlib.sha256()
    root = source / "BasisTheoryElements/Sources"
    for path in sorted(root.rglob("*")):
        if path.is_file():
            digest.update(str(path.relative_to(root)).encode())
            digest.update(path.read_bytes())
    return digest.hexdigest()


if __name__ == "__main__":
    baseline, candidate, report_dir = [Path(arg).resolve() for arg in sys.argv[1:]]
    report_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="sdk-size-") as temporary:
        work_dir = Path(temporary)
        metadata = {
            "baseline_sha": output(["git", "rev-parse", "HEAD"], cwd=baseline),
            "candidate_sha": output(["git", "rev-parse", "HEAD"], cwd=candidate),
            "baseline_sources_sha256": source_hash(baseline),
            "candidate_sources_sha256": source_hash(candidate),
            "xcode": output(["xcodebuild", "-version"]),
            "swift": output(["xcrun", "swiftc", "--version"]),
            "ios_sdk": output(["xcrun", "--sdk", "iphoneos", "--show-sdk-version"]),
            "cocoapods": output(["pod", "--version"]),
            "build_settings": BUILD_SETTINGS,
            "strip": "xcrun strip -S -x <binary>",
        }
        (report_dir / "environment.json").write_text(json.dumps(metadata, indent=2) + "\n")
        results = {"before": cocoapods("before", baseline), "after": cocoapods("after", candidate)}
        results["spm"] = spm(candidate)
        version = results["spm"]["pin"]["state"]["version"]
        for label in ["before", "after"]:
            if f"AnyCodable-FlightSchool ({version})" not in results[label]["pods"]:
                raise ValueError(f"AnyCodable versions differ in {label}")
        (report_dir / "results.json").write_text(json.dumps(results, indent=2) + "\n")
        names = sorted(set().union(*(result["binaries"] for result in results.values())))
        rows = ["# Compiled SDK size", "", "| Binary | CocoaPods before | CocoaPods after | SPM reference |", "| --- | ---: | ---: | ---: |"]
        for name in names:
            sizes = [result["binaries"].get(name, {}).get("bytes", 0) for result in results.values()]
            rows.append(f"| {name} | " + " | ".join(f"{size:,}" for size in sizes) + " |")
        totals = [sum(binary["bytes"] for binary in result["binaries"].values()) for result in results.values()]
        rows.append("| **Total bytes** | " + " | ".join(f"**{total:,}**" for total in totals) + " |")
        reduction = totals[0] - totals[1]
        rows += ["", f"CocoaPods reduction: **{reduction:,} bytes ({reduction / totals[0]:.2%})**.", "", "Method: iOS arm64, Release, Swift 5, -O, whole-module optimization; dynamic framework binaries stripped with `strip -S -x`. Sizes exclude resources, module metadata, debug symbols, and app packaging. These are library sizes, not App Store download sizes.", "", "CocoaPods uses the projects generated by `pod lib lint`. The SPM reference uses the candidate source and the committed AnyCodable revision. Only its temporary package manifests change: both library products are dynamic and AnyCodable uses a local checkout, so the binary type matches CocoaPods. Original and fixture manifests are included in the artifact.", "", f"Baseline: `{metadata['baseline_sha']}`. Candidate: `{metadata['candidate_sha']}`.", f"Identical SDK source trees: **{metadata['baseline_sources_sha256'] == metadata['candidate_sources_sha256']}**.", f"AnyCodable: `{version}`. Xcode: `{metadata['xcode'].replace(chr(10), ' / ')}`. iOS SDK: `{metadata['ios_sdk']}`.", "", "See `environment.json`, `results.json`, both CocoaPods lockfiles, `Package.resolved`, and `commands.log` for reproduction details.", ""]
        summary = "\n".join(rows)
        (report_dir / "summary.md").write_text(summary)
        if os.environ.get("GITHUB_STEP_SUMMARY"):
            with Path(os.environ["GITHUB_STEP_SUMMARY"]).open("a") as step_summary:
                step_summary.write(summary)
        print(summary)
