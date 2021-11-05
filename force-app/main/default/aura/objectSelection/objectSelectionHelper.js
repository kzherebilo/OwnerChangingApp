({
    fireOnObjectsUpdateEvent: function(component, selectedObjects) {
        let updateEvent = component.getEvent('updateObjects');
        updateEvent.setParams({ 'selectedObjectList': selectedObjects });
        updateEvent.fire();
    }
})
