({
    setUserLookupTableColumns: function(component) {
        let table = this.getUserLookupTable(component);
        table.set('v.columns', [
            { label: 'Name', fieldName: 'Name', type: 'text' },
            { label: 'Salesforce Name', fieldName: 'Username', type: 'text'}
        ]);
    },

    populateUserLookupTable: function(component, data) {
        let table = this.getUserLookupTable(component);
        table.set('v.data', data);
    },

    clearSelectedTableRows: function(component) {
        this.getUserLookupTable(component).set('v.selectedRows', []);
    },

    setSearchDialogIsLoading: function(component) {
        let searchField = this.getUserSearchField(component);
        searchField.set('v.isLoading', true);
        searchField.set('v.disabled', true);
        searchField.set('v.placeholder', 'Loading users...');
    },

    reduceLookupTable: function(data, keyword) {
        let filteredData = [];
        if (!data) return filteredData;
        if (data.length < 2) return data;
        for (let i = 0; i < data.length; i++) {
            if (data[i].Name.toUpperCase().includes(keyword)) {
                filteredData.push(data[i]);
            }
        }
        return filteredData;
    },

    fireOnUserUpdateEvent: function(component, selectedUser) {
        let updateEvent = component.getEvent('updateUser');
        updateEvent.setParams({ 'selectedUser': selectedUser });
        updateEvent.fire();
    },

    getUserLookupTable: function(component) {
        return component.find('userLookupTable');
    },
    
    getUserSearchField: function(component) {
        return component.find('searchField');
    } 
})
