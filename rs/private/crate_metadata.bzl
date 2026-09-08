"""Source- and checkout-qualified Cargo metadata cache keys."""

def git_checkout_fingerprint(annotation):
    """Returns the repository-wide inputs that determine a Git checkout."""
    return {
        "patch_args": annotation.patch_args,
        "patch_tool": annotation.patch_tool or "",
        # Patch order is significant because each patch sees the output of the
        # preceding patch.
        "patches": [str(patch) for patch in annotation.patches],
        "workspace_cargo_toml": annotation.workspace_cargo_toml,
    }

def registry_fact_key(source, name, version):
    """Returns the source-qualified cache key for registry package facts."""
    return "rs_crate_fact_v2_registry_" + json.encode({
        "name": name,
        "source": source,
        "version": version,
    })

def git_fact_key(source, name, version, annotation, strip_prefix):
    """Returns the checkout- and layout-qualified cache key for Git facts."""
    return "rs_crate_fact_v2_git_" + json.encode({
        "checkout": git_checkout_fingerprint(annotation),
        "name": name,
        "source": source,
        "strip_prefix": strip_prefix or "",
        "version": version,
    })

def registry_metadata_prefixes(fetch_configs_by_source):
    """Assigns a deterministic staging prefix per registry source.

    The prefix depends only on the sorted source set, never on the order the
    hubs were traversed, so separate hubs select identical per-source metadata
    paths and the same crate name pulled from two registries lands in distinct
    metadata files.
    """
    return {
        source: "registry_metadata_%d" % index
        for index, source in enumerate(sorted(fetch_configs_by_source))
    }
