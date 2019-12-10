const Decodable = @import("zig-json-decode").Decodable;

const Message = struct {
    jsonrpc: []const u8,
};

pub const TextDocument = struct {
    const PublishDiagnostics = struct {
        relatedInformation: bool,
    };
    publishDiagnostics: PublishDiagnostics,

    const Synchronization = struct {
        dynamicRegistration: bool,
        willSave: bool,
        willSaveWaitUntil: bool,
        didSave: bool,
    };
    synchronization: Synchronization,
    const Completion = struct {
        dynamicRegistration: bool,
        contextSupport: bool,
        const CompletionItem = struct {
            snippetSupport: bool,
            commitCharacterSupport: bool,
        };
        completionItem: CompletionItem,
    };
    completion: Completion,
};

const Any = struct {
    const Kind = union(enum) {
        Number,
        String,
        Boolean,
    };

    kind: Kind,
    ptr: usize,
};

usingnamespace @import("protocol/initialization.zig");

pub const Request = union(enum) {
    Initialization: InitializationMessageSkeleton,
};
