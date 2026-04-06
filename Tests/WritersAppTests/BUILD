load("@build_bazel_rules_swift//swift:swift.bzl", "swift_test")

package(default_visibility = ["//visibility:public"])

swift_test(
    name = "WritersAppTests",
    srcs = glob(["*.swift"]),
    deps = [
        "//Sources/WritersApp:WritersApp",
    ],
)
