//
//  Processes.swift
//  SyncthingBar
//
//  Created by John on 11/11/2016.
//  Copyright © 2016 Olive Toast Software Ltd. All rights reserved.
//

//import Darwin
import Foundation

enum ProcessesError : Error {
    case procListError
}

struct ProcInfo {
    let pid: Int32
    let path: String
}

struct Processes {

    static func listPids() -> [Int32] {
        let pnum = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        var pids = [pid_t](repeating:0, count:Int(pnum))

        let _ = pids.withUnsafeMutableBufferPointer{ ptr in
            proc_listpids(UInt32(PROC_ALL_PIDS), 0, ptr.baseAddress, pnum * Int32(MemoryLayout<pid_t>.size))
        }

        return pids
    }

    static func list() -> [ProcInfo] {
        var list = [ProcInfo]()

        for pid in self.listPids() {
            if pid == 0 {
                continue
            }

            let cpath = UnsafeMutablePointer<CChar>.allocate(capacity:Int(MAXPATHLEN))
            proc_pidpath(pid, cpath, UInt32(MAXPATHLEN))

            if strlen(cpath) > 0 {
                let path = String(cString: cpath)
                list.append(ProcInfo(pid:pid, path:path))
            }
        }

        return list
    }

    static func find(processName: String) -> ProcInfo? {
        for pid in self.listPids() {
            if pid == 0 {
                continue
            }

            let cpath = UnsafeMutablePointer<CChar>.allocate(capacity:Int(MAXPATHLEN))
            proc_pidpath(pid, cpath, UInt32(MAXPATHLEN))

            guard strlen(cpath) > 0 else {
                continue
            }

            let path = String(cString:cpath)
            let url = URL(fileURLWithPath:path)

            if url.lastPathComponent == processName {
                return ProcInfo(pid:pid, path:path)
            }
        }
        return nil
    }
}
