#if os(tvOS)
import QuartzCore
import SwiftUI
import UIKit

/// How much of the lead sheet fills the screen. Pressing the remote steps through them; Back steps back.
enum SheetZoom: CaseIterable {
    /// The page's width beside the lyrics.
    case fit
    /// The full width of the screen.
    case fill
    /// Twice that, panned around with the remote.
    case close

    var next: SheetZoom {
        switch self {
        case .fit: .fill
        case .fill: .close
        case .close: .fit
        }
    }

    var previous: SheetZoom? {
        switch self {
        case .fit: nil
        case .fill: .fit
        case .close: .fill
        }
    }

    fileprivate var scale: CGFloat {
        self == .close ? 2 : 1
    }
}

/// Lets the screen move the sheet in the steps the remote asks for.
final class SheetViewport {
    fileprivate weak var scrollView: SheetScrollView?

    /// Returns false when the sheet is already at that edge.
    @discardableResult
    func scroll(_ direction: MoveCommandDirection) -> Bool {
        scrollView?.scroll(direction) ?? false
    }
}

/// A lead sheet drawn from its PDF, sharp at every zoom level.
struct ZoomableSheet: UIViewRepresentable {
    let url: URL
    let zoom: SheetZoom
    let viewport: SheetViewport

    func makeUIView(context: Context) -> SheetScrollView {
        let view = SheetScrollView(url: url)
        viewport.scrollView = view
        return view
    }

    func updateUIView(_ view: SheetScrollView, context: Context) {
        view.setZoom(zoom)
    }
}

final class SheetScrollView: UIScrollView, UIScrollViewDelegate {
    private let pageView = UIView()
    private let tiledLayer = CATiledLayer()
    private let drawer: PDFPageDrawer?
    private let pageSize: CGSize
    private var zoom = SheetZoom.fit
    private var laidOutWidth: CGFloat = 0

    init(url: URL) {
        let page = CGPDFDocument(url as CFURL)?.page(at: 1)
        pageSize = page?.getBoxRect(.cropBox).size ?? CGSize(width: 612, height: 792)
        drawer = page.map(PDFPageDrawer.init)
        super.init(frame: .zero)

        delegate = self
        contentInsetAdjustmentBehavior = .never
        minimumZoomScale = 1
        maximumZoomScale = SheetZoom.close.scale
        bouncesZoom = false

        pageView.backgroundColor = .white
        addSubview(pageView)
        tiledLayer.delegate = drawer
        tiledLayer.tileSize = CGSize(width: 512, height: 512)
        // Detail for the closest zoom on a 4K screen: 2 for the zoom, times 2 for the screen.
        tiledLayer.levelsOfDetailBias = 2
        pageView.layer.addSublayer(tiledLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        tiledLayer.contentsScale = traitCollection.displayScale
    }

    /// The page is as wide as the view; the view widens when the lyrics make way for the sheet.
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        guard width > 0, abs(width - laidOutWidth) > 0.5 else { return }

        let topFraction = contentSize.height > 0 ? contentOffset.y / contentSize.height : 0
        let scale = zoomScale
        laidOutWidth = width
        zoomScale = 1
        pageView.frame = CGRect(x: 0, y: 0, width: width, height: width * pageSize.height / pageSize.width)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        tiledLayer.frame = pageView.bounds
        CATransaction.commit()
        tiledLayer.setNeedsDisplay()
        contentSize = pageView.frame.size
        zoomScale = scale
        contentOffset = clamped(CGPoint(x: contentOffset.x, y: topFraction * contentSize.height))
    }

    func setZoom(_ newZoom: SheetZoom) {
        guard newZoom != zoom else { return }
        zoom = newZoom
        let scale = newZoom.scale
        guard scale != zoomScale else { return }
        // Zoom around the middle of what's on screen.
        let center = CGPoint(x: bounds.midX / zoomScale, y: bounds.midY / zoomScale)
        let size = CGSize(width: bounds.width / scale, height: bounds.height / scale)
        let origin = CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2)
        zoom(to: CGRect(origin: origin, size: size), animated: true)
    }

    func scroll(_ direction: MoveCommandDirection) -> Bool {
        var offset = contentOffset
        switch direction {
        case .up: offset.y -= bounds.height * 0.6
        case .down: offset.y += bounds.height * 0.6
        case .left: offset.x -= bounds.width * 0.6
        case .right: offset.x += bounds.width * 0.6
        @unknown default: return false
        }
        let target = clamped(offset)
        guard target != contentOffset else { return false }
        setContentOffset(target, animated: true)
        return true
    }

    private func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(0, point.x), max(0, contentSize.width - bounds.width)),
            y: min(max(0, point.y), max(0, contentSize.height - bounds.height))
        )
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        pageView
    }
}

/// Draws the tiles of the page. CATiledLayer calls this on background threads, so it's kept off the main actor.
nonisolated private final class PDFPageDrawer: NSObject, CALayerDelegate {
    private let page: CGPDFPage
    private let box: CGRect

    init(page: CGPDFPage) {
        self.page = page
        box = page.getBoxRect(.cropBox)
    }

    func draw(_ layer: CALayer, in context: CGContext) {
        let bounds = layer.bounds
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(context.boundingBoxOfClipPath)
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: bounds.width / box.width, y: -bounds.height / box.height)
        context.translateBy(x: -box.minX, y: -box.minY)
        context.drawPDFPage(page)
    }
}
#endif
