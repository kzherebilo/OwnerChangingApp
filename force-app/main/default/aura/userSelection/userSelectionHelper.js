({
    getUserTableColumns : function(component) {
        component.set('v.userLookupTableColumns', [
            { label: 'Name', fieldName: 'Name', type: 'text' },
            { label: 'Salesforce Name', fieldName: 'Username', type: 'text'}
        ]);
    }
})
