workspace(name = "friendly_outlaw")

# Load Swift rules
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "aaaa",  # Update with actual SHA256
    url = "https://github.com/bazelbuild/rules_swift/releases/download/1.12.0/rules_swift.1.12.0.tar.gz",
)

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

# Register Swift toolchain
register_toolchains(
    "@build_bazel_rules_swift//swift:default_toolchain",
)
