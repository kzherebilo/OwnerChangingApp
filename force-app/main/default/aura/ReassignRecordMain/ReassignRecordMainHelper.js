({
    getOrgUsers: function(component) {
        let action = component.get('c.getUsers');
        let currentOwnerSelector = this.getCurrentOwnerComponent(component);
        let newOwnerSelector = this.getNewOwnerComponent(component);
        action.setCallback(this, function(response) {
            if (response.getState() === 'SUCCESS') {
                currentOwnerSelector.set('v.orgUsers', response.getReturnValue());
                newOwnerSelector.set('v.orgUsers', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    getOrgObjects: function(component) {
        let action = component.get('c.getObjects');
        let objectSelector = this.getObjectListComponent(component);
        let objectList = [];
        action.setCallback(this, function(response) {
            if (response.getState() === 'SUCCESS') {
                objectList = this.parseObjectOptionList(response.getReturnValue());
                objectSelector.set('v.objectOptions', objectList);
            }
        });
        $A.enqueueAction(action);
    },

    parseObjectOptionList : function(objectOptionList) {
        let delimiter = objectOptionList[0];
        let parsedObjectList = [];
        for(let i=1; i < objectOptionList.length; i++) {
            let objectOption = objectOptionList[i].split(delimiter);
            parsedObjectList.push({
                value: objectOption[0], label: objectOption[1]
            });
        }
        return parsedObjectList;
    },

    validateForm: function(component) {
        let currentOwner = component.get('v.currentOwner');
        let newOwner = component.get('v.newOwner');
        let objectsToUpdate = component.get('v.objectsToUpdate');
        if (!currentOwner) {
            this.getNotificationBar(component).showNotice({
                "variant": "warning",
                "header": "Invalid current owner",
                "message": "Empty owner field is not allowed. Click Select to search for user" 
            });
            return false;
        }
        if (!newOwner) {
            this.getNotificationBar(component).showNotice({
                "variant": "warning",
                "header": "Invalid new owner",
                "message": "Empty owner field is not allowed. Click Select to search for user" 
            });
            return false;
        }
        if (!objectsToUpdate || objectsToUpdate.length == 0) {
            this.getNotificationBar(component).showNotice({
                "variant": "warning",
                "header": "Invalid objects list",
                "message": "Empty list of objects to update is not allowed. Please select objects" 
            });
            return false;
        }
        return true;
    },

    getCurrentOwnerComponent: function(component) {
        return component.find('currentOwner');
    },

    getNewOwnerComponent: function(component) {
        return component.find('newOwner');
    },

    getObjectListComponent: function(component) {
        return component.find('objectsToUpdate');
    },

    getNotificationBar: function(component) {
        return component.find('notifLib');
    },

    getOptionsEmailEnabler: function(component) {
        return component.find('enableEmails');
    }
})
