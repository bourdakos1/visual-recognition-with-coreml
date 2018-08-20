//
//  Analyzer.swift
//  Core ML Vision
//
//  Created by Nicholas Bourdakos on 8/17/18.
//

import UIKit

extension ImageClassificationViewController  {
    struct Point: Hashable {
        var x: Int
        var y: Int
        var cgPoint: CGPoint {
            return CGPoint(x: x, y: y)
        }
    }
    
    struct OutlineState {
        var position: Point = Point(x: 0, y: 0)
        var path: UIBezierPath = UIBezierPath()
        var pathStart: CGPoint = CGPoint(x: -1, y: -1)
        var velocity: Direction = .right
        var check: Direction = .up
        var seen: Set<Point> = Set<Point>()
    }
    
    enum Direction: String {
        case up, right, down, left
    }
    
    func renderOutline(_ heatmap: [[CGFloat]], size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        
        let scale = size.width / 14
        let offset = (size.height - size.width) / 2
        
        var seen = Set<Point>()
        
        for (down, row) in heatmap.enumerated() {
            for (right, mean) in row.enumerated() {
                if !seen.contains(Point(x: right, y: down)) && mean <= 0.5 {
                    if down <= 0 || heatmap[down - 1][right] <= 0.5
                        && right >= heatmap[down].count - 1 || heatmap[down][right + 1] <= 0.5
                        && down >= heatmap.count - 1 || heatmap[down + 1][right] <= 0.5
                        && right <= 0 || heatmap[down][right - 1] <= 0.5 {
                        break
                    }
                    var state = OutlineState()
                    state.seen = seen
                    state.position = Point(x: right, y: down)
                    moveToBlock(heatmap, &state, scale: scale, offset: offset)
                    seen = state.seen
                    
                    print("CLOSING PATH")
                    state.path.close()
                    
                    state.path.lineWidth = 8
                    UIColor(red: 0 / 255, green: 0 / 255, blue: 0 / 255, alpha: 0.4).setStroke()
                    state.path.stroke()
                    
                    state.path.lineWidth = 6
                    UIColor(red: 255 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1).setStroke()
                    state.path.stroke()
                }
            }
        }
        
        let outlinedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return outlinedImage
    }
    
    func moveToBlock(_ heatmap: [[CGFloat]], _ state: inout OutlineState, scale: CGFloat, offset: CGFloat) {
        state.seen.insert(Point(x: state.position.x, y: state.position.y))
        
        print("moving \(state.velocity.rawValue.uppercased()) to (\(state.position.x + 1), \(state.position.y + 1))")
        
        // The direction is shifted by one, because we start out by rotating one when checking a line
        switch state.velocity {
        case .up:
            state.check = .down
            check(heatmap, &state, scale: scale, offset: offset)
            return
        case .right:
            state.check = .left
            check(heatmap, &state, scale: scale, offset: offset)
            return
        case .down:
            state.check = .up
            check(heatmap, &state, scale: scale, offset: offset)
            return
        case .left:
            state.check = .right
            check(heatmap, &state, scale: scale, offset: offset)
            return
        }
    }
    
    func check(_ heatmap: [[CGFloat]], _ state: inout OutlineState, scale: CGFloat, offset: CGFloat) {
        setNextCheck(&state)
        
        if needsEdge(heatmap, &state) {
            drawEdge(&state, scale: scale, offset: offset)
            
            if state.path.currentPoint == state.pathStart {
                return
            }
            
            print("draw \(state.check.rawValue.uppercased()) edge")
            check(heatmap, &state, scale: scale, offset: offset)
            return
        } else {
            state.velocity = state.check
            setMove(&state)
            moveToBlock(heatmap, &state, scale: scale, offset: offset)
            return
        }
    }
    
    func needsEdge(_ heatmap: [[CGFloat]], _ state: inout OutlineState) -> Bool {
        let down = state.position.y
        let right = state.position.x
        
        switch state.check {
        case .up:
            return down <= 0 || heatmap[down - 1][right] > 0.5
        case .right:
            return right >= heatmap[down].count - 1 || heatmap[down][right + 1] > 0.5
        case .down:
            return down >= heatmap.count - 1 || heatmap[down + 1][right] > 0.5
        case .left:
            return right <= 0 || heatmap[down][right - 1] > 0.5
        }
    }
    
    func setNextCheck(_ state: inout OutlineState) {
        switch state.check {
        case .up:
            state.check = .right
        case .right:
            state.check = .down
        case .down:
            state.check = .left
        case .left:
            state.check = .up
        }
    }
    
    func setMove(_ state: inout OutlineState) {
        switch state.velocity {
        case .up:
            state.position.y = state.position.y - 1
        case .right:
            state.position.x = state.position.x + 1
        case .down:
            state.position.y = state.position.y + 1
        case .left:
            state.position.x = state.position.x - 1
        }
    }
    
    func drawEdge(_ state: inout OutlineState, scale: CGFloat, offset: CGFloat) {
        let down = state.position.cgPoint.y
        let right = state.position.cgPoint.x
        
        let topLeft = CGPoint(x: right * scale, y: down * scale + offset)
        let topRight = CGPoint(x: right * scale + scale, y: down * scale + offset)
        let bottomRight = CGPoint(x: right * scale + scale, y: down * scale + scale + offset)
        let bottomLeft = CGPoint(x: right * scale, y: down * scale + scale + offset)
        
        switch state.check {
        case .up:
            if state.pathStart == CGPoint(x: -1, y: -1) {
                print("JUMP")
                state.path.move(to: topLeft)
                state.pathStart = topLeft
            }
            state.path.addLine(to: topRight)
        case .right:
            if state.pathStart == CGPoint(x: -1, y: -1) {
                print("JUMP")
                state.path.move(to: topRight)
                state.pathStart = topRight
            }
            state.path.addLine(to: bottomRight)
        case .down:
            if state.pathStart == CGPoint(x: -1, y: -1) {
                print("JUMP")
                state.path.move(to: bottomRight)
                state.pathStart = bottomRight
            }
            state.path.addLine(to: bottomLeft)
        case .left:
            if state.pathStart == CGPoint(x: -1, y: -1) {
                print("JUMP")
                state.path.move(to: bottomLeft)
                state.pathStart = bottomLeft
            }
            state.path.addLine(to: topLeft)
        }
    }
}
