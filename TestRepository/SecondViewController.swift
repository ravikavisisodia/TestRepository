//
//  SecondViewController.swift
//  TestRepository
//
//  Created by Ravi Sisodia on 23/10/18.
//  Copyright © 2018 CultureAlley. All rights reserved.
//

import UIKit
import AdSupport

class SecondViewController: UIViewController {

	@IBOutlet var viewPager: ViewPager!

	@IBOutlet var label2: UILabel!
	override func viewDidLoad() {
		super.viewDidLoad()
		label2.text = "AdId: \(ASIdentifierManager.shared().advertisingIdentifier.uuidString)\nDevId: \(UIDevice.current.identifierForVendor?.uuidString ?? "NA")"
		
		self.viewPager.animationDuration = 0.5
		self.viewPager.offscreenPageLimit = 2
		self.viewPager.padding = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 50)
		self.viewPager.distanceBetweenPages = 10
		self.viewPager.dataSource = self
		self.viewPager.delegate = self
	}
	
	private var timer: Timer?
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
//		self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.updatePage), userInfo: nil, repeats: true)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		self.timer?.invalidate()
	}
	
	@objc private func updatePage() {
		self.viewPager.currentIndex = (self.viewPager.currentIndex + 3)%self.numberOfPages()
	}
}

extension SecondViewController: ViewPagerDataSource, ViewPagerDelegate {
	func parentController() -> UIViewController {
		return self
	}
	func numberOfPages() -> Int {
		return 10
	}
	func page(at index: Int) -> UIViewController {
		let vc = self.storyboard!.instantiateViewController(withIdentifier: "ItemViewController")
		vc.view.backgroundColor = [
			.red, .blue, .green, .yellow, .purple, .magenta, .cyan
		][index%6]
		DispatchQueue.main.async {
			(vc.view.subviews.first as? UILabel)?.text = "Screen #\(index)"
		}
		return vc
	}
	func forceUpdate(page: UIViewController, at index: Int) -> Bool {
		return false
	}
	var isAllowedToLoadPreviousPage: Bool {
		return true
	}
	var isAllowedToLoadNextPage: Bool {
		return true
	}
	
	func pager(_ pager: ViewPager, willReplace viewController1: UIViewController?, at index1: Int, with viewController2: UIViewController, at index2: Int) {
	}
	func pager(_ pager: ViewPager, didReplace viewController1: UIViewController?, at index1: Int, with viewController2: UIViewController, at index2: Int) {
	}
}

//
//  ViewPager.swift
//  Hello English for Kids
//
//  Created by Ravi Sisodia on 28/09/18.
//  Copyright © 2018 CultureAlley. All rights reserved.
//

protocol ViewPagerDataSource {
	func parentController() -> UIViewController
	func numberOfPages() -> Int
	func page(at index: Int) -> UIViewController
	func forceUpdate(page: UIViewController, at index: Int) -> Bool

	var isAllowedToLoadPreviousPage: Bool { get }
	var isAllowedToLoadNextPage: Bool { get }
}

protocol ViewPagerDelegate {
	func pager(_ pager: ViewPager, willReplace viewController1: UIViewController?, at index1: Int, with viewController2: UIViewController, at index2: Int)
	func pager(_ pager: ViewPager, didReplace viewController1: UIViewController?, at index1: Int, with viewController2: UIViewController, at index2: Int)
}

open class ViewPager: UIView {
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		self.registerSwipeGesture()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		self.registerSwipeGesture()
	}
	
	private func registerSwipeGesture() {
		let p = UIPanGestureRecognizer(target: self, action: #selector(self.didRecognizePanGesture(_:)))
		p.maximumNumberOfTouches = 1
		self.gestureRecognizers = [p]
	}
	
	private var moveEnabled = true
	private var lastSwipeTranslation: CGPoint = .zero
	private var thresholdSpeedForSwipe: CGFloat = 500
	
	private var isAllowedToLoadPreviousPage: Bool {
		return self.dataSource?.isAllowedToLoadPreviousPage ?? false
	}
	private var isAllowedToLoadNextPage: Bool {
		return self.dataSource?.isAllowedToLoadNextPage ?? false
	}
	
	private var viewControllers = [UIViewController?]()
	
	var animationDuration: TimeInterval = 0.25
	var offscreenPageLimit = 1, distanceBetweenPages: CGFloat = 0, padding: UIEdgeInsets = .zero
	var dataSource: ViewPagerDataSource? {
		didSet {
			for viewController in self.viewControllers {
				viewController?.view.removeFromSuperview()
				viewController?.removeFromParent()
			}
			guard let ds = self.dataSource, ds.numberOfPages() > 0 else {
				return
			}

			self.viewControllers = [UIViewController?](repeating: nil, count: ds.numberOfPages())
			self.currentIndex = 0
		}
	}
	var delegate: ViewPagerDelegate?
	
	private var _currentIndex: Int = -1
	var currentIndex: Int {
		get {
			return self._currentIndex
		}
		set {
			self.setCurrent(index: newValue, completion: {})
		}
	}
	
	func setCurrent(index: Int, completion: @escaping () -> ()) {
		guard self.moveEnabled else {
			return
		}
		self.fifoQueue.append((to: index, completion: completion))
		if self.fifoQueue.count == 1 {
			self.move(from: self._currentIndex, to: index)
		}
	}

	private func isValidIndex(_ index: Int) -> Bool {
		return index >= 0 && index < self.viewControllers.count
	}
	
	private func updatableIndices(centeredAt index: Int) -> (willBeRemoved: [Int], willBeAdded: [Int])? {
		guard let ds = self.dataSource else {
			return nil
		}
		let willBeRemovedIndices = (0..<self.viewControllers.count).filter { i in
			return (i < index - self.offscreenPageLimit || i > index + self.offscreenPageLimit) && (self.viewControllers[i] != nil)
		}
		let willBeAddedIndices = (max(0, index - self.offscreenPageLimit)...min(ds.numberOfPages() - 1, index + self.offscreenPageLimit)).filter { i in
			if let vc = self.viewControllers[i], ds.forceUpdate(page: vc, at: i) {
				vc.view.removeFromSuperview()
				vc.removeFromParent()
				self.viewControllers[i] = nil
			}
			return self.viewControllers[i] == nil
		}
		return (willBeRemoved: willBeRemovedIndices, willBeAdded: willBeAddedIndices)
	}
	
	private func add(indices: [Int], using oldIndex: Int, and newIndex: Int) {
		guard let ds = self.dataSource else {
			return
		}
		let d = newIndex > oldIndex ? 1 : -1, parent = ds.parentController()
		let w = self.bounds.width - self.padding.left - self.padding.right
		let h = self.bounds.height - self.padding.top - self.padding.bottom
		let rtl = UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft

		for index in indices {
			let viewController = self.viewControllers[index] ?? ds.page(at: index)
			self.viewControllers[index] = viewController
			parent.addChild(viewController)
			self.addSubview(viewController.view)
			if d == 1 {
				if index == indices.first {
					if oldIndex != -1, let prev = self.viewControllers[oldIndex + self.offscreenPageLimit] {
						let x = prev.view.frame.origin.x + (rtl ? -1 : 1)*(w + self.distanceBetweenPages)
						viewController.view.frame = CGRect(x: x, y: self.padding.top, width: w, height: h)
					} else {
						viewController.view.frame = CGRect(x: self.padding.left, y: self.padding.top, width: w, height: h)
					}
				} else if let prev = self.viewControllers[index - 1] {
					let x = prev.view.frame.origin.x + (rtl ? -1 : 1)*(w + self.distanceBetweenPages)
					viewController.view.frame = CGRect(x: x, y: self.padding.top, width: w, height: h)
				}
			} else {
				if index == indices.first {
					if let next = self.viewControllers[oldIndex - self.offscreenPageLimit] {
						let x = next.view.frame.origin.x - (rtl ? -1 : 1)*(w + self.distanceBetweenPages)
						viewController.view.frame = CGRect(x: x, y: self.padding.top, width: w, height: h)
					} else {
						// Error
					}
				} else if let next = self.viewControllers[index + 1] {
					let x = next.view.frame.origin.x - (rtl ? -1 : 1)*(w + self.distanceBetweenPages)
					viewController.view.frame = CGRect(x: x, y: self.padding.top, width: w, height: h)
				}
			}
		}
	}

	private var fifoQueue = [(to: Int, completion: (() -> ()))]()
	private func move(from oldIndex: Int, to newIndex: Int) {
		let loadNext = {
			self.fifoQueue.remove(at: 0).completion()
			guard let next = self.fifoQueue.first else {
				return
			}
			self.move(from: self._currentIndex, to: next.to)
		}
		guard oldIndex != newIndex, self.isValidIndex(newIndex) else {
			return loadNext()
		}
		guard var indices = self.updatableIndices(centeredAt: newIndex), let ds = self.dataSource else {
			return loadNext()
		}

		let d = newIndex > oldIndex ? 1 : -1, parent = ds.parentController()
		indices.willBeAdded = d == -1 ? indices.willBeAdded.reversed() : indices.willBeAdded
		
		DispatchQueue.main.async {
			let o = self.isValidIndex(oldIndex) ? self.viewControllers[oldIndex] : nil
			self.delegate?.pager(self, willReplace: o, at: oldIndex, with: self.viewControllers[newIndex]!, at: newIndex)
		}
		
		for index in indices.willBeRemoved {
			self.viewControllers[index]?.willMove(toParent: nil)
		}
		self.add(indices: indices.willBeAdded, using: oldIndex, and: newIndex)
		
		let completion: ((Bool) -> ()) = { _ in
			for index in indices.willBeRemoved {
				let vc = self.viewControllers[index]
				vc?.view.removeFromSuperview()
				vc?.removeFromParent()
				self.viewControllers[index] = nil
			}
			for index in indices.willBeAdded {
				self.viewControllers[index]?.didMove(toParent: parent)
			}
			
			self._currentIndex = newIndex
			DispatchQueue.main.async {
				let o = self.isValidIndex(oldIndex) ? self.viewControllers[oldIndex] : nil
				self.delegate?.pager(self, didReplace: o, at: oldIndex, with: self.viewControllers[newIndex]!, at: newIndex)
			}
			self.fifoQueue.remove(at: 0).completion()
			if let next = self.fifoQueue.first {
				return self.move(from: self._currentIndex, to: next.to)
			}
		}
		
		if oldIndex == -1 {
			completion(true)
		} else {
			let frame = self.viewControllers[newIndex]?.view.frame ?? .zero, a = (frame.size.width + self.distanceBetweenPages)
			let f = (a - abs(frame.origin.x - self.padding.left))/a
			let rtl = UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft
			UIView.animate(withDuration: self.animationDuration*Double(f), animations: {
				for i in 0..<newIndex {
					guard let vc = self.viewControllers[i] else {
						continue
					}
					vc.view.frame.origin.x = self.padding.left - (rtl ? -1 : 1)*CGFloat(newIndex - i)*(vc.view.frame.size.width + self.distanceBetweenPages)
				}
				self.viewControllers[newIndex]?.view.frame.origin.x = self.padding.left
				for i in min(ds.numberOfPages() - 1, newIndex + 1)...min(ds.numberOfPages() - 1, newIndex + self.offscreenPageLimit) {
					guard let vc = self.viewControllers[i] else {
						continue
					}
					vc.view.frame.origin.x = self.padding.left + (rtl ? -1 : 1)*CGFloat(i - newIndex)*(vc.view.frame.size.width + self.distanceBetweenPages)
				}
			}, completion: completion)
		}
	}
	
	@objc private func didRecognizePanGesture(_ panGesture: UIPanGestureRecognizer) {
		guard self.isAllowedToLoadPreviousPage || self.isAllowedToLoadNextPage else {
			return
		}
		var t = panGesture.translation(in: self)
		let rtl = UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft
		t = rtl ? CGPoint(x: -t.x, y: t.y) : t
		if !self.isAllowedToLoadNextPage, t.x < 0 {
			return self.reset()
		}
		if !self.isAllowedToLoadPreviousPage, t.x > 0 {
			return self.reset()
		}
		switch panGesture.state {
		case .began: self.touchBegan(at: t)
		case .changed: self.touchTranslated(by: t)
		default: self.touchEnded(with: t, and: panGesture.velocity(in: self))
		}
	}
	
	private func touchBegan(at point: CGPoint) {
		self.moveEnabled = false
		self.lastSwipeTranslation = point
	}
	
	private func touchTranslated(by translation: CGPoint) {
		guard let ds = self.dataSource else {
			return self.reset()
		}
		let dx = translation.x - self.lastSwipeTranslation.x
		if self._currentIndex <= 0, dx > 0 {
			return self.reset() // TODO: show limit reached UI in left
		} else if let n = self.dataSource?.numberOfPages(), self._currentIndex >= n - 1, dx < 0 {
			return self.reset() // TODO: show limit reached UI in right
		}
		let rtl = UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft
		for i in max(0, self._currentIndex - self.offscreenPageLimit)...min(ds.numberOfPages() - 1, self._currentIndex + self.offscreenPageLimit) {
			guard let vc = self.viewControllers[i] else {
				continue
			}
			vc.view.frame.origin.x = vc.view.frame.origin.x + dx*(rtl ? -1 : 1)
		}
		self.lastSwipeTranslation = translation
	}
	
	func touchEnded(with translation: CGPoint, and velocity: CGPoint) {
		let dx = translation.x
		if self._currentIndex <= 0, dx > 0 {
			return self.reset() // TODO: show limit reached UI in left
		} else if let n = self.dataSource?.numberOfPages(), self._currentIndex >= n - 1, dx < 0 {
			return self.reset() // TODO: show limit reached UI in right
		}

		let w = self.bounds.width - self.padding.left - self.padding.right
		if abs(dx) > 0.6*w || abs(velocity.x) > self.thresholdSpeedForSwipe {
			self.moveEnabled = true
			self.setCurrent(index: self._currentIndex - (dx > 0 ? 1 : -1)) {
				self.resetVariables()
			}
		} else {
			self.reset()
		}
	}
	
	private func resetVariables() {
		self.lastSwipeTranslation = .zero
		self.moveEnabled = true
	}
	
	private func reset() {
		guard let ds = self.dataSource, let vc = self.viewControllers[self._currentIndex] else {
			return self.resetVariables()
		}
		let rtl = UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft
		let frame = vc.view.frame, a = (frame.size.width + self.distanceBetweenPages)
		let f = (a - abs(frame.origin.x - self.padding.left))/a
		UIView.animate(withDuration: self.animationDuration*Double(f), animations: {
			for i in max(0, self._currentIndex - self.offscreenPageLimit)..<self._currentIndex {
				guard let vc = self.viewControllers[i] else {
					continue
				}
				vc.view.frame.origin.x = self.padding.left - (rtl ? -1 : 1)*CGFloat(self._currentIndex - i)*(frame.size.width + self.distanceBetweenPages)
			}
			vc.view.frame.origin.x = self.padding.left
			for i in min(ds.numberOfPages() - 1, self._currentIndex + 1)...min(ds.numberOfPages() - 1, self._currentIndex + self.offscreenPageLimit) {
				guard let vc = self.viewControllers[i] else {
					continue
				}
				vc.view.frame.origin.x = self.padding.left + (rtl ? -1 : 1)*CGFloat(i - self._currentIndex)*(frame.size.width + self.distanceBetweenPages)
			}
		}) { _ in
			self.resetVariables()
		}
	}
}
