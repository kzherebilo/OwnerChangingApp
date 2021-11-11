({
    fireOnUserUpdateEvent: function(component) {
        let updateEvent = component.getEvent('updateUser');
        updateEvent.fire();
    }

})
