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

    setupEventBus: function(component) {
        let empApi = component.find('empApi');
        let channel = this.getPlatformEventChannel();
        empApi.onError($A.getCallback(function(error) {
            console.debug('EMP_API_DEBUG: ' + JSON.stringify(error));
        }));
        empApi.subscribe(channel, -1, $A.getCallback(eventReceived => {
            // Process event (this is called each time we receive an event)
            console.debug('EMP_API_DEBUG: Received ',
                JSON.stringify(eventReceived));
            if (this.isFianalPlatformEvent(eventReceived)) {
                component.set('v.isLoading', false);
                this.getNotificationBar(component).showToast({
                    "variant": "success",
                    "title": "Success!",
                    "message": "Records have been updated!"
                });
            }
        }))
        .then(subscription => {
            // Subscription response received.
            // We haven't received an event yet.
            console.debug('EMP_API_DEBUG: Subscription request sent to: ',
                subscription.channel);
        });
    },

    isFianalPlatformEvent: function(event) {
        return event.data.payload.jobStatus__c.includes('Final');
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
    },

    getPlatformEventChannel: function() {
        return '/event/Update_Owner_Event__e';
    }
})
