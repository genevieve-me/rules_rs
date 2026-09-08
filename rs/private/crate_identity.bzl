"""Cargo package identity, independent of compilation compatibility."""

load(":downloader.bzl", "parse_git_url")

def normalize_git_remote(remote):
    """Normalizes syntax that does not change a Git repository's identity."""
    remote = remote.removesuffix("/")
    remote = remote.removesuffix(".git")

    scheme_separator = remote.find("://")
    if scheme_separator == -1:
        return remote

    scheme = remote[:scheme_separator].lower()
    remainder = remote[scheme_separator + len("://"):]
    path_separator = remainder.find("/")
    if path_separator == -1:
        return scheme + "://" + remainder.lower()

    authority = remainder[:path_separator].lower()
    path = remainder[path_separator:]
    return scheme + "://" + authority + path

def package_identity(package, package_path = ""):
    source = package["source"]
    if source.startswith("sparse+"):
        return json.encode([
            "registry",
            source,
            package["name"],
            package["version"],
        ])
    if source.startswith("git+"):
        remote, commit = parse_git_url(source)
        return json.encode([
            "git",
            normalize_git_remote(remote),
            commit,
            package_path,
            package["name"],
            package["version"],
        ])
    return None

def crate_identity(package, package_path = ""):
    """Returns the reserved ``cargo:`` logical library identity for a package.

    Cargo Package IDs are opaque and complete: registry provenance carries the
    fully qualified source, Git provenance carries the normalized remote, pinned
    commit, and workspace member path. The same configured package always yields
    the same identity, so distinct compatibility classes for one package still
    share one logical ID and are caught by the link-unit validator when they
    converge in one artifact.
    """
    identity = package_identity(package, package_path)
    if not identity:
        return None
    return "cargo:" + identity
