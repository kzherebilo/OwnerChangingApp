({
    doInit : function(component, event, helper) {
        let action = component.get('c.getObjects');
        let objectList = [];
        action.setCallback(this, function(response) {
            objectList = helper.parseObjectOptionList(response.getReturnValue());
            component.set('v.objectOptions', objectList);
        });
        $A.enqueueAction(action);
    }
})
