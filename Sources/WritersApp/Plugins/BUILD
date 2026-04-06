load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

package(default_visibility = ["//visibility:public"])

swift_library(
    name = "Plugins",
    srcs = glob(["*.swift"]),
    module_name = "WritersAppPlugins",
    deps = ["//Sources/WritersApp/Models"],
)
