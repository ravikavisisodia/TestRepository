//
//  FirstViewController.swift
//  TestRepository
//
//  Created by Ravi Sisodia on 23/10/18.
//  Copyright © 2018 CultureAlley. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {
	
	private lazy var box: UIView = {
		let f = self.view.frame, c = self.view.center

		let box = UIView()
		box.frame = CGRect(x: 0, y: c.y - 200, width: f.width, height: 400)
		box.backgroundColor = .yellow
		self.view.addSubview(box)
		return box
	}()
	
	private var ballFrame: CGRect {
		return CGRect(x: self.view.center.x/2 - 36, y: 0, width: 72, height: 72)
//		return CGRect(x: 0, y: self.box.frame.height - 30, width: 30, height: 30)
	}
	
	private lazy var ball: UIView = {
		let ball = UIView()
		ball.frame = self.ballFrame
		ball.layer.cornerRadius = ball.frame.size.width/2
		ball.backgroundColor = .red
		self.box.addSubview(ball)
		return ball
	}()
	
	private var animator: UIDynamicAnimator!

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		self.ball.frame = self.ballFrame
		self.animator = UIDynamicAnimator(referenceView: self.box)
		
		let collider = UICollisionBehavior(items: [self.ball])
		collider.translatesReferenceBoundsIntoBoundary = true
		self.animator.addBehavior(collider)
		
//		let gravity = UIGravityBehavior(items: [self.ball])
//		self.animator.addBehavior(gravity)
		
		let elasticity = UIDynamicItemBehavior(items: [self.ball])
		elasticity.elasticity = 0.6
//		elasticity.density = 1000
		elasticity.addAngularVelocity(50, for: self.ball)
		elasticity.addLinearVelocity(CGPoint(x: 200, y: 1000), for: self.ball)
		self.animator.addBehavior(elasticity)
	}
}
