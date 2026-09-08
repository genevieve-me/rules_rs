load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("@rules_rust//rust:rust_common.bzl", "CrateInfo")

def _identity_check(expect_set):
    """Creates an analysis test asserting the target's crate_identity presence.

    `expect_set` True asserts a RustCrateIdentityInfo whose crate_instance is the
    configured CrateInfo output; False asserts the identity is absent.
    """

    def _impl(ctx):
        env = analysistest.begin(ctx)
        target = analysistest.target_under_test(env)
        identity = target[CrateInfo].crate_identity
        if expect_set:
            asserts.true(env, identity != None)
            asserts.equals(env, target.label, identity.owner)
            asserts.equals(env, target[CrateInfo].output, identity.crate_instance)
            asserts.equals(env, target[CrateInfo].name, identity.display_name)
        else:
            asserts.equals(env, None, identity)
        return analysistest.end(env)

    return analysistest.make(_impl)

library_identity_test = _identity_check(expect_set = True)

proc_macro_identity_test = _identity_check(expect_set = True)

no_identity_test = _identity_check(expect_set = False)

def _git_generated_identity_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    identity = target[CrateInfo].crate_identity

    asserts.true(env, identity != None)
    asserts.true(env, identity.logical_id.startswith("cargo:[\"git\","))
    asserts.true(env, '"o2o"' in identity.logical_id)
    asserts.true(env, '"0.5.4"' in identity.logical_id)
    return analysistest.end(env)

git_generated_identity_test = analysistest.make(_git_generated_identity_impl)

def cargo_crate_identity_info_tests():
    library_identity_test(
        name = "library_identity_test",
        target_under_test = ":metadata_crate",
    )

    proc_macro_identity_test(
        name = "proc_macro_identity_test",
        target_under_test = ":proc_metadata",
    )

    no_identity_test(
        name = "generated_binary_no_identity_test",
        target_under_test = ":tool__bin",
    )

    no_identity_test(
        name = "build_script_no_identity_test",
        target_under_test = ":_bs_",
    )

    git_generated_identity_test(
        name = "git_extension_generated_identity_test",
        target_under_test = "@git_crates//:o2o-0.5.4",
    )
