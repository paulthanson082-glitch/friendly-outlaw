load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

package(default_visibility = ["//visibility:public"])

swift_library(
    name = "WritersApp",
    srcs = glob(
        ["**/*.swift"],
        exclude = ["BUILD"],
    ),
    module_name = "WritersApp",
    deps = [
        "//Sources/WritersApp/Models",
        "//Sources/WritersApp/Services",
        "//Sources/WritersApp/Plugins",
        "//Sources/WritersApp/Views",
        "//Sources/WritersApp/Extensions",
        "//Sources/WritersApp/Previews",
    ],
)
