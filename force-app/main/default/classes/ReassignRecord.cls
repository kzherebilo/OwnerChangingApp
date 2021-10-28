public without sharing class ReassignRecord implements
        Database.Batchable<SObject>, Database.Stateful {
    
    private class LogRecord {
        public String       jobId               = '';
        public String       jobStatus           = '';
        public String       objectName          = '';
        public Integer      recordsProcessed    = 0;
        public Integer      recordsUpdated      = 0;
        public Integer      recordsFailed       = 0;
        public Integer      batchJobItems       = 0;
        public Integer      batchJobErrors      = 0;
        public String       errorType           = '';
        public String       errorCode           = '';
        public String       errorMessage        = '';
    }

    public  String                      oldOwnerName;
    public  String                      newOwnerName;
    public  Boolean                     enableEmails;
    private String                      oldOwnerId;
    private String                      newOwnerId;
    private List<String>                objectNameList;
    private Integer                     numberOfRecordsUpdated = 0;
    private Integer                     numberOfRecordsProcessed = 0;
    private List<LogRecord>             log = new List<LogRecord> ();
    public  List<String>                emailAddressList = new List<String> (); 

    public ReassignRecord(String oldOwnerId, String newOwnerId,
            List<String> objectNameList) {
        this.oldOwnerId = oldOwnerId;
        this.newOwnerId = newOwnerId;
        this.objectNameList = objectNameList;
        this.oldOwnerName = '';
        this.newOwnerName = '';
        this.enableEmails = false;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        String oldOwnerId = this.oldOwnerId;
        String query = 'SELECT OwnerId FROM ' + this.objectNameList[0]
            + ' WHERE OwnerId=:oldOwnerId';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<sObject> records) {
        for (sObject record : records) {
            record.put('OwnerId', this.newOwnerId);
        }
        List<Database.SaveResult> results = Database.update(records, false);
        for (Database.SaveResult result : results) {
            this.numberOfRecordsProcessed ++;
            if (result.isSuccess()) {
                this.numberOfRecordsUpdated++;
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        AsyncApexJob apexJob = [SELECT Id, Status, NumberOfErrors,
            JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob WHERE Id =
            :context.getJobId()];
        if (this.emailAddressList.isEmpty()) {
            this.emailAddressList.add(apexJob.CreatedBy.Email);
        }
        LogRecord logRec = new LogRecord();
        logRec.jobId = context.getJobId();
        logRec.jobStatus = apexJob.Status;
        logRec.objectName = objectNameList[0];
        logRec.recordsProcessed = this.numberOfRecordsProcessed;
        logRec.recordsUpdated = this.numberOfRecordsUpdated;
        logRec.recordsFailed = logRec.recordsProcessed - logRec.recordsUpdated;
        logRec.batchJobItems = apexJob.TotalJobItems;
        logRec.batchJobErrors = apexJob.NumberOfErrors;
        this.log.add(logRec);
        this.numberOfRecordsProcessed = 0;
        this.numberOfRecordsUpdated = 0;
        this.objectNameList.remove(0);
        if (this.objectNameList.size() > 0) {
            publishReport();
            Database.executeBatch(this);
        }
        else {
            emailReport();
            publishReport();
        }

    }


    private void emailReport() {

        if (!this.enableEmails) return;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        LogRecord logHeadRecord = new LogRecord();
        if (!this.log.isEmpty()) logHeadRecord = this.log[this.log.size() - 1];
        String emailHtmlBody = '';
        String emailSubject = '';
        String overallStatus = 'Completed';

        emailHtmlBody = emailHtmlBody
            + '<tr><td>Old record owner</td><td>: ' + this.oldOwnerName +'</td></tr>\n'
            + '<tr><td>New record owner</td><td>: ' + this.newOwnerName +'</td></tr>\n'
            + '<br/><br/>\n';
        for (LogRecord logRec : log) {
            emailHtmlBody = emailHtmlBody
                + '<tr><td>Apex batch job ID</td><td>: ' + logRec.jobId +'</td></tr>\n'
                + '<tr><td>Job status</td><td>: ' + logRec.jobStatus +'</td></tr>\n'
                + '<tr><td>Object name</td><td>: ' + logRec.objectName +'</td></tr>\n'
                + '<tr><td>Records processed</td><td>: ' + logRec.recordsProcessed +'</td></tr>\n'
                + '<tr><td>Records updated</td><td>: ' + logRec.recordsUpdated +'</td></tr>\n'
                + '<tr><td>Records failed</td><td>: ' + logRec.recordsFailed +'</td></tr>\n'
                + '<tr><td>Job items</td><td>: ' + logRec.batchJobItems +'</td></tr>\n'
                + '<tr><td>Job errors</td><td>: ' + logRec.batchJobErrors +'</td></tr>\n'
                + '<br/>\n';
            if (logRec.jobStatus != 'Completed') overallStatus = 'Failed';
            emailSubject += logRec.objectName + ', ';
        }
        emailSubject
            = overallStatus.toUpperCase() + ': '
            + 'Update owner of ' + emailSubject.left(emailSubject.length() - 2)
            + ' records';
        mail.setToAddresses(emailAddressList);
        mail.setSubject(emailSubject);
        mail.setHtmlBody(emailHtmlBody);
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        catch (System.EmailException ex) {
            logHeadRecord.errorType += 'MAIL';
            logHeadRecord.errorCode += ex.getDmlType(0);
            logHeadRecord.errorMessage += ex.getDmlMessage(0);
            if (!this.log.isEmpty()) this.log.remove(this.log.size() - 1);
            this.log.add(logHeadRecord);
        }
    }

    private void publishReport() {
        if (this.log.isEmpty()) return;
        LogRecord logHeadRecord = this.log[this.log.size() - 1];
        Update_Owner_Event__e updateOwnerEvent = new Update_Owner_Event__e (
            oldOwnerName__c = this.oldOwnerName,
            newOwnerName__c = this.newOwnerName,
            jobId__c = logHeadRecord.jobId,
            jobStatus__c = logHeadRecord.jobStatus,
            objectName__c = logHeadRecord.objectName,
            recordsProcessed__c = logHeadRecord.recordsProcessed,
            recordsUpdated__c = logHeadRecord.recordsUpdated,
            errorCode__c = logHeadRecord.errorCode,
            errorType__c = logHeadRecord.errorType,
            errorMessage__c = logHeadRecord.errorMessage
        );
        if (this.objectNameList.size() == 0) {
            updateOwnerEvent.jobStatus__c += 'Final';
        }
        Database.SaveResult publishingResult = Eventbus.publish(updateOwnerEvent);
    }
}
