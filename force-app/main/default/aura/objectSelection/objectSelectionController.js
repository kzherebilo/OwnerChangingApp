({
    doInit : function(component, event, helper) {
    },

    onChangeHandler: function(component, event, helper) {
        let selectedObjects = event.getParam('value');
        helper.fireOnObjectsUpdateEvent(component, selectedObjects);
    }
})
