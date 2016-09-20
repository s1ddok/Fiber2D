//
//  PhysicsBody+Shapes.swift
//  Fiber2D
//
//  Created by Andrey Volodin on 20.09.16.
//  Copyright © 2016 s1ddok. All rights reserved.
//

extension PhysicsBody {
    // MARK: Shapes
    /**
     * get the shape of the body.
     *
     * @param   tag   An integer number that identifies a PhysicsShape object.
     * @return A PhysicsShape object pointer or nullptr if no shapes were found.
     */
    func getShape(by tag: Int) -> PhysicsShape? {
        return nil
    }
    /**
     * @brief Add a shape to body.
     * @param shape The shape to be added.
     * @param addMassAndMoment If this is true, the shape's mass and moment will be added to body. The default is true.
     * @return This shape's pointer if added success or nullptr if failed.
     */
    func add(shape: PhysicsShape, addMassAndMoment: Bool = true) {}
    
    /**
     * @brief Remove a shape from body.
     * @param shape Shape the shape to be removed.
     * @param reduceMassAndMoment If this is true, the body mass and moment will be reduced by shape. The default is true.
     */
    func remove(shape: PhysicsShape, reduceMassAndMoment: Bool = true) {
        
    }
    
    /**
     * @brief Remove a shape from body.
     * @param tag The tag of the shape to be removed.
     * @param reduceMassAndMoment If this is true, the body mass and moment will be reduced by shape. The default is true.
     */
    func removeShape(by tag: Int, reduceMassAndMoment: Bool = true) {}
    
    /**
     * Remove all shapes.
     *
     * @param reduceMassAndMoment If this is true, the body mass and moment will be reduced by shape. The default is true.
     */
    func removeAllShapes(reduceMassAndMoment: Bool = true) {
        
    }

}
