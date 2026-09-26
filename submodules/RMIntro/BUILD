load("//build-system/bazel-utils:unique_directories.bzl", "unique_directories")

private_headers = glob([
    "Sources/**/*.h",
])

objc_library(
    name = "RMIntro",
    enable_modules = True,
    module_name = "RMIntro",
    srcs = glob([
        "Sources/**/*.m",
    ], exclude = [
        "Sources/platform/ios/texture_helper.m",
    ]) + private_headers,
    hdrs = glob([
        "PublicHeaders/**/*.h",
    ]),
    includes = [
        "PublicHeaders",
    ],
    copts = [
        "-I{}/{}".format(package_name(), directory) for directory in unique_directories(private_headers)
    ] + [
        "-Werror",
        "-I{}/PublicHeaders/RMIntro".format(package_name()),
    ],
    deps = [
        "//submodules/LegacyComponents:LegacyComponents",
    ],
    sdk_frameworks = [
        "Foundation",
        "UIKit",
    ],
    visibility = [
        "//visibility:public",
    ],
)
