usingnamespace @import("../protocol.zig");
const Decodable = @import("zig-json-decode").Decodable;

pub const InitializationMessage = Decodable(InitializationMessageSkeleton);
pub const InitializationMessageSkeleton = struct {
    jsonrpc: []const u8,
    id: i64,
    method: []const u8,

    const Params = struct {
        processId: i64,
        rootPath: []const u8,
        rootUri: []const u8,

        const Capabilities = struct {
            const Workspace = struct {
                applyEdit: bool,

                const WorkspaceEdit = struct {
                    documentChanges: bool,
                    resourceOperations: [][]const u8,
                    failureHandling: []const u8,
                };
                workspaceEdit: WorkspaceEdit,

                const DidChangeConfiguration = struct {
                    dynamicRegistration: bool,
                };
                didChangeConfiguration: DidChangeConfiguration,

                const DidChangeWatchedFiles = struct {
                    dynamicRegistration: bool,
                };
                didChangeWatchedFiles: DidChangeWatchedFiles,

                const Symbol = struct {
                    dynamicRegistration: bool,

                    const SymbolKind = struct {
                        valueSet: []i64,
                    };
                    symbolKind: SymbolKind,
                };
                symbol: Symbol,

                const ExecuteCommand = struct {
                    dynamicRegistration: bool,
                };
                executeCommand: ExecuteCommand,
                configuration: bool,
                workspaceFolders: bool,
            };
            workspace: Workspace,
            textDocument: TextDocument,
        };
        capabilities: Capabilities,
        // const InitilizationOptions = struct {}; // do what we want to here
        // initializationOptions: []InitilizationOptions,
        trace: []const u8,

        const WorkspaceFolder = struct {
            uri: []const u8,
            name: []const u8,
        };
        workspaceFolders: []WorkspaceFolder,
    };
    params: Params,
};
