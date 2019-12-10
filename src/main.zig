const std = @import("std");
const mem = std.mem;
const proto = @import("protocol.zig");
const Decoder = @import("zig-json-decode").Decodable;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // inline comments be like: bruh
    var allocator = &arena.allocator;
    var stdin = &std.io.getStdIn().inStream().stream;
    var stdout = &std.io.getStdOut().outStream().stream;
    var dbgFile = try (try std.fs.Dir.open("/Users/haze/src/ziglsp")).createFile("debug.log", .{});
    var dbgOut = &dbgFile.outStream().stream;

    var lspServer = Server.init(allocator, stdin, stdout, dbgOut);
    lspServer.start() catch |e| try dbgOut.print("LSP.start() error: {}\n", .{e});
}

const InStream = *std.io.InStream(std.os.ReadError);
const OutStream = *std.io.OutStream(std.os.WriteError);

const Server = struct {
    const Self = @This();

    // configuration
    in: InStream,
    out: OutStream,
    debug: ?OutStream,
    allocator: *mem.Allocator,

    // state
    // buffer: std.Buffer,

    fn init(allocator: *mem.Allocator, inStream: var, outStream: var, dbgStream: var) Self {
        return .{
            .in = inStream,
            .out = outStream,
            .debug = dbgStream,
            .allocator = allocator,
            // .buffer = try std.Buffer.initSize(allocator, 0),
        };
    }

    /// Starts loop responsible for serving LSP requests
    fn start(self: *Self) !void {
        while (true) {
            const content = self.readFrame() catch |e| {
                switch (e) {
                    error.EndOfStream => break,
                    else => {
                        std.debug.warn("Error: {}\n", .{e});
                        continue;
                    },
                }
            };
            if (self.debug) |d| {
                try d.print("Content: {}\n", .{content});
                const req = self.parseMessage(content) catch |e| {
                    switch (e) {
                        error.UnknownMessage => {
                            try d.print("Unknown message: {}\n", .{e});
                            continue;
                        },
                        else => return e,
                    }
                };
                try d.print("{}\n", .{req});
            }
        }
    }

    fn parseMessage(self: Self, contents: []const u8) !proto.Request {
        var parser = std.json.Parser.init(self.allocator, false);
        defer parser.deinit();
        const root = (try parser.parse(contents)).root.Object;

        const initAttempt = proto.InitializationMessage.fromJson(.{ .ignoreMissing = true }, self.allocator, root) catch |e| switch (e) {
            error.MissingField => null,
            else => return e,
        };

        if (initAttempt) |attempt| {
            return proto.Request{ .Initialization = attempt };
        }

        return error.UnknownMessage;
    }

    const Error = error{
        UnsupportedEncoding,
        MalforedFrame,
        EndOfStream,
    } || std.fmt.ParseUnsignedError || mem.Allocator.Error || std.os.WriteError || std.os.ReadError;

    fn readLine(self: *Self) ![]const u8 {
        var buffer = try std.Buffer.initCapacity(self.allocator, 0);
        return std.io.readLineFrom(self.in, &buffer);
    }

    fn readN(self: *Self, n: usize) ![]const u8 {
        var buf = try std.Buffer.initCapacity(self.allocator, n);
        var c: usize = 0;
        while (c < n) : (c += 1) {
            try buf.appendByte(try self.in.readByte());
        }
        return buf.toOwnedSlice();
    }

    fn readFrame(self: *Self) Error![]const u8 {
        var contentLength: ?usize = null;
        while (contentLength == null) {
            const line = try self.readLine();
            if (line.len > 0) {
                if (mem.indexOfScalar(u8, line, ':')) |sepIndex| {
                    const kind = line[0..sepIndex];
                    const value = mem.trimLeft(u8, line[sepIndex + 1 ..], " \t");
                    if (mem.eql(u8, kind, "Content-Type")) {
                        const utf8Ind = mem.indexOf(u8, value, "utf8") orelse null;
                        const utf8DashInd = mem.indexOf(u8, value, "utf-8") orelse null;
                        if (utf8Ind == null and utf8DashInd == null) return error.UnsupportedEncoding;
                    } else if (mem.eql(u8, kind, "Content-Length")) {
                        contentLength = try std.fmt.parseInt(usize, value, 10);
                    }
                }
            }
        }
        return mem.trimLeft(u8, try self.readN(contentLength.? + 2), " \r\n\t"); // TODO stripWhitespace
    }

    fn respond(self: *Self, line: []const u8) Error!?[]const u8 {}
};
