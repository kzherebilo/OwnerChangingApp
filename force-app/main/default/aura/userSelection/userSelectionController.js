({
    doInit : function(component, event, helper) {
    },

    openSearchDialog: function(component, event, helper) {
        let orgUsers = component.get("v.orgUsers");
        component.set('v.isSearchModalOpen', true);
        helper.setUserLookupTableColumns(component);
        helper.populateUserLookupTable(component, orgUsers);
        if (!orgUsers) {
            helper.setSearchDialogIsLoading(component);
        }
    },

    closeSearchDialog: function(component, event, helper) {
        component.set('v.isSearchModalOpen', false);
    },

    submitSearchResult: function(component, event, helper) {
        let selectedRows = helper.getUserLookupTable(component).getSelectedRows();
        let selectedUser = component.find('selectedUser');
        if (selectedRows && (selectedRows.length == 1)) {
            selectedUser.set('v.value', selectedRows[0].Name);
            helper.fireOnUserUpdateEvent(component, selectedRows[0]);
        }
        component.set('v.isSearchModalOpen', false);
        
    },

    updateUserLookupTable: function(component, event, helper) {
        let orgUsers = component.get("v.orgUsers");
        let keyword = event.getSource().get("v.value").toUpperCase();
        helper.clearSelectedTableRows(component);
        helper.populateUserLookupTable(component,
            helper.reduceLookupTable(orgUsers, keyword));
    },

    onRowSelect: function(component, event, helper) {
        let user = event.getParam('selectedRows');
        let searchField = component.find('searchField');
        searchField.set('v.value', user[0].Name);
    }
})
