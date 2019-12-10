const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("ziglsp", "src/main.zig");
    exe.setOutputDir("zig-cache");
    exe.setBuildMode(mode);
    exe.install();
    exe.addPackagePath("zig-json-decode", "zig-json-decode/src/main.zig");

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
