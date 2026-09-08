load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(":crate_metadata.bzl", "git_fact_key", "registry_fact_key")

_REGISTRY = "sparse+https://index.crates.io/"

_OTHER_REGISTRY = "sparse+https://registry.example.com/index/"

_GIT = "git+https://example.com/workspace.git?rev=main#0123456789abcdef"

def _annotation(
        additive_build_file = None,
        additive_build_file_content = "",
        gen_binaries = [],
        patch_args = [],
        patch_tool = None,
        patches = [],
        workspace_cargo_toml = "Cargo.toml"):
    return struct(
        additive_build_file = additive_build_file,
        additive_build_file_content = additive_build_file_content,
        gen_binaries = gen_binaries,
        patch_args = patch_args,
        patch_tool = patch_tool,
        patches = patches,
        workspace_cargo_toml = workspace_cargo_toml,
    )

def _fact_keys_are_schema_qualified_impl(ctx):
    env = unittest.begin(ctx)
    registry = registry_fact_key(_REGISTRY, "crate", "1.0.0")
    asserts.true(env, registry.startswith("rs_crate_fact_v2_registry_"))
    for key in [
        registry_fact_key(_OTHER_REGISTRY, "crate", "1.0.0"),
        registry_fact_key(_REGISTRY, "other", "1.0.0"),
        registry_fact_key(_REGISTRY, "crate", "2.0.0"),
    ]:
        asserts.true(env, registry != key)

    annotation = _annotation()
    git = git_fact_key(_GIT, "crate", "1.0.0", annotation, "member")
    asserts.true(env, git.startswith("rs_crate_fact_v2_git_"))
    for key in [
        git_fact_key("git+https://other.example/repo#0123456789abcdef", "crate", "1.0.0", annotation, "member"),
        git_fact_key(_GIT, "crate", "2.0.0", annotation, "member"),
        git_fact_key(_GIT, "crate", "1.0.0", _annotation(patches = [Label("//:patch")]), "member"),
        git_fact_key(_GIT, "crate", "1.0.0", _annotation(workspace_cargo_toml = "nested/Cargo.toml"), "member"),
        git_fact_key(_GIT, "crate", "1.0.0", annotation, "other"),
    ]:
        asserts.true(env, git != key)
    return unittest.end(env)

fact_keys_are_schema_qualified_test = unittest.make(_fact_keys_are_schema_qualified_impl)

def crate_metadata_tests():
    fact_keys_are_schema_qualified_test(name = "fact_keys_are_schema_qualified_test")
