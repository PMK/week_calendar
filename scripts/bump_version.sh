#!/usr/bin/env bash

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repository_root="$(cd "$script_directory/.." && pwd)"
cd "$repository_root"

version_file="pubspec.yaml"
app_version_file="lib/main.dart"
changelog_directory="fastlane/metadata/android/en-US/changelogs"
release_files=(
  ".github/workflows/build.yml"
  ".github/workflows/release.yml"
  "scripts/bump_version.sh"
  "test/widget_test.dart"
)
bump="${1:-patch}"
target_branch="${2:-$(git branch --show-current)}"

usage() {
  echo "Usage: $0 [patch|minor|major|X.Y.Z] [target-branch]" >&2
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

[[ -f "$version_file" ]] || fail "$version_file not found. Run from repository root."
[[ -f "$app_version_file" ]] || fail "$app_version_file not found."
[[ -d "$changelog_directory" ]] || fail "$changelog_directory not found."
[[ -n "$target_branch" ]] || fail "Target branch required when HEAD is detached."

if ! git diff --quiet -- "$version_file" "$app_version_file" ||
  ! git diff --cached --quiet -- "$version_file" "$app_version_file"; then
  fail "Version files have uncommitted changes."
fi

current_full_version="$(
  awk '$1 == "version:" { print $2; exit }' "$version_file" | tr -d '\r'
)"

if [[ ! "$current_full_version" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\+([1-9][0-9]*)$ ]]; then
  fail "Expected version: X.Y.Z+BUILD in $version_file, found '$current_full_version'."
fi

current_major="${BASH_REMATCH[1]}"
current_minor="${BASH_REMATCH[2]}"
current_patch="${BASH_REMATCH[3]}"
current_build="${BASH_REMATCH[4]}"

case "$bump" in
  patch)
    next_major="$current_major"
    next_minor="$current_minor"
    next_patch=$((current_patch + 1))
    ;;
  minor)
    next_major="$current_major"
    next_minor=$((current_minor + 1))
    next_patch=0
    ;;
  major)
    next_major=$((current_major + 1))
    next_minor=0
    next_patch=0
    ;;
  *)
    if [[ ! "$bump" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
      usage
      fail "Version must be patch, minor, major, or strict SemVer X.Y.Z."
    fi

    next_major="${BASH_REMATCH[1]}"
    next_minor="${BASH_REMATCH[2]}"
    next_patch="${BASH_REMATCH[3]}"

    if ((next_major < current_major)) ||
      ((next_major == current_major && next_minor < current_minor)) ||
      ((next_major == current_major && next_minor == current_minor && next_patch <= current_patch)); then
      fail "Specific version $bump must be greater than $current_major.$current_minor.$current_patch."
    fi
    ;;
esac

latest_changelog_number="$(
  find "$changelog_directory" -maxdepth 1 -type f -name '*.txt' -print |
    sed -E 's#^.*/([0-9]+)\.txt$#\1#' |
    sort -n |
    tail -1
)"
[[ -n "$latest_changelog_number" ]] ||
  fail "No numeric changelog files found in $changelog_directory."
next_changelog_number=$((10#$latest_changelog_number + 1))
next_build="$next_changelog_number"
((next_build > current_build)) ||
  fail "Next changelog number must exceed current Android versionCode $current_build."
((next_build <= 2100000000)) || fail "Android versionCode exceeds 2100000000."

next_version_name="$next_major.$next_minor.$next_patch"
next_full_version="$next_version_name+$next_build"
changelog_file="$changelog_directory/$next_changelog_number.txt"
[[ ! -e "$changelog_file" ]] || fail "$changelog_file already exists."

release_boundary="$(
  git log --format='%H%x09%s' |
    awk -F '\t' '$2 ~ /^chore\(release\): bump version to / { print $1; exit }'
)"
if [[ -z "$release_boundary" ]]; then
  release_boundary="$(
    git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || true
  )"
fi

if [[ -n "$release_boundary" ]]; then
  commit_range="$release_boundary..HEAD"
else
  commit_range="HEAD"
fi

changelog_entries="$(
  git log "$commit_range" --no-merges --format='%s' |
    grep -Ev '^chore\(release\): bump version to ' || true
)"
if [[ -z "$changelog_entries" ]]; then
  fail "No commits found since the previous release."
fi

pubspec_temporary_file="$(mktemp "${TMPDIR:-/tmp}/week-calendar-pubspec.XXXXXX")"
app_temporary_file="$(mktemp "${TMPDIR:-/tmp}/week-calendar-main.XXXXXX")"
changelog_temporary_file="$(mktemp "${TMPDIR:-/tmp}/week-calendar-changelog.XXXXXX")"
trap 'rm -f "$pubspec_temporary_file" "$app_temporary_file" "$changelog_temporary_file"' EXIT

awk -v next_full_version="$next_full_version" '
  $1 == "version:" {
    print "version: " next_full_version
    updated = 1
    next
  }
  { print }
  END {
    if (!updated) {
      exit 1
    }
  }
' "$version_file" >"$pubspec_temporary_file"

awk -v next_version_name="$next_version_name" '
  BEGIN {
    quote = sprintf("%c", 39)
  }
  /static const _appVersion =/ {
    print "  static const _appVersion = " quote next_version_name quote ";"
    updated = 1
    next
  }
  { print }
  END {
    if (!updated) {
      exit 1
    }
  }
' "$app_version_file" >"$app_temporary_file"

printf '%s\n' "$changelog_entries" |
  sed 's/^/- /' >"$changelog_temporary_file"

mv "$pubspec_temporary_file" "$version_file"
mv "$app_temporary_file" "$app_version_file"
mv "$changelog_temporary_file" "$changelog_file"
trap - EXIT

commit_files=("$version_file" "$app_version_file" "$changelog_directory")
for release_file in "${release_files[@]}"; do
  if [[ -e "$release_file" ]]; then
    commit_files+=("$release_file")
  fi
done

git add -- "${commit_files[@]}"
git commit --only -m "chore(release): bump version to $next_version_name" -- \
  "${commit_files[@]}"
commit_sha="$(git rev-parse HEAD)"
git push origin "HEAD:$target_branch"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "version=$next_version_name"
    echo "build_number=$next_build"
    echo "changelog_file=$changelog_file"
    echo "commit_sha=$commit_sha"
  } >>"$GITHUB_OUTPUT"
fi

echo "Bumped to $next_version_name and pushed to $target_branch."
