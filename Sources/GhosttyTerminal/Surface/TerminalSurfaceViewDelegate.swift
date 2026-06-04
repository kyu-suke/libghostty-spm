//
//  TerminalSurfaceViewDelegate.swift
//  libghostty-spm
//
//  Created by Lakr233 on 2026/3/16.
//

import CoreGraphics
import Foundation
import GhosttyKit

@MainActor
public protocol TerminalSurfaceViewDelegate: AnyObject {}

@MainActor
public protocol TerminalSurfaceTitleDelegate: TerminalSurfaceViewDelegate {
    func terminalDidChangeTitle(_ title: String)
}

@MainActor
public protocol TerminalSurfaceGridResizeDelegate: TerminalSurfaceViewDelegate {
    func terminalDidResize(_ size: TerminalGridMetrics)
}

@MainActor
public protocol TerminalSurfaceResizeDelegate: TerminalSurfaceViewDelegate {
    func terminalDidResize(columns: Int, rows: Int)
}

@MainActor
public protocol TerminalSurfaceFocusDelegate: TerminalSurfaceViewDelegate {
    func terminalDidChangeFocus(_ focused: Bool)
}

@MainActor
public protocol TerminalSurfaceBellDelegate: TerminalSurfaceViewDelegate {
    func terminalDidRingBell()
}

@MainActor
public protocol TerminalSurfaceCloseDelegate: TerminalSurfaceViewDelegate {
    func terminalDidClose(processAlive: Bool)
}

// MARK: - Extended action delegates

/// State of an OSC 9;4 / DECSET progress report.
public enum TerminalProgressState: Sendable {
    case remove
    case set
    case error
    case indeterminate
    case pause

    init?(_ raw: ghostty_action_progress_report_state_e) {
        switch raw {
        case GHOSTTY_PROGRESS_STATE_REMOVE: self = .remove
        case GHOSTTY_PROGRESS_STATE_SET: self = .set
        case GHOSTTY_PROGRESS_STATE_ERROR: self = .error
        case GHOSTTY_PROGRESS_STATE_INDETERMINATE: self = .indeterminate
        case GHOSTTY_PROGRESS_STATE_PAUSE: self = .pause
        default: return nil
        }
    }
}

/// OSC 9;4 progress report (state + 0-100 percent, nil percent when the
/// emitter didn't provide one — e.g. INDETERMINATE / REMOVE).
@MainActor
public protocol TerminalSurfaceProgressReportDelegate: TerminalSurfaceViewDelegate {
    func terminalDidReportProgress(state: TerminalProgressState, percent: Int?)
}

/// Fires when a shell-integration-aware command exits. `exitCode` is nil
/// when not reported; `duration` is the wall clock in nanoseconds.
@MainActor
public protocol TerminalSurfaceCommandFinishedDelegate: TerminalSurfaceViewDelegate {
    func terminalDidFinishCommand(exitCode: Int?, durationNanos: UInt64)
}

/// OSC 9 (iTerm2) / OSC 777 (rxvt-unicode) desktop notification.
/// Empty title/body surface as empty strings rather than nil.
@MainActor
public protocol TerminalSurfaceDesktopNotificationDelegate: TerminalSurfaceViewDelegate {
    func terminalDidRequestDesktopNotification(title: String, body: String)
}

public enum TerminalOpenURLKind: Sendable {
    case unknown
    case text
    case html

    init(_ raw: ghostty_action_open_url_kind_e) {
        switch raw {
        case GHOSTTY_ACTION_OPEN_URL_KIND_TEXT: self = .text
        case GHOSTTY_ACTION_OPEN_URL_KIND_HTML: self = .html
        default: self = .unknown
        }
    }
}

/// User activated (cmd-clicked) a hyperlink inside the terminal grid.
@MainActor
public protocol TerminalSurfaceOpenURLDelegate: TerminalSurfaceViewDelegate {
    func terminalDidRequestOpenURL(_ url: String, kind: TerminalOpenURLKind)
}

/// Mouse hovered over a recognized hyperlink. nil = hover ended / link lost.
@MainActor
public protocol TerminalSurfaceHoverLinkDelegate: TerminalSurfaceViewDelegate {
    func terminalDidUpdateHoverLink(_ url: String?)
}

/// OSC 7 working-directory update.
@MainActor
public protocol TerminalSurfacePwdDelegate: TerminalSurfaceViewDelegate {
    func terminalDidChangeWorkingDirectory(_ path: String)
}

/// User long-pressed to request a selection-page presentation.
public struct TerminalTextSelectionRequest: Sendable {
    /// Viewport text snapshot. Lines separated by `\n`.
    public let text: String

    /// Recommended pre-selection range in UTF-16 units, suitable for direct
    /// assignment to `UITextView.selectedRange`. `nil` means the host should
    /// `selectAll` instead.
    public let anchorRange: NSRange?

    /// Long-press point in the terminal view's coordinate space (points).
    /// Hosts may use this as a popover anchor.
    public let sourcePoint: CGPoint
}

@MainActor
public protocol TerminalSurfaceTextSelectionRequestDelegate: TerminalSurfaceViewDelegate {
    func terminalDidRequestTextSelection(_ request: TerminalTextSelectionRequest)
}

/// Notifies a delegate when the underlying ``TerminalSurface`` is created or
/// torn down. Useful when a consumer needs surface-level APIs (e.g.
/// ``TerminalSurface/sendText(_:)``) reachable from outside the platform view.
@MainActor
public protocol TerminalSurfaceLifecycleDelegate: TerminalSurfaceViewDelegate {
    func terminalDidAttachSurface(_ surface: TerminalSurface)
    func terminalDidDetachSurface()
}

/// Surface 内検索の状態変化を受け取る delegate。
///
/// ghostty 内部の検索エンジン (apprt action 経由) からの通知を受け、
/// apprt 側が検索 UI を表示・更新するために使う。
///
/// - `terminalDidRequestStartSearch`: ghostty が検索 UI の起動を要求。`needle` は
///   初期検索語 (空 / nil の場合あり)。
/// - `terminalDidRequestEndSearch`: ghostty が検索 UI の終了を要求。
/// - `terminalDidUpdateSearchTotal`: 現在の検索結果総数の通知。
/// - `terminalDidUpdateSearchSelected`: 現在ハイライトされているヒットの 0-based インデックスの通知。
@MainActor
public protocol TerminalSurfaceSearchDelegate: TerminalSurfaceViewDelegate {
    func terminalDidRequestStartSearch(needle: String?)
    func terminalDidRequestEndSearch()
    func terminalDidUpdateSearchTotal(_ total: Int)
    func terminalDidUpdateSearchSelected(_ selected: Int)
}
