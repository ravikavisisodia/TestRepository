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
