public without sharing class ReassignRecordPageHelper {

    // Public constants
    public static final String STRING_DELIMITER = ';';
    public static final List<String> OBJECT_FILTER_LIST = new List<String> {
        'Account',
        'Opportunity',
        'Lead',
        'Contact'
    };

    // Public methods
    public static List<SelectOption> getOrgObjects() {
        List<SelectOption> orgObjects = new List<SelectOption> ();
        List<String> objectsLabels;
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        for (Schema.SObjectType objectType : globalDescribe.values()) {
            Schema.DescribeSObjectResult objectDescription
                = objectType.getDescribe();
            Map<String, Schema.SObjectField> objectFieldMap
                = objectDescription.fields.getMap();
            Boolean objectQualifies = true
                && OBJECT_FILTER_LIST.contains(objectDescription.getName());
                //&& objectDescription.isSearchable();
                //&& objectDescription.isCreateable();
                //|| objectDescription.isCustom();
            if (!objectQualifies) continue;
            Boolean fieldQualifies = true;
            // for (Schema.SObjectField objectField : objectFieldMap.values()) {
            //     fieldQualifies = objectField.getDescribe().getName() == 'OwnerId';
            //     if (fieldQualifies) break;
            // }
            if (fieldQualifies) {
                orgObjects.add(new SelectOption(objectDescription.getName(),
                    objectDescription.getLabel()));
            }
        }
        orgObjects.sort();
        return orgObjects;
    }
}
