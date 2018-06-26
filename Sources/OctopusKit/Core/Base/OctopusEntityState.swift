//
//  OctopusEntityState.swift
//  OctopusKit
//
//  Created by ShinryakuTako@invadingoctopus.io on 2017/11/13.
//  Copyright © 2018 Invading Octopus. Licensed under Apache License v2.0 (see LICENSE.txt)
//

import GameplayKit

/// A logical state which may be associated with an entity's `StateMachineComponent`. Dictates the validity of state transitions and performs modifications to the entity upon entering from or exiting to specific states.
public class OctopusEntityState: GKState {
    
    public let entity: OctopusEntity
    
    // ⚠️ NOTE: Component arrays should be of type `GKComponent` instead of the more specific `OctopusComponent`, so that `GKAgent` and `OctopusAgent2D` etc. can be added.
    
    /// The components to be added to the entity when its state machine enters this state.
    ///
    /// For more granular control, e.g. using different components depending on the previous state, override `didEnter(from:)`.
    ///
    /// - Note: Adding components of the same class will replace older components of that class, if the entity already has any.
    ///
    /// - Important: This property is ineffective if the `OctopusEntityState` subclass overrides `didEnter(from:)` without calling `super.didEnter(from:)`.
    public var componentsToAddOnEntry: [GKComponent]?
    
    /// The components to be removed from the entity when its state machine exits this state.
    ///
    /// For more granular control, e.g. removing different components depending on the upcoming state, override `willExit(to:)`.
    ///
    /// - Important: This property is ineffective if the `OctopusEntityState` subclass overrides `willExit(to:)` without calling `super.willExit(to:)`.
    public var componentTypesToRemoveOnExit: [GKComponent.Type]?
    
    public init(entity: OctopusEntity) {
        self.entity = entity
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    /// Sets `componentTypesToRemoveOnExit` to the types of all the components in `componentsToAddOnEntry`
    ///
    /// If `componentsToAddOnEntry` is `nil` then `componentTypesToRemoveOnExit` is set to `nil` as well.
    public func syncComponentTypesToRemoveOnExitWithComponentsToAddOnEntry() {
        // CHECK: Shorter name? ^^'
        componentTypesToRemoveOnExit = componentsToAddOnEntry?.map { type(of: $0) } ?? nil
    }
    
    /// Call `super.didEnter(from: previousState)` to add a log entry.
    public override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        OctopusKit.logForStates.add("\"\(String(optional: entity.name))\" \(String(optional: previousState)) → \(self)")
        
        if let componentsToAddOnEntry = self.componentsToAddOnEntry {
            // TODO: Add count check?
            entity.addComponents(componentsToAddOnEntry)
        }
    }
    
    /// Call `super.willExit(to: nextState)` to add a log entry.
    public override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
        OctopusKit.logForStates.add("\"\(String(optional: entity.name))\" \(self) → \(nextState)")
        
        if let componentTypesToRemoveOnExit = self.componentTypesToRemoveOnExit {
            // TODO: Add count check?
            for componentType in componentTypesToRemoveOnExit {
                entity.removeComponent(ofType: componentType)
            }
        }
    }
}