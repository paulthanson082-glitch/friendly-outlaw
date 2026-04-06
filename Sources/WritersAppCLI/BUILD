load("@build_bazel_rules_swift//swift:swift.bzl", "swift_binary")

package(default_visibility = ["//visibility:public"])

swift_binary(
    name = "WritersAppCLI",
    srcs = ["main.swift"],
    deps = [
        "//Sources/WritersApp:WritersApp",
    ],
)
