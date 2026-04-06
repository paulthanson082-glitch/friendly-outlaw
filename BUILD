load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

package(default_visibility = ["//visibility:public"])

pkg_tar(
    name = "friendly_outlaw_source",
    srcs = glob(
        ["Sources/**"],
        exclude = ["Sources/**/*.swiftdeps"],
    ),
    strip_prefix = "/",
)

# Export build configuration
filegroup(
    name = "config_files",
    srcs = [
        ".bazelversion",
        "WORKSPACE",
        "Package.swift",
    ],
)
