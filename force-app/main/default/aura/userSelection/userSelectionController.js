({
    doInit : function(component, event, helper) {
        let action = component.get('c.getUsers');
        action.setCallback(this, function(response) {
            component.set('v.orgUsers', response.getReturnValue());
        });
        $A.enqueueAction(action);
        helper.getUserTableColumns(component);
    },


    openSearchDialog: function(component, event, helper) {
        let orgUsers = component.get("v.orgUsers");
        if (!orgUsers) {
            console.debug('USER_SELECT_COMP DEBUG: ' + 'List of users is empty');
            return;
        }
        component.set('v.isSearchModalOpen', true);
        component.set('v.userLookupTable', orgUsers);
    },

    closeSearchDialog: function(component, event, helper) {
        component.set('v.isSearchModalOpen', false);
    },

    submitSearchResult: function(component, event, helper) {
        let searchResult = component.get('v.searchKeyword');
        component.set('v.selectedUser', searchResult);
        component.set('v.isSearchModalOpen', false);

    },

    updateUserLookupTable: function(component, event, helper) {
        let keyword = event.getSource().get("v.value").toUpperCase();
        let orgUsers = component.get("v.orgUsers");
        let filteredUserList = [];
        for (let i = 0; i < orgUsers.length; i++) {
            if (orgUsers[i].Name.toUpperCase().includes(keyword)) {
                filteredUserList.push(orgUsers[i]);
            }
        }
        component.set("v.userLookupTable", filteredUserList);
    }
})
