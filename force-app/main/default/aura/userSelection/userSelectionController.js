({
    doInit : function(component, event, helper) {
        let action = component.get('c.getUsers');
        action.setCallback(this, function(response) {
            console.log('MY_DEBUG: ' + JSON.stringify(response.getReturnValue()));
            component.set('v.owners', response.getReturnValue());
        });
        $A.enqueueAction(action);
    }
})
