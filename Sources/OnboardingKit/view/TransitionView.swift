//
//  TransitionView.swift
//  
//
//  Created by Joao Pedro Oliveira on 03/08/22.
//

import UIKit

class TransitionView: UIView {
    
    private var timer: DispatchSourceTimer?
    
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private lazy var barViews: [AnimatedBarView] = {
        var views: [AnimatedBarView] = []
        slides.forEach { _ in
            views.append(AnimatedBarView(barColor: viewTintColor))
        }
        return views
    }()
    
    private lazy var barStackView: UIStackView = {
        let stack = UIStackView()
        barViews.forEach { barView in
            stack.addArrangedSubview(barView)
        }
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var titleView: TitleView = {
        let view = TitleView(themeFont: themeFont)
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [imageView, titleView])
        stack.distribution = .fill
        stack.axis = .vertical
        return stack
    }()
    
    private let slides: [Slide]
    private let viewTintColor: UIColor
    private let themeFont: UIFont
    private var index: Int = -1
    
    var slideIndex: Int {
        return index
    }
    
    init(slides: [Slide], tintColor: UIColor, themeFont: UIFont) {
        self.slides = slides
        self.viewTintColor = tintColor
        self.themeFont = themeFont
        super.init(frame: .zero)
        layout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func start() {
        buildTimerIfNeeded()
        timer?.resume()
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
    }
    
    private func buildTimerIfNeeded() {
        guard timer == nil else { return }
        timer = DispatchSource.makeTimerSource()
        timer?.schedule(deadline: .now(), repeating: .seconds(3), leeway: .seconds(1))
        timer?.setEventHandler(handler: {
            DispatchQueue.main.async { [weak self] in
                self?.showNext()
            }
        })
    }
    
    private func showNext() {
        let nextImage: UIImage
        let nextTitle: String
        let nextBarView: AnimatedBarView
        
        if slides.indices.contains(index + 1) {
            nextImage = slides[index + 1].image
            nextTitle = slides[index + 1].title
            nextBarView = barViews[index + 1]
            index += 1
        } else {
            barViews.forEach({ $0.reset() })
            nextImage = slides[0].image
            nextTitle = slides[0].title
            nextBarView = barViews[0]
            index = 0
        }
        UIView.transition(with: imageView, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.imageView.image = nextImage
        }, completion: nil)
        
        titleView.setTitle(text: nextTitle)
        nextBarView.startAnimating()
    }
    
    private func layout() {
        addSubview(stackView)
        addSubview(barStackView)
        
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        barStackView.snp.makeConstraints { make in
            make.leading.equalTo(snp.leading).offset(24)
            make.trailing.equalTo(snp.trailing).offset(-24)
            make.top.equalTo(snp.topMargin)
            make.height.equalTo(4)
        }
        
        imageView.snp.makeConstraints { make in
            make.height.equalTo(stackView.snp.height).multipliedBy(0.8)
        }
    }
    
    func handleTap(direction: Direction) {
        switch direction {
        case .left:
            barViews[index].reset()
            if barViews.indices.contains(index - 1) {
                barViews[index - 1].reset()
            }
            index -= 2
        case .right:
            barViews[index].complete()
        }
        timer?.cancel()
        timer = nil
        start()
    }
}
