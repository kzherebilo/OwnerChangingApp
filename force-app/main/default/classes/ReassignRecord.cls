public without sharing class ReassignRecord implements
        Database.Batchable<SObject>, Database.Stateful {
    
    private String                      oldOwnerId;
    private String                      newOwnerId;
    private String                      objectName;
    private List<Database.SaveResult>   errorList = new List<Database.SaveResult> ();
    private Integer                     numberOfRecordsUpdated = 0;
    private Integer                     numberOfRecordsProcessed = 0;
    public List<String>                 emailAddressList = new List<String> ();    

    public ReassignRecord(User oldOwnerId, User newOwnerId, sObject sample) {
        this.oldOwnerId = (String) oldOwnerId.Id;
        this.newOwnerId = (String) newOwnerId.Id;
        this.objectName = ((Id) sample.get('Id')).getSobjectType().getDescribe().getName();
    }

    public ReassignRecord(String oldOwnerId, String newOwnerId, String objectName) {
        this.oldOwnerId = oldOwnerId;
        this.newOwnerId = newOwnerId;
        this.objectName = objectName;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String oldOwnerId = this.oldOwnerId;
        String query = 'SELECT OwnerId FROM ' + this.objectName
            + ' WHERE OwnerId=:oldOwnerId';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<sObject> records) {
        for (sObject record : records) {
            record.put('OwnerId', this.newOwnerId);
        }
        List<Database.SaveResult> results = Database.update(records, false);
        this.numberOfRecordsProcessed += results.size();
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                errorList.add(result);
            } 
            else {
                numberOfRecordsUpdated++;
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob WHERE Id =
            :BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if (emailAddressList.isEmpty()) {
            emailAddressList.add(apexJob.CreatedBy.Email);
        }
        String emailBody = 'The batch Apex job processed ' + apexJob.TotalJobItems
            + ' batches with '+ apexJob.NumberOfErrors + ' failures. Number of'
            + ' records processed: ' + this.numberOfRecordsProcessed + '. Number '
            + ' records updated: ' + this.numberOfRecordsUpdated;
        mail.setToAddresses(emailAddressList);
        mail.setSubject('Update owner of ' + objectName + ' records: ' 
            + apexJob.Status);
        mail.setPlainTextBody(emailBody);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
