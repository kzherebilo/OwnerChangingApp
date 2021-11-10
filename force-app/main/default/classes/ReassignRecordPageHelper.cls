public without sharing class ReassignRecordPageHelper {

    // Public constants
    public static final String STRING_DELIMITER = ';';
    public static final String REASSIGN_RECORD_CLASS_ID = getReassignRecordClassId();
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

    private static String getReassignRecordClassId() {
        String reassignRecordClassName = ReassignRecord.class.getName();
        String reassignRecordClassId;
        reassignRecordClassId = [SELECT Id FROM ApexClass
            WHERE Name = :reassignRecordClassName LIMIT 1].Id;
        return reassignRecordClassId;
    }

    public static Boolean isAsyncJobInProgress() {
        List<AsyncApexJob> apexJobs = [SELECT ApexClassId, Status 
            FROM AsyncApexJob
            WHERE ApexClassId =: REASSIGN_RECORD_CLASS_ID
            AND Status != 'Completed' AND Status != 'Failed'];
        return !apexJobs.isEmpty();
    }

    public static Boolean isApexFormValid(OwnerChangingPageController controller) {
        String logMessage;
        ApexPages.Severity logMsgSeverity;

        logMsgSeverity = ApexPages.Severity.ERROR;
        if (ReassignRecordPageHelper.isAsyncJobInProgress()) { 
            logMessage = 'Another task is being processed. Please try again later';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return false;
        }
        // A series of trivial checks of user input
        logMsgSeverity = ApexPages.Severity.WARNING;
        if (String.isBlank(controller.verifiedOldOwnerName)) {
            logMessage = '"From"-user field is required! '
                + 'Please select a user whose ownership to be revoked';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return false;
        }
        if (String.isBlank(controller.verifiedNewOwnerName)) {
            logMessage = '"To"-user field is required! '
                + 'Please select a new owner of the records';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return false;
        }
        if (controller.verifiedOldOwnerName == controller.verifiedNewOwnerName) {
            logMessage = 'Current and new owner are identical! '
                + 'Reassignment is pointless! Select different users';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return false;
        }
        if (controller.verifiedObjectList.isEmpty()) {
            logMessage = 'No object type is selected! '
                + 'Please specify object types, such as Accounts or Leads; the '
                + 'owner of the records belonging to each of the selected type '
                + 'will be updated';
            ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
            return false;
        }
        logMsgSeverity = ApexPages.Severity.INFO;
        logMessage = 'Reassignment task is initiated';
        ApexPages.addMessage(new ApexPages.Message(logMsgSeverity, logMessage));
        return true;
    }
}
