({
    doInit : function(component, event, helper) {
        helper.getOrgUsers(component);
        helper.getOrgObjects(component);
        helper.setupEventBus(component);
    },

    onUserUpdateHandler: function(component, event, helper) {
        let oldOwnerSelector = helper.getCurrentOwnerComponent(component);
        let newOwnerSelector = helper.getNewOwnerComponent(component);
        switch (event.getSource()) {
            case oldOwnerSelector:
                component.set('v.currentOwner', event.getParam('selectedUser'));
                break;
            case newOwnerSelector:
                let userId = newOwnerSelector.get('v.userId');
                component.set('v.newOwner', helper.getUserById(component, userId));
                break;
        }
    },

    onObjectsUpdateHandler: function(component, event, helper) {
        component.set('v.objectsToUpdate', event.getParam('selectedObjectList'));
    },

    onReassignClickHandler: function(component, event, helper) {
        if (!helper.validateForm(component)) return;
        let action = component.get('c.updateRecords');
        component.set('v.isLoading', true);
        action.setParams({
            "currentOwner": component.get('v.currentOwner'),
            "newOwner": component.get('v.newOwner'),
            "objectList": component.get('v.objectsToUpdate'),
            "enableEmails": helper.getOptionsEmailEnabler(component).get('v.checked')
        });
        action.setCallback(this, function(response) {
            if (response) {
                helper.getNotificationBar(component).showToast({
                    "variant": "info",
                    "title": "Success!",
                    "message": "Records updating has been initiated"
                });
            }
            else {
                component.set('v.isLoading', false);
                helper.getNotificationBar(component).showToast({
                    "variant": "warning",
                    "title": "Warning!",
                    "message": "Another similar job is in progress"
                });
            }
        });
        $A.enqueueAction(action);

    }
 })