import Foundation
import UIKit

public protocol SortedSet: BidirectionalCollection, CustomStringConvertible where Element: Comparable {
    
    init()
    func contains(_ element: Element) -> Bool

    @discardableResult
    mutating func insert(_ element: Element) -> (hasInserted: Bool, memberAfterInsert: Element)
}

extension PlaygroundQuickLook {
    public static func monospacedText(_ string: String) -> PlaygroundQuickLook {
        let text = NSMutableAttributedString(string: string)
        let range = NSRange(location: 0, length: text.length)
        let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        style.lineSpacing = 0
        style.alignment = .left
        style.maximumLineHeight = 17
        text.addAttribute(.font, value: UIFont(name: "Menlo", size: 13)!, range: range)
        text.addAttribute(.paragraphStyle, value: style, range: range)
        return PlaygroundQuickLook.attributedString(text)
    }
}

extension SortedSet {
    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        return .monospacedText(String(describing: self))
    }
}
