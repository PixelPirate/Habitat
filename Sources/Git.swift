/*
import CLibgit2
import Foundation

fileprivate class LibGitHandle {
    init() {
        git_libgit2_init()
    }

    deinit {
        git_libgit2_shutdown()
    }
}

final class Git {
    enum Error: Swift.Error {
        case internalError
        case error(String)
    }

    private static var handle: LibGitHandle = LibGitHandle()

    /// Clones a Git repository.
    ///
    /// - Parameters:
    ///   - remote: A Git repository.
    ///   - to: A local URL with the folder in which the repo will be cloned. The folder will be created if it doesn't exist.
    /// - Throws: A `Git.Error` when something went wrong.
    static func clone(remote: URL, to: URL) throws {
        git_libgit2_init()
        defer {
            git_libgit2_shutdown()
        }

        let repository = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
        var options = git_clone_options()
        options.version = 1
        options.checkout_opts.version = 1
        options.checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE.rawValue
        options.fetch_opts.version = 1
        options.fetch_opts.prune = GIT_FETCH_PRUNE_UNSPECIFIED
        options.fetch_opts.update_fetchhead = 1
        options.fetch_opts.callbacks.version = 1
        options.fetch_opts.proxy_opts.version = 1
        //options.fetch_opts.callbacks.payload = //Passed to credentials callback
        // See https://github.com/damicreabox/Git2Swift/blob/a9e4d2ad7ef5265b8393561932bfd88fdab6a88f/Sources/Git2Swift/authentication/Authentication.swift
        options.fetch_opts.callbacks.credentials = { out, url, username_from_url, allowed_types, payload in
            return git_cred_userpass_plaintext_new(out, "codepirate", "k8m710")
        }

        guard git_clone(repository, remote.absoluteString, to.path, &options) == 0 else {
            let message = String(cString: giterr_last().pointee.message)
            throw Error.error("Can't clone remote repository \"\(remote.absoluteString)\" to path \"\(to.absoluteString)\". Error: \(message)")
        }
        git_repository_free(repository.pointee)
        repository.deinitialize()
        repository.deallocate(capacity: 1)
    }

    static func commit(ofRepositoryAt repositoryURL: URL) throws -> String {
        throw Error.internalError
    }

    static func fetch(repositoryAt respositoryURL: URL) throws {
        git_libgit2_init()
        defer {
            git_libgit2_shutdown()
        }

        let repository = UnsafeMutablePointer<OpaquePointer?>.allocate(capacity: 1)
        guard git_repository_open(repository, respositoryURL.path) == 0 else {
            let message = String(cString: giterr_last().pointee.message)
            throw Error.error("Can't open repository \"\(respositoryURL.path)\". Error: \(message)")
        }

        var remote: OpaquePointer? = nil
        guard git_remote_lookup(&remote, repository.pointee, "origin") == 0 else {
            let message = String(cString: giterr_last().pointee.message)
            throw Error.error("Can't find remote \"origin\". Error: \(message)")
        }

        var options = git_fetch_options()
        options.version = 1
        options.prune = GIT_FETCH_PRUNE_UNSPECIFIED
        options.update_fetchhead = 1
        options.callbacks.version = 1
        options.proxy_opts.version = 1
        options.callbacks.credentials = { out, url, username_from_url, allowed_types, payload in
            return git_cred_userpass_plaintext_new(out, "codepirate", "k8m710")
        }


        guard git_remote_fetch(remote, nil, &options, nil) == 0 else {
            let message = String(cString: giterr_last().pointee.message)
            throw Error.error("Can't fetch \"origin\". Error: \(message)")
        }
    }

    static func isClean(repositoryAt respositoryURL: URL) throws -> Bool {
        var repository: OpaquePointer?
        guard git_repository_open(&repository, respositoryURL.absoluteString) == 0 else {
            throw Error.error("Can't open repository at \"\(respositoryURL.absoluteString)\".")
        }

        var index: OpaquePointer?
        guard git_repository_index(&index, repository) == 0 else {
            throw Error.error("Can't read index of repository at \"\(respositoryURL.absoluteString)\".")
        }

        return git_index_entrycount(index) == 0
    }

    static func a(path: String) {
        var repository: OpaquePointer?
        git_repository_open(&repository, path)
        let call: git_status_cb = { (path: UnsafePointer<Int8>?, statusFlags: UInt32, payload: UnsafeMutableRawPointer?) in
            guard let path = path else {
                return 0
            }

            if statusFlags == GIT_STATUS_CURRENT.rawValue {
                let p = String(cString: path)
                let x = payload?.assumingMemoryBound(to: String.self)
                x?.pointee.append(p)
                return 1
            }
            return 0
        }
        var path = String()
        git_status_foreach(repository, call, &path)
        print("working dir status", path)

    }
}
*/
